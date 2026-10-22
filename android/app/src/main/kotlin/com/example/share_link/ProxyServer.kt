package com.example.share_link

import android.net.Network
import android.util.Log
import java.io.BufferedInputStream
import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.DataInputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.ConnectException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * Minimal proxy on a single port:
 * - HTTP: plain requests (absolute-URI form) and CONNECT tunnels (HTTPS), for a manual Wi-Fi proxy.
 * - SOCKS5 (first byte 0x05): CONNECT and UDP ASSOCIATE, used by client mode on Phone B.
 * One thread per client plus one pump thread per tunnel; outgoing sockets and DNS go through
 * the network returned by [upstreamNetwork] (the Wi-Fi network).
 */
class ProxyServer(
    private val port: Int,
    private val upstreamNetwork: () -> Network?,
    /** DNS server of the Wi-Fi network; UDP DNS queries from clients are redirected to it. */
    private val upstreamDns: () -> InetAddress? = { null },
) {
    val activeConnections = AtomicInteger()
    val bytesUp = AtomicLong()
    val bytesDown = AtomicLong()

    private val threadCounter = AtomicInteger()
    private val executor: ExecutorService = Executors.newCachedThreadPool { runnable ->
        Thread(runnable, "proxy-${threadCounter.incrementAndGet()}").apply { isDaemon = true }
    }
    private val openSockets: MutableSet<Socket> = ConcurrentHashMap.newKeySet()
    private val openDatagrams: MutableSet<DatagramSocket> = ConcurrentHashMap.newKeySet()

    @Volatile
    private var serverSocket: ServerSocket? = null

    @Volatile
    private var running = false

    /** Binds to [bindAddress]:[port] and starts accepting. Throws if the bind fails. */
    @Throws(IOException::class)
    fun start(bindAddress: InetAddress) {
        val server = ServerSocket()
        try {
            server.reuseAddress = true
            server.bind(InetSocketAddress(bindAddress, port), BACKLOG)
        } catch (e: IOException) {
            closeQuietly(server)
            throw e
        }
        serverSocket = server
        running = true
        executor.execute { acceptLoop(server) }
        Log.i(TAG, "Proxy listening on ${bindAddress.hostAddress}:$port")
    }

    fun stop() {
        running = false
        closeQuietly(serverSocket)
        serverSocket = null
        openSockets.forEach(::closeQuietly)
        openSockets.clear()
        openDatagrams.forEach(DatagramSocket::close)
        openDatagrams.clear()
        executor.shutdownNow()
        Log.i(TAG, "Proxy stopped")
    }

    private fun acceptLoop(server: ServerSocket) {
        while (running) {
            val client = try {
                server.accept()
            } catch (e: IOException) {
                if (running) Log.w(TAG, "accept failed", e)
                break
            }
            if (activeConnections.get() >= MAX_CONNECTIONS) {
                closeQuietly(client)
                continue
            }
            try {
                executor.execute { handleClient(client) }
            } catch (e: RejectedExecutionException) {
                closeQuietly(client)
            }
        }
    }

    private fun handleClient(client: Socket) {
        activeConnections.incrementAndGet()
        openSockets.add(client)
        var upstream: Socket? = null
        try {
            client.soTimeout = HEADER_TIMEOUT_MS
            client.tcpNoDelay = true
            val clientIn = BufferedInputStream(client.getInputStream())
            clientIn.mark(1)
            val first = clientIn.read()
            if (first < 0) return
            clientIn.reset()
            if (first == SOCKS_VERSION) {
                handleSocks(client, clientIn)
                return
            }

            val head = readHead(clientIn) ?: return
            val parts = head.first().split(' ')
            if (parts.size < 3) {
                sendError(client, 400, "Bad Request")
                return
            }
            val method = parts[0].uppercase()
            val target = parts[1]
            val version = parts[2]

            if (method == "CONNECT") {
                val (host, targetPort) = parseHostPort(target, 443)
                    ?: return sendError(client, 400, "Bad Request")
                upstream = openUpstream(client, host, targetPort) ?: return
                client.getOutputStream().write(CONNECT_OK)
                tunnel(client, clientIn, upstream)
            } else {
                val request = parseHttpTarget(target, head) ?: return sendError(client, 400, "Bad Request")
                upstream = openUpstream(client, request.host, request.port) ?: return
                val rewritten = buildRequestHead(method, request.path, version, head)
                upstream.getOutputStream().write(rewritten)
                bytesUp.addAndGet(rewritten.size.toLong())
                tunnel(client, clientIn, upstream)
            }
        } catch (e: IOException) {
            // Timeouts, resets and closes are normal for a proxy.
        } catch (e: Exception) {
            Log.w(TAG, "Unexpected proxy error", e)
        } finally {
            upstream?.let {
                closeQuietly(it)
                openSockets.remove(it)
            }
            closeQuietly(client)
            openSockets.remove(client)
            activeConnections.decrementAndGet()
        }
    }

    // region SOCKS5 (RFC 1928), no authentication: the Wi-Fi Direct passphrase protects the network.

    private class SocksTarget(val host: String, val port: Int)

    private fun handleSocks(client: Socket, input: InputStream) {
        val data = DataInputStream(input)
        val out = client.getOutputStream()

        // Greeting: VER NMETHODS METHODS...
        if (data.readUnsignedByte() != SOCKS_VERSION) return
        val methods = ByteArray(data.readUnsignedByte()).also { data.readFully(it) }
        if (methods.none { it.toInt() == METHOD_NO_AUTH }) {
            out.write(byteArrayOf(SOCKS_VERSION.toByte(), METHOD_NONE_ACCEPTABLE.toByte()))
            return
        }
        out.write(byteArrayOf(SOCKS_VERSION.toByte(), METHOD_NO_AUTH.toByte()))

        // Request: VER CMD RSV ATYP DST.ADDR DST.PORT
        if (data.readUnsignedByte() != SOCKS_VERSION) return
        val command = data.readUnsignedByte()
        data.readUnsignedByte()
        val target = readSocksTarget(data) ?: return sendSocksReply(out, REP_ADDRESS_UNSUPPORTED)

        when (command) {
            CMD_CONNECT -> socksConnect(client, input, out, target)
            CMD_UDP_ASSOCIATE -> socksUdpAssociate(client, input, out)
            else -> sendSocksReply(out, REP_COMMAND_UNSUPPORTED)
        }
    }

    private fun socksConnect(client: Socket, input: InputStream, out: OutputStream, target: SocksTarget) {
        val upstream = try {
            connectUpstream(target.host, target.port).also { openSockets.add(it) }
        } catch (e: IOException) {
            Log.d(TAG, "SOCKS upstream ${target.host}:${target.port} failed: ${e.message}")
            sendSocksReply(out, socksReplyFor(e))
            return
        }
        try {
            sendSocksReply(out, REP_SUCCEEDED)
            tunnel(client, input, upstream)
        } finally {
            closeQuietly(upstream)
            openSockets.remove(upstream)
        }
    }

    private fun socksUdpAssociate(client: Socket, input: InputStream, out: OutputStream) {
        val network = upstreamNetwork()
        if (network == null) {
            sendSocksReply(out, REP_NETWORK_UNREACHABLE)
            return
        }
        val association = try {
            UdpAssociation(client.inetAddress, client.localAddress, network)
        } catch (e: IOException) {
            sendSocksReply(out, REP_GENERAL_FAILURE)
            return
        }
        try {
            sendSocksReply(out, REP_SUCCEEDED, InetSocketAddress(client.localAddress, association.relayPort))
            executor.execute { association.clientToRemote() }
            executor.execute { association.remoteToClient() }
            // The association lives as long as its TCP control connection (RFC 1928 §7).
            holdControlConnection(client, input, association.lastActivity)
        } finally {
            association.close()
        }
    }

    private fun holdControlConnection(client: Socket, input: InputStream, lastActivity: AtomicLong) {
        client.soTimeout = READ_TIMEOUT_MS
        val buffer = ByteArray(256)
        while (true) {
            try {
                if (input.read(buffer) < 0) return
            } catch (e: SocketTimeoutException) {
                if (System.currentTimeMillis() - lastActivity.get() > UDP_IDLE_TIMEOUT_MS) return
            }
        }
    }

    /** Relays datagrams between one client and the internet, wrapping them in SOCKS5 UDP headers. */
    private inner class UdpAssociation(
        private val clientIp: InetAddress,
        bindAddress: InetAddress,
        private val network: Network,
    ) {
        private val relay = DatagramSocket(InetSocketAddress(bindAddress, 0))
        private val remote = DatagramSocket()
        val relayPort: Int get() = relay.localPort
        val lastActivity = AtomicLong(System.currentTimeMillis())

        @Volatile
        private var clientAddress: InetSocketAddress? = null

        /** Header the client used per destination, echoed on replies (keeps domain/DNS mappings intact). */
        private val replyHeaders = ConcurrentHashMap<InetSocketAddress, ByteArray>()
        private val resolved = ConcurrentHashMap<String, InetAddress>()

        init {
            try {
                network.bindSocket(remote)
            } catch (e: IOException) {
                relay.close()
                remote.close()
                throw e
            }
            openDatagrams.add(relay)
            openDatagrams.add(remote)
        }

        fun clientToRemote() {
            val buffer = ByteArray(UDP_BUFFER_SIZE)
            val packet = DatagramPacket(buffer, buffer.size)
            try {
                while (true) {
                    packet.setData(buffer)
                    relay.receive(packet)
                    if (packet.address != clientIp) continue
                    clientAddress = packet.socketAddress as InetSocketAddress
                    val headerLength = udpHeaderLength(buffer, packet.length) ?: continue
                    val target = parseUdpTarget(buffer) ?: continue
                    var destination = resolve(target) ?: continue
                    if (destination.port == DNS_PORT) {
                        upstreamDns()?.let { destination = InetSocketAddress(it, DNS_PORT) }
                    }
                    replyHeaders[destination] = buffer.copyOfRange(0, headerLength)
                    val payloadLength = packet.length - headerLength
                    remote.send(DatagramPacket(buffer, headerLength, payloadLength, destination))
                    bytesUp.addAndGet(payloadLength.toLong())
                    lastActivity.set(System.currentTimeMillis())
                }
            } catch (e: IOException) {
                // Closed.
            } finally {
                close()
            }
        }

        fun remoteToClient() {
            val buffer = ByteArray(UDP_BUFFER_SIZE)
            val packet = DatagramPacket(buffer, buffer.size)
            try {
                while (true) {
                    packet.setData(buffer)
                    remote.receive(packet)
                    val destination = clientAddress ?: continue
                    val from = packet.socketAddress as InetSocketAddress
                    val header = replyHeaders[from] ?: udpHeaderFor(from)
                    val reply = ByteArray(header.size + packet.length)
                    System.arraycopy(header, 0, reply, 0, header.size)
                    System.arraycopy(buffer, 0, reply, header.size, packet.length)
                    relay.send(DatagramPacket(reply, reply.size, destination))
                    bytesDown.addAndGet(packet.length.toLong())
                    lastActivity.set(System.currentTimeMillis())
                }
            } catch (e: IOException) {
                // Closed.
            } finally {
                close()
            }
        }

        private fun resolve(target: SocksTarget): InetSocketAddress? {
            val address = resolved[target.host] ?: try {
                network.getAllByName(target.host).first().also { resolved[target.host] = it }
            } catch (e: IOException) {
                return null
            }
            return InetSocketAddress(address, target.port)
        }

        fun close() {
            relay.close()
            remote.close()
            openDatagrams.remove(relay)
            openDatagrams.remove(remote)
        }
    }

    private fun readSocksTarget(data: DataInputStream): SocksTarget? {
        val host = when (data.readUnsignedByte()) {
            ATYP_IPV4 -> InetAddress.getByAddress(ByteArray(4).also { data.readFully(it) }).hostAddress
            ATYP_IPV6 -> InetAddress.getByAddress(ByteArray(16).also { data.readFully(it) }).hostAddress
            ATYP_DOMAIN -> String(ByteArray(data.readUnsignedByte()).also { data.readFully(it) }, Charsets.ISO_8859_1)
            else -> return null
        } ?: return null
        return SocksTarget(host, data.readUnsignedShort())
    }

    /** Length of the SOCKS5 UDP header (RSV RSV FRAG ATYP ADDR PORT), or null if invalid/fragmented. */
    private fun udpHeaderLength(buffer: ByteArray, length: Int): Int? {
        if (length < 4 || buffer[2].toInt() != 0) return null
        val headerLength = when (buffer[3].toInt()) {
            ATYP_IPV4 -> 4 + 4 + 2
            ATYP_IPV6 -> 4 + 16 + 2
            ATYP_DOMAIN -> if (length > 4) 4 + 1 + (buffer[4].toInt() and 0xFF) + 2 else return null
            else -> return null
        }
        return if (length >= headerLength) headerLength else null
    }

    private fun parseUdpTarget(buffer: ByteArray): SocksTarget? {
        val (host, portOffset) = when (buffer[3].toInt()) {
            ATYP_IPV4 -> InetAddress.getByAddress(buffer.copyOfRange(4, 8)).hostAddress to 8
            ATYP_IPV6 -> InetAddress.getByAddress(buffer.copyOfRange(4, 20)).hostAddress to 20
            ATYP_DOMAIN -> {
                val length = buffer[4].toInt() and 0xFF
                String(buffer, 5, length, Charsets.ISO_8859_1) to 5 + length
            }
            else -> return null
        }
        val port = ((buffer[portOffset].toInt() and 0xFF) shl 8) or (buffer[portOffset + 1].toInt() and 0xFF)
        return SocksTarget(host ?: return null, port)
    }

    private fun udpHeaderFor(address: InetSocketAddress): ByteArray {
        val ip = address.address.address
        val header = ByteArray(4 + ip.size + 2)
        header[3] = (if (ip.size == 4) ATYP_IPV4 else ATYP_IPV6).toByte()
        System.arraycopy(ip, 0, header, 4, ip.size)
        header[header.size - 2] = (address.port shr 8).toByte()
        header[header.size - 1] = address.port.toByte()
        return header
    }

    private fun sendSocksReply(out: OutputStream, reply: Int, bound: InetSocketAddress? = null) {
        val ipv4 = bound != null && bound.address is Inet4Address
        val ip = if (ipv4) bound!!.address.address else ByteArray(4)
        val port = if (ipv4) bound!!.port else 0
        val response = byteArrayOf(
            SOCKS_VERSION.toByte(), reply.toByte(), 0, ATYP_IPV4.toByte(),
            ip[0], ip[1], ip[2], ip[3],
            (port shr 8).toByte(), port.toByte(),
        )
        try {
            out.write(response)
        } catch (e: IOException) {
            // Client already gone.
        }
    }

    private fun socksReplyFor(e: IOException) = when (e) {
        is UnknownHostException -> REP_HOST_UNREACHABLE
        is ConnectException -> REP_CONNECTION_REFUSED
        is SocketTimeoutException -> REP_HOST_UNREACHABLE
        else -> REP_GENERAL_FAILURE
    }

    // endregion

    /** Connects to the target, or replies 502 to the client and returns null. */
    private fun openUpstream(client: Socket, host: String, targetPort: Int): Socket? {
        return try {
            connectUpstream(host, targetPort).also { openSockets.add(it) }
        } catch (e: IOException) {
            Log.d(TAG, "Upstream $host:$targetPort failed: ${e.message}")
            sendError(client, 502, "Bad Gateway")
            null
        }
    }

    private fun connectUpstream(host: String, targetPort: Int): Socket {
        val network = upstreamNetwork() ?: throw IOException("Wi-Fi network unavailable")
        val addresses = network.getAllByName(host)
        var lastError: IOException? = null
        for (address in addresses) {
            // Don't let clients reach services on this phone itself.
            if (address.isLoopbackAddress || address.isAnyLocalAddress) {
                throw IOException("Blocked address $address")
            }
            val socket = Socket()
            try {
                network.bindSocket(socket)
                socket.tcpNoDelay = true
                socket.connect(InetSocketAddress(address, targetPort), CONNECT_TIMEOUT_MS)
                return socket
            } catch (e: IOException) {
                closeQuietly(socket)
                lastError = e
            }
        }
        throw lastError ?: UnknownHostException(host)
    }

    /**
     * Pipes bytes both ways until the server finishes. Client EOF half-closes the upstream so the
     * response can still arrive; server EOF ends the whole tunnel.
     */
    private fun tunnel(client: Socket, clientIn: InputStream, upstream: Socket) {
        val lastActivity = AtomicLong(System.currentTimeMillis())
        client.soTimeout = READ_TIMEOUT_MS
        upstream.soTimeout = READ_TIMEOUT_MS

        val downstream = executor.submit(Runnable {
            try {
                pipe(upstream.getInputStream(), client.getOutputStream(), bytesDown, lastActivity)
            } catch (e: IOException) {
                // Connection ended.
            } finally {
                closeQuietly(client)
                closeQuietly(upstream)
            }
        })
        try {
            pipe(clientIn, upstream.getOutputStream(), bytesUp, lastActivity)
            if (!upstream.isClosed) upstream.shutdownOutput()
            downstream.get()
        } catch (e: Exception) {
            downstream.cancel(true)
        }
    }

    private fun pipe(input: InputStream, output: OutputStream, counter: AtomicLong, lastActivity: AtomicLong) {
        val buffer = ByteArray(BUFFER_SIZE)
        while (true) {
            val read = try {
                input.read(buffer)
            } catch (e: SocketTimeoutException) {
                // Only give up when *both* directions have been idle (e.g. a long download has no upload).
                if (System.currentTimeMillis() - lastActivity.get() < IDLE_TIMEOUT_MS) continue
                throw e
            }
            if (read < 0) return
            output.write(buffer, 0, read)
            counter.addAndGet(read.toLong())
            lastActivity.set(System.currentTimeMillis())
        }
    }

    /** Reads the request line and headers (up to the blank line). Returns null on EOF or oversize. */
    private fun readHead(input: InputStream): List<String>? {
        val buffer = ByteArrayOutputStream()
        var tail = 0
        while (true) {
            if (buffer.size() >= MAX_HEAD_BYTES) return null
            val b = input.read()
            if (b < 0) return null
            buffer.write(b)
            tail = (tail shl 8) or b
            if (tail == CRLF_CRLF || (tail and 0xFFFF) == LF_LF) break
        }
        val lines = String(buffer.toByteArray(), Charsets.ISO_8859_1)
            .lines()
            .dropWhile { it.isEmpty() }
            .takeWhile { it.isNotEmpty() }
        return lines.ifEmpty { null }
    }

    private data class HttpTarget(val host: String, val port: Int, val path: String)

    /** Accepts "http://host[:port]/path" (proxy form) or "/path" with a Host header. */
    private fun parseHttpTarget(target: String, head: List<String>): HttpTarget? {
        val authority: String
        val path: String
        if (target.startsWith("http://", ignoreCase = true)) {
            val rest = target.substring("http://".length)
            val slash = rest.indexOf('/').let { if (it < 0) rest.length else it }
            authority = rest.substring(0, slash)
            path = rest.substring(slash).ifEmpty { "/" }
        } else if (target.startsWith("/")) {
            authority = headerValue(head, "Host") ?: return null
            path = target
        } else {
            return null
        }
        val (host, targetPort) = parseHostPort(authority, 80) ?: return null
        return HttpTarget(host, targetPort, path)
    }

    private fun parseHostPort(authority: String, defaultPort: Int): Pair<String, Int>? {
        val value = authority.substringAfterLast('@').trim()
        val host: String
        val portText: String
        if (value.startsWith("[")) {
            val end = value.indexOf(']')
            if (end < 0) return null
            host = value.substring(1, end)
            portText = value.substring(end + 1).removePrefix(":")
        } else {
            val colon = value.lastIndexOf(':')
            host = if (colon >= 0) value.substring(0, colon) else value
            portText = if (colon >= 0) value.substring(colon + 1) else ""
        }
        val targetPort = if (portText.isEmpty()) defaultPort else portText.toIntOrNull() ?: return null
        if (host.isEmpty() || targetPort !in 1..65535) return null
        return host to targetPort
    }

    /** Origin-form request line, hop-by-hop/proxy headers removed, one request per connection. */
    private fun buildRequestHead(method: String, path: String, version: String, head: List<String>): ByteArray {
        val builder = StringBuilder("$method $path $version\r\n")
        for (line in head.drop(1)) {
            val name = line.substringBefore(':').trim()
            if (DROPPED_HEADERS.any { it.equals(name, ignoreCase = true) }) continue
            builder.append(line).append("\r\n")
        }
        builder.append("Connection: close\r\n\r\n")
        return builder.toString().toByteArray(Charsets.ISO_8859_1)
    }

    private fun headerValue(head: List<String>, name: String): String? =
        head.drop(1).firstOrNull { it.substringBefore(':').trim().equals(name, ignoreCase = true) }
            ?.substringAfter(':')?.trim()

    private fun sendError(client: Socket, code: Int, reason: String) {
        val body = "$code $reason\n"
        val response = "HTTP/1.1 $code $reason\r\n" +
            "Content-Type: text/plain\r\n" +
            "Content-Length: ${body.length}\r\n" +
            "Connection: close\r\n\r\n" +
            body
        try {
            client.getOutputStream().write(response.toByteArray(Charsets.ISO_8859_1))
        } catch (e: IOException) {
            // Client already gone.
        }
    }

    private fun closeQuietly(closeable: Closeable?) {
        try {
            closeable?.close()
        } catch (e: IOException) {
            // Ignore.
        }
    }

    companion object {
        private const val TAG = "ShareLink"
        private const val BACKLOG = 128
        private const val MAX_CONNECTIONS = 256
        private const val BUFFER_SIZE = 32 * 1024
        private const val MAX_HEAD_BYTES = 64 * 1024
        private const val CONNECT_TIMEOUT_MS = 15_000
        private const val HEADER_TIMEOUT_MS = 30_000
        private const val READ_TIMEOUT_MS = 60_000
        private const val IDLE_TIMEOUT_MS = 5 * 60_000L
        private const val CRLF_CRLF = 0x0D0A0D0A
        private const val LF_LF = 0x0A0A
        private const val UDP_IDLE_TIMEOUT_MS = 2 * 60_000L
        private const val UDP_BUFFER_SIZE = 65_536
        private const val DNS_PORT = 53

        private const val SOCKS_VERSION = 0x05
        private const val METHOD_NO_AUTH = 0x00
        private const val METHOD_NONE_ACCEPTABLE = 0xFF
        private const val CMD_CONNECT = 0x01
        private const val CMD_UDP_ASSOCIATE = 0x03
        private const val ATYP_IPV4 = 0x01
        private const val ATYP_DOMAIN = 0x03
        private const val ATYP_IPV6 = 0x04
        private const val REP_SUCCEEDED = 0x00
        private const val REP_GENERAL_FAILURE = 0x01
        private const val REP_NETWORK_UNREACHABLE = 0x03
        private const val REP_HOST_UNREACHABLE = 0x04
        private const val REP_CONNECTION_REFUSED = 0x05
        private const val REP_COMMAND_UNSUPPORTED = 0x07
        private const val REP_ADDRESS_UNSUPPORTED = 0x08

        private val CONNECT_OK ="HTTP/1.1 200 Connection Established\r\n\r\n".toByteArray(Charsets.ISO_8859_1)
        private val DROPPED_HEADERS = listOf(
            "Proxy-Connection",
            "Proxy-Authorization",
            "Connection",
            "Keep-Alive",
        )
    }
}
