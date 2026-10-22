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
) {
    val activeConnections = AtomicInteger()
    val bytesUp = AtomicLong()
    val bytesDown = AtomicLong()

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
        openDatagrams.forEach(::closeQuietly)
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
            activeConnections.decrementAndGet()
        }
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
