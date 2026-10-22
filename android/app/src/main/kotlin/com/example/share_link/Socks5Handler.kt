package com.example.share_link

import android.net.Network
import android.util.Log
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
import java.net.Socket
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

/**
 * SOCKS5 (RFC 1928) without authentication: the Wi-Fi Direct passphrase already protects the
 * network. Supports CONNECT and UDP ASSOCIATE (DNS, voice/video calls).
 */
internal class Socks5Handler(private val server: ProxyServer) {

    fun handle(client: Socket, input: InputStream) {
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
        val target = readSocksTarget(data) ?: return sendReply(out, REP_ADDRESS_UNSUPPORTED)

        when (command) {
            CMD_CONNECT -> connect(client, input, out, target)
            CMD_UDP_ASSOCIATE -> udpAssociate(client, input, out)
            else -> sendReply(out, REP_COMMAND_UNSUPPORTED)
        }
    }

    private fun connect(client: Socket, input: InputStream, out: OutputStream, target: SocksTarget) {
        val upstream = try {
            server.connectUpstream(target.host, target.port)
        } catch (e: IOException) {
            Log.d(TAG, "SOCKS upstream ${target.host}:${target.port} failed: ${e.message}")
            sendReply(out, replyFor(e))
            return
        }
        try {
            sendReply(out, REP_SUCCEEDED)
            server.tunnel(client, input, upstream)
        } finally {
            server.release(upstream)
        }
    }

    private fun udpAssociate(client: Socket, input: InputStream, out: OutputStream) {
        val network = server.upstreamNetwork()
        if (network == null) {
            sendReply(out, REP_NETWORK_UNREACHABLE)
            return
        }
        val association = try {
            UdpAssociation(client.inetAddress, client.localAddress, network)
        } catch (e: IOException) {
            sendReply(out, REP_GENERAL_FAILURE)
            return
        }
        try {
            sendReply(out, REP_SUCCEEDED, InetSocketAddress(client.localAddress, association.relayPort))
            server.executor.execute { association.clientToRemote() }
            server.executor.execute { association.remoteToClient() }
            // The association lives as long as its TCP control connection (RFC 1928 §7).
            holdControlConnection(client, input, association.lastActivity)
        } finally {
            association.close()
        }
    }

    private fun holdControlConnection(client: Socket, input: InputStream, lastActivity: AtomicLong) {
        client.soTimeout = ProxyServer.READ_TIMEOUT_MS
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
            server.openDatagrams.add(relay)
            server.openDatagrams.add(remote)
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
                        server.upstreamDns()?.let { destination = InetSocketAddress(it, DNS_PORT) }
                    }
                    replyHeaders[destination] = buffer.copyOfRange(0, headerLength)
                    val payloadLength = packet.length - headerLength
                    remote.send(DatagramPacket(buffer, headerLength, payloadLength, destination))
                    server.bytesUp.addAndGet(payloadLength.toLong())
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
                    server.bytesDown.addAndGet(packet.length.toLong())
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
            server.openDatagrams.remove(relay)
            server.openDatagrams.remove(remote)
        }
    }

    private fun sendReply(out: OutputStream, reply: Int, bound: InetSocketAddress? = null) {
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

    private fun replyFor(e: IOException) = when (e) {
        is UnknownHostException -> REP_HOST_UNREACHABLE
        is ConnectException -> REP_CONNECTION_REFUSED
        is SocketTimeoutException -> REP_HOST_UNREACHABLE
        else -> REP_GENERAL_FAILURE
    }
}

// Pure parsing helpers (unit-tested in ProxyParsingTest).

internal data class SocksTarget(val host: String, val port: Int)

/** Reads ATYP DST.ADDR DST.PORT from a SOCKS5 request. */
internal fun readSocksTarget(data: DataInputStream): SocksTarget? {
    val host = when (data.readUnsignedByte()) {
        ATYP_IPV4 -> InetAddress.getByAddress(ByteArray(4).also { data.readFully(it) }).hostAddress
        ATYP_IPV6 -> InetAddress.getByAddress(ByteArray(16).also { data.readFully(it) }).hostAddress
        ATYP_DOMAIN -> String(ByteArray(data.readUnsignedByte()).also { data.readFully(it) }, Charsets.ISO_8859_1)
        else -> return null
    } ?: return null
    return SocksTarget(host, data.readUnsignedShort())
}

/** Length of the SOCKS5 UDP header (RSV RSV FRAG ATYP ADDR PORT), or null if invalid/fragmented. */
internal fun udpHeaderLength(buffer: ByteArray, length: Int): Int? {
    if (length < 4 || buffer[2].toInt() != 0) return null
    val headerLength = when (buffer[3].toInt()) {
        ATYP_IPV4 -> 4 + 4 + 2
        ATYP_IPV6 -> 4 + 16 + 2
        ATYP_DOMAIN -> if (length > 4) 4 + 1 + (buffer[4].toInt() and 0xFF) + 2 else return null
        else -> return null
    }
    return if (length >= headerLength) headerLength else null
}

/** Destination of a SOCKS5 UDP datagram; call only after [udpHeaderLength] accepted it. */
internal fun parseUdpTarget(buffer: ByteArray): SocksTarget? {
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

/** SOCKS5 UDP header for a reply coming from [address]. */
internal fun udpHeaderFor(address: InetSocketAddress): ByteArray {
    val ip = address.address.address
    val header = ByteArray(4 + ip.size + 2)
    header[3] = (if (ip.size == 4) ATYP_IPV4 else ATYP_IPV6).toByte()
    System.arraycopy(ip, 0, header, 4, ip.size)
    header[header.size - 2] = (address.port shr 8).toByte()
    header[header.size - 1] = address.port.toByte()
    return header
}

internal const val SOCKS_VERSION = 0x05
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
private const val UDP_IDLE_TIMEOUT_MS = 2 * 60_000L
private const val UDP_BUFFER_SIZE = 65_536
private const val DNS_PORT = 53
