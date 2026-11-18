package com.example.share_link

import android.net.Network
import android.util.Log
import java.io.BufferedInputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.DatagramSocket
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
 * Proxy on a single port. The first byte picks the protocol:
 * - 0x05 → SOCKS5 ([Socks5Handler]): CONNECT and UDP ASSOCIATE, used by client mode on Phone B.
 * - anything else → HTTP ([HttpProxyHandler]): plain requests and CONNECT, for a manual Wi-Fi proxy.
 *
 * One thread per client plus one pump thread per tunnel. Outgoing sockets and DNS go through
 * the network returned by [upstreamNetwork] (Phone A's Wi-Fi).
 */
class ProxyServer(
    private val port: Int,
    internal val upstreamNetwork: () -> Network?,
    /** DNS server of the Wi-Fi network; UDP DNS queries from clients are redirected to it. */
    internal val upstreamDns: () -> InetAddress? = { null },
    /** This phone's Wi-Fi Direct network name, served to Phone B at [PHONE_A_INFO_PATH]. */
    internal val networkName: () -> String? = { null },
) {
    val activeConnections = AtomicInteger()
    val bytesUp = AtomicLong()
    val bytesDown = AtomicLong()

    /** Per-client traffic and blocking, for the devices list. */
    internal val devices = DeviceRegistry()

    private val threadCounter = AtomicInteger()
    internal val executor: ExecutorService = Executors.newCachedThreadPool { runnable ->
        Thread(runnable, "proxy-${threadCounter.incrementAndGet()}").apply { isDaemon = true }
    }

    /** Everything still open, so [stop] can unblock every thread at once. */
    private val openSockets: MutableSet<Socket> = ConcurrentHashMap.newKeySet()
    internal val openDatagrams: MutableSet<DatagramSocket> = ConcurrentHashMap.newKeySet()

    private val http = HttpProxyHandler(this)
    private val socks = Socks5Handler(this)

    @Volatile
    private var serverSocket: ServerSocket? = null

    /** Extra listeners from [startTcpRelay] (e.g. the WhatsApp proxy ports). */
    private val relayServers: MutableSet<ServerSocket> = ConcurrentHashMap.newKeySet()

    @Volatile
    private var running = false

    /** Binds to [bindAddress]:[port] and starts accepting. Throws if the bind fails. */
    @Throws(IOException::class)
    fun start(bindAddress: InetAddress) {
        val server = bindServer(bindAddress, port)
        serverSocket = server
        running = true
        executor.execute { acceptLoop(server, ::handleClient) }
        Log.i(TAG, "Proxy listening on ${bindAddress.hostAddress}:$port")
    }

    /**
     * Also listens on [listenPort] and pipes every connection, unchanged, to the fixed
     * [targetHost]:[targetPort] over Wi-Fi. Only that target is reachable, so it isn't an open
     * relay. Call after [start]; throws if the port can't be bound.
     */
    @Throws(IOException::class)
    fun startTcpRelay(bindAddress: InetAddress, listenPort: Int, targetHost: String, targetPort: Int) {
        val server = bindServer(bindAddress, listenPort)
        relayServers.add(server)
        executor.execute { acceptLoop(server) { client -> handleRelay(client, targetHost, targetPort) } }
        Log.i(TAG, "Relay ${bindAddress.hostAddress}:$listenPort → $targetHost:$targetPort")
    }

    private fun bindServer(bindAddress: InetAddress, listenPort: Int): ServerSocket {
        val server = ServerSocket()
        try {
            server.reuseAddress = true
            server.bind(InetSocketAddress(bindAddress, listenPort), BACKLOG)
        } catch (e: IOException) {
            closeQuietly(server)
            throw e
        }
        return server
    }

    fun stop() {
        running = false
        closeQuietly(serverSocket)
        serverSocket = null
        relayServers.forEach(::closeQuietly)
        relayServers.clear()
        openSockets.forEach(::closeQuietly)
        openSockets.clear()
        openDatagrams.forEach(::closeQuietly)
        openDatagrams.clear()
        executor.shutdownNow()
        Log.i(TAG, "Proxy stopped")
    }

    private fun acceptLoop(server: ServerSocket, handler: (Socket) -> Unit) {
        while (running) {
            val client = try {
                server.accept()
            } catch (e: IOException) {
                if (running) Log.w(TAG, "accept failed", e)
                break
            }
            if (devices.isBlocked(client.inetAddress) || activeConnections.get() >= MAX_CONNECTIONS) {
                closeQuietly(client)
                continue
            }
            try {
                executor.execute { handler(client) }
            } catch (e: RejectedExecutionException) {
                closeQuietly(client)
            }
        }
    }

    /** One relay connection: no protocol, just bytes both ways to the fixed target. */
    private fun handleRelay(client: Socket, targetHost: String, targetPort: Int) {
        activeConnections.incrementAndGet()
        openSockets.add(client)
        devices.opened(client.inetAddress, client)
        try {
            client.tcpNoDelay = true
            val upstream = connectUpstream(targetHost, targetPort)
            try {
                tunnel(client, client.getInputStream(), upstream)
            } finally {
                release(upstream)
            }
        } catch (e: IOException) {
            Log.d(TAG, "Relay to $targetHost:$targetPort failed: ${e.message}")
        } catch (e: Exception) {
            Log.w(TAG, "Unexpected relay error", e)
        } finally {
            release(client)
            devices.closed(client.inetAddress, client)
            activeConnections.decrementAndGet()
        }
    }

    private fun handleClient(client: Socket) {
        activeConnections.incrementAndGet()
        openSockets.add(client)
        devices.opened(client.inetAddress, client)
        try {
            client.soTimeout = HEADER_TIMEOUT_MS
            client.tcpNoDelay = true
            val input = BufferedInputStream(client.getInputStream())
            input.mark(1)
            val first = input.read()
            if (first < 0) return
            input.reset()
            if (first == SOCKS_VERSION) socks.handle(client, input) else http.handle(client, input)
        } catch (e: IOException) {
            // Timeouts, resets and closes are normal for a proxy.
        } catch (e: Exception) {
            Log.w(TAG, "Unexpected proxy error", e)
        } finally {
            release(client)
            devices.closed(client.inetAddress, client)
            activeConnections.decrementAndGet()
        }
    }

    /** Counts bytes sent from [client] to the internet, in total and for that device. */
    internal fun countUp(client: InetAddress, bytes: Long) {
        bytesUp.addAndGet(bytes)
        devices.countUp(client, bytes)
    }

    /** Counts bytes sent from the internet to [client], in total and for that device. */
    internal fun countDown(client: InetAddress, bytes: Long) {
        bytesDown.addAndGet(bytes)
        devices.countDown(client, bytes)
    }

    /** Opens a TCP connection over Wi-Fi; the caller must [release] it. */
    internal fun connectUpstream(host: String, targetPort: Int): Socket {
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
                openSockets.add(socket)
                return socket
            } catch (e: IOException) {
                closeQuietly(socket)
                lastError = e
            }
        }
        throw lastError ?: UnknownHostException(host)
    }

    internal fun release(socket: Socket) {
        closeQuietly(socket)
        openSockets.remove(socket)
    }

    /**
     * Pipes bytes both ways until the server finishes. Client EOF half-closes the upstream so the
     * response can still arrive; server EOF ends the whole tunnel.
     */
    internal fun tunnel(client: Socket, clientIn: InputStream, upstream: Socket) {
        val lastActivity = AtomicLong(System.currentTimeMillis())
        val address = client.inetAddress
        client.soTimeout = READ_TIMEOUT_MS
        upstream.soTimeout = READ_TIMEOUT_MS

        val downstream = executor.submit(Runnable {
            try {
                pipe(upstream.getInputStream(), client.getOutputStream(), lastActivity) { countDown(address, it) }
            } catch (e: IOException) {
                // Connection ended.
            } finally {
                closeQuietly(client)
                closeQuietly(upstream)
            }
        })
        try {
            pipe(clientIn, upstream.getOutputStream(), lastActivity) { countUp(address, it) }
            if (!upstream.isClosed) upstream.shutdownOutput()
            downstream.get()
        } catch (e: Exception) {
            downstream.cancel(true)
        }
    }

    private fun pipe(input: InputStream, output: OutputStream, lastActivity: AtomicLong, count: (Long) -> Unit) {
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
            count(read.toLong())
            lastActivity.set(System.currentTimeMillis())
        }
    }

    companion object {
        private const val BACKLOG = 128
        private const val MAX_CONNECTIONS = 256
        private const val BUFFER_SIZE = 32 * 1024
        private const val CONNECT_TIMEOUT_MS = 15_000
        private const val HEADER_TIMEOUT_MS = 30_000
        internal const val READ_TIMEOUT_MS = 60_000
        private const val IDLE_TIMEOUT_MS = 5 * 60_000L
    }
}
