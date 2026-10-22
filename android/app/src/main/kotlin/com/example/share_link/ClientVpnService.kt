package com.example.share_link

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.File
import java.io.IOException
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket

/**
 * Client mode (Phone B): a local VPN captures every app's traffic and hev-socks5-tunnel forwards
 * it as SOCKS5 (TCP + UDP) to Phone A's proxy over the Wi-Fi Direct network.
 */
class ClientVpnService : VpnService() {

    private class ClientException(val code: String, message: String) : Exception(message)

    private val mainHandler = Handler(Looper.getMainLooper())
    private var tunnel: ParcelFileDescriptor? = null
    private var directNetwork: Network? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var connecting = false

    /** Disconnect was requested while [connect] was still running in the background. */
    private var cancelRequested = false

    private val statsTicker = object : Runnable {
        override fun run() {
            if (tunnel == null) return
            val stats = TProxyService.TProxyGetStats()
            ClientState.update { it.copy(bytesUp = stats[1], bytesDown = stats[3]) }
            mainHandler.postDelayed(this, STATS_INTERVAL_MS)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CONNECT -> connect(intent.getIntExtra(EXTRA_PORT, ShareSettings.DEFAULT_PORT))
            else -> {
                disconnect()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onRevoke() {
        // Another VPN took over, or the user turned ours off in system settings.
        disconnect()
        super.onRevoke()
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }

    private fun connect(port: Int) {
        if (connecting || tunnel != null) return
        connecting = true
        ClientState.update { ClientSnapshot(status = ClientStatus.CONNECTING, port = port) }
        // Finding the network and probing Phone A block, so do it off the main thread.
        Thread({
            val result = runCatching { establish(port) }
            mainHandler.post {
                connecting = false
                if (cancelRequested) {
                    cancelRequested = false
                    disconnect()
                    return@post
                }
                result.onSuccess { host ->
                    ClientState.update { it.copy(status = ClientStatus.CONNECTED, host = host, port = port) }
                    mainHandler.post(statsTicker)
                }.onFailure { e ->
                    Log.e(TAG, "Client connect failed", e)
                    val code = (e as? ClientException)?.code ?: ClientErrorCodes.VPN_FAILED
                    fail(code, e.message)
                }
            }
        }, "client-connect").start()
    }

    /** Runs on a background thread. Returns Phone A's address. */
    private fun establish(port: Int): String {
        val cm = getSystemService(ConnectivityManager::class.java)
        val (network, host) = findDirectNetwork(cm)
            ?: throw ClientException(ClientErrorCodes.NOT_ON_DIRECT_NETWORK, "Not on a DIRECT- network")

        try {
            Socket().use { probe ->
                network.bindSocket(probe)
                probe.connect(InetSocketAddress(host, port), PROBE_TIMEOUT_MS)
            }
        } catch (e: IOException) {
            throw ClientException(ClientErrorCodes.HOST_UNREACHABLE, "${host.hostAddress}:$port: ${e.message}")
        }

        // Load the native library before creating the VPN, so a broken library can't leave a
        // VPN up that swallows all traffic.
        try {
            TProxyService.TProxyIsRunning()
        } catch (e: Throwable) {
            throw ClientException(ClientErrorCodes.VPN_FAILED, "Native tunnel unavailable: $e")
        }

        // Our own process is excluded from the VPN; make the tunnel's sockets use the DIRECT
        // network even if mobile data is the default network.
        cm.bindProcessToNetwork(network)
        directNetwork = network

        val builder = Builder()
            .setSession(getString(R.string.app_name))
            .setMtu(TUNNEL_MTU)
            .addAddress(TUNNEL_IPV4, 32)
            .addAddress(TUNNEL_IPV6, 128)
            .addRoute("0.0.0.0", 0)
            .addRoute("::", 0)
            .addDnsServer(MAPPED_DNS)
            .addDisallowedApplication(packageName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) builder.setMetered(false)

        val fd = builder.establish()
            ?: throw ClientException(ClientErrorCodes.VPN_DENIED, "VPN permission not granted")
        val started = try {
            val config = writeConfig(host.hostAddress ?: DEFAULT_HOST, port)
            TProxyService.TProxyStartService(config.absolutePath, fd.fd)
        } catch (e: Throwable) {
            fd.close()
            throw ClientException(ClientErrorCodes.VPN_FAILED, "Tunnel failed to start: $e")
        }
        if (!started) {
            fd.close()
            throw ClientException(ClientErrorCodes.VPN_FAILED, "Tunnel failed to start")
        }
        tunnel = fd
        watchNetwork(cm, network)
        return host.hostAddress ?: DEFAULT_HOST
    }

    /** The Wi-Fi network on Phone A's Wi-Fi Direct subnet, and Phone A's address (its gateway). */
    private fun findDirectNetwork(cm: ConnectivityManager): Pair<Network, InetAddress>? {
        @Suppress("DEPRECATION")
        for (network in cm.allNetworks) {
            val caps = cm.getNetworkCapabilities(network) ?: continue
            if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) continue
            val link = cm.getLinkProperties(network) ?: continue
            val onDirectSubnet = link.linkAddresses.any {
                it.address is Inet4Address && it.address.hostAddress?.startsWith(DIRECT_SUBNET_PREFIX) == true
            }
            if (onDirectSubnet) return network to (gatewayOf(link) ?: InetAddress.getByName(DEFAULT_HOST))
        }
        return null
    }

    private fun gatewayOf(link: LinkProperties): InetAddress? =
        link.routes.firstOrNull { it.isDefaultRoute && it.gateway is Inet4Address }?.gateway
            ?.takeUnless { it.isAnyLocalAddress }

    private fun watchNetwork(cm: ConnectivityManager, network: Network) {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onLost(lost: Network) {
                if (lost != network) return
                mainHandler.post {
                    fail(ClientErrorCodes.CONNECTION_LOST, "Wi-Fi Direct network lost")
                }
            }
        }
        try {
            cm.registerNetworkCallback(
                NetworkRequest.Builder()
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .build(),
                callback,
            )
            networkCallback = callback
        } catch (e: RuntimeException) {
            Log.w(TAG, "registerNetworkCallback failed", e)
        }
    }

    private fun writeConfig(host: String, port: Int): File {
        val config = """
            |tunnel:
            |  mtu: $TUNNEL_MTU
            |socks5:
            |  port: $port
            |  address: '$host'
            |  udp: 'udp'
            |mapdns:
            |  address: $MAPPED_DNS
            |  port: 53
            |  network: 100.64.0.0
            |  netmask: 255.192.0.0
            |  cache-size: 10000
            |misc:
            |  task-stack-size: 81920
            |  connect-timeout: 10000
            |  tcp-read-write-timeout: 300000
            |  udp-read-write-timeout: 60000
            |""".trimMargin()
        return File(cacheDir, "tunnel.yml").apply { writeText(config) }
    }

    private fun fail(code: String, detail: String?) {
        Log.e(TAG, "Client failed: $code ($detail)")
        disconnect()
        ClientState.update { ClientSnapshot(status = ClientStatus.ERROR, errorCode = code, errorDetail = detail) }
        stopSelf()
    }

    private fun disconnect() {
        if (connecting) cancelRequested = true
        mainHandler.removeCallbacks(statsTicker)
        val cm = getSystemService(ConnectivityManager::class.java)
        networkCallback?.let {
            try {
                cm?.unregisterNetworkCallback(it)
            } catch (e: IllegalArgumentException) {
                // Already unregistered.
            }
        }
        networkCallback = null
        tunnel?.let {
            TProxyService.TProxyStopService()
            try {
                it.close()
            } catch (e: IOException) {
                // Ignore.
            }
        }
        tunnel = null
        if (directNetwork != null) {
            cm?.bindProcessToNetwork(null)
            directNetwork = null
        }
        ClientState.update { if (it.status == ClientStatus.ERROR) it else ClientSnapshot() }
    }

    companion object {
        private const val TAG = "ShareLink"
        private const val ACTION_CONNECT = "com.example.share_link.action.CONNECT"
        private const val ACTION_DISCONNECT = "com.example.share_link.action.DISCONNECT"
        private const val EXTRA_PORT = "port"
        private const val DEFAULT_HOST = "192.168.49.1"
        private const val DIRECT_SUBNET_PREFIX = "192.168.49."
        private const val TUNNEL_MTU = 8500
        private const val TUNNEL_IPV4 = "198.18.0.1"
        private const val TUNNEL_IPV6 = "fc00::1"
        private const val MAPPED_DNS = "198.18.0.2"
        private const val PROBE_TIMEOUT_MS = 3000
        private const val STATS_INTERVAL_MS = 1000L

        fun connect(context: Context, port: Int) {
            context.startService(
                Intent(context, ClientVpnService::class.java)
                    .setAction(ACTION_CONNECT)
                    .putExtra(EXTRA_PORT, port),
            )
        }

        fun disconnect(context: Context) {
            context.startService(Intent(context, ClientVpnService::class.java).setAction(ACTION_DISCONNECT))
        }
    }
}
