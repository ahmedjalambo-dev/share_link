package com.example.share_link

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.Socket
import java.net.URL
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Client mode (Phone B): a local VPN captures every app's traffic and hev-socks5-tunnel forwards
 * it as SOCKS5 (TCP + UDP) to Phone A's proxy over the Wi-Fi Direct network.
 *
 * Two layers:
 * - the **VPN interface** ([vpnFd]) lives from the first successful connect until disconnect;
 * - the **link** ([link]: the DIRECT network, process binding and native tunnel) is replaced on
 *   every reconnect. While Phone A is unreachable the VPN stays up with the tunnel stopped, so
 *   apps' traffic is held (nothing leaks to mobile data) and resumes once the link is back.
 */
class ClientVpnService : VpnService() {

    /** The DIRECT network Phone B rides on, Phone A's address, and the joiner if we joined it. */
    private class Link(val network: Network, val host: String, val joiner: DirectNetworkJoiner?)

    // All fields below are only touched on the main thread, except [pendingJoiner].
    private val mainHandler = Handler(Looper.getMainLooper())
    private val background: ExecutorService = Executors.newSingleThreadExecutor()
    private var vpnFd: ParcelFileDescriptor? = null
    private var link: Link? = null
    private var lossCallback: ConnectivityManager.NetworkCallback? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var port = ShareSettings.DEFAULT_PORT

    /** Between CONNECT and DISCONNECT (or a failed first connect). */
    private var active = false
    private var reconnecting = false
    private var attempt = 0
    private var probeFailures = 0

    /** Bumped on every disconnect so results of stale background work are discarded. */
    private var generation = 0

    /** hev resets its counters on every start, so totals from earlier links are kept here. */
    private var bytesUpBase = 0L
    private var bytesDownBase = 0L

    /** The join in progress on a worker thread, so [disconnect] can cancel Android's dialog. */
    @Volatile
    private var pendingJoiner: DirectNetworkJoiner? = null

    private val statsTicker = object : Runnable {
        override fun run() {
            if (link == null) return
            val stats = TProxyService.TProxyGetStats()
            ClientState.update { it.copy(bytesUp = bytesUpBase + stats[1], bytesDown = bytesDownBase + stats[3]) }
            mainHandler.postDelayed(this, STATS_INTERVAL_MS)
        }
    }

    private val healthProbe = object : Runnable {
        override fun run() = probeCurrentLink()
    }

    private val reconnectAttempt = Runnable { startReconnectAttempt() }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
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
        background.shutdownNow()
        super.onDestroy()
    }

    // region Connect / reconnect

    private fun connect(port: Int) {
        if (active) return
        active = true
        this.port = port
        ClientState.update { ClientSnapshot(status = ClientStatus.CONNECTING, port = port) }
        startForegroundNotification()
        acquireWifiLock()

        val gen = generation
        // Finding/joining the network and probing Phone A block, so do it off the main thread.
        Thread({
            val result = runCatching {
                ensureNativeTunnelLoaded()
                acquireLink(port)
            }
            mainHandler.post {
                if (gen != generation) {
                    result.getOrNull()?.joiner?.release()
                    return@post
                }
                result.mapCatching { startLink(it) }.onFailure { e ->
                    Log.e(TAG, "Client connect failed", e)
                    fail((e as? ClientException)?.code ?: ClientErrorCodes.VPN_FAILED, e.message)
                }
            }
        }, "client-connect").start()
    }

    /** Main thread. Called when the current link stops working. */
    private fun onLinkLost(network: Network, code: String, detail: String) {
        if (!active || reconnecting || link?.network != network) return
        Log.w(TAG, "Link to Phone A lost ($code: $detail); reconnecting")
        stopLink()
        reconnecting = true
        attempt = 0
        scheduleReconnect(code, detail)
    }

    /** Main thread. Shows the next attempt number and waits the backoff delay before trying. */
    private fun scheduleReconnect(code: String?, detail: String?) {
        attempt++
        ClientState.update {
            it.copy(
                status = ClientStatus.RECONNECTING,
                reconnectAttempt = attempt,
                errorCode = code,
                errorDetail = detail,
                joining = false,
            )
        }
        updateNotification()
        mainHandler.postDelayed(reconnectAttempt, reconnectDelayMs(attempt))
    }

    private fun startReconnectAttempt() {
        if (!active || !reconnecting) return
        val gen = generation
        Thread({
            val result = runCatching { acquireLink(port) }
            mainHandler.post {
                if (gen != generation || !active) {
                    result.getOrNull()?.joiner?.release()
                    return@post
                }
                result.mapCatching { startLink(it) }.onFailure { e ->
                    Log.w(TAG, "Reconnect attempt $attempt failed: ${e.message}")
                    scheduleReconnect((e as? ClientException)?.code ?: ClientErrorCodes.VPN_FAILED, e.message)
                }
            }
        }, "client-reconnect").start()
    }

    /**
     * Worker thread; touches no fields except [pendingJoiner]. Finds Phone A's network (joining it
     * if allowed) and checks Phone A answers. On failure everything it set up is undone.
     */
    private fun acquireLink(port: Int): Link {
        val cm = getSystemService(ConnectivityManager::class.java)
        var joiner: DirectNetworkJoiner? = null
        try {
            val (network, host) = NetworkUtils.findDirectNetwork(cm) ?: run {
                val settings = ShareSettings(this)
                if (!settings.clientAutoJoin) {
                    throw ClientException(ClientErrorCodes.NOT_ON_DIRECT_NETWORK, "Not on a DIRECT- network")
                }
                val newJoiner = DirectNetworkJoiner(this)
                joiner = newJoiner
                joinPhoneA(newJoiner, settings)
            }
            if (!probe(network, host, port)) {
                throw ClientException(ClientErrorCodes.HOST_UNREACHABLE, "${host.hostAddress}:$port not answering")
            }
            return Link(network, host.hostAddress ?: DIRECT_OWNER_IP, joiner)
        } catch (e: Throwable) {
            joiner?.release()
            throw e
        } finally {
            pendingJoiner = null
        }
    }

    /** Joins Phone A's network with the saved name/password, showing "Joining…" meanwhile. */
    private fun joinPhoneA(joiner: DirectNetworkJoiner, settings: ShareSettings): Pair<Network, InetAddress> {
        pendingJoiner = joiner
        ClientState.update { it.copy(joining = true) }
        try {
            return joiner.join(settings.clientSsid, settings.clientPassphrase) {
                mainHandler.post {
                    val current = link
                    if (current?.joiner === joiner) {
                        onLinkLost(current.network, ClientErrorCodes.CONNECTION_LOST, "Wi-Fi Direct network lost")
                    }
                }
            }
        } finally {
            ClientState.update { it.copy(joining = false) }
        }
    }

    /**
     * Main thread. Routes our process over [newLink], creates the VPN interface the first time,
     * and (re)starts the native tunnel. Throws [ClientException]; the link is released then.
     */
    private fun startLink(newLink: Link) {
        val cm = getSystemService(ConnectivityManager::class.java)
        // Our own process is excluded from the VPN; make the tunnel's sockets use the DIRECT
        // network even if mobile data is the default network.
        cm.bindProcessToNetwork(newLink.network)
        try {
            val fd = vpnFd ?: createVpnInterface().also { vpnFd = it }
            val started = try {
                TProxyService.TProxyStartService(writeConfig(newLink.host, port).absolutePath, fd.fd)
            } catch (e: Throwable) {
                throw ClientException(ClientErrorCodes.VPN_FAILED, "Tunnel failed to start: $e")
            }
            if (!started) throw ClientException(ClientErrorCodes.VPN_FAILED, "Tunnel failed to start")
        } catch (e: Throwable) {
            cm.bindProcessToNetwork(null)
            newLink.joiner?.release()
            throw e
        }

        link = newLink
        reconnecting = false
        attempt = 0
        probeFailures = 0
        // A joined network reports its own loss through the joiner.
        if (newLink.joiner?.reportsLoss != true) watchNetwork(newLink.network)
        ClientState.update {
            it.copy(
                status = ClientStatus.CONNECTED,
                host = newLink.host,
                port = port,
                reconnectAttempt = 0,
                errorCode = null,
                errorDetail = null,
                joining = false,
            )
        }
        updateNotification()
        mainHandler.removeCallbacks(statsTicker)
        mainHandler.post(statsTicker)
        mainHandler.postDelayed(healthProbe, PROBE_INTERVAL_MS)
        learnPhoneANetworkName(newLink)
    }

    /** Main thread. Stops the tunnel and leaves the current link; the VPN interface stays up. */
    private fun stopLink() {
        mainHandler.removeCallbacks(healthProbe)
        mainHandler.removeCallbacks(statsTicker)
        val current = link ?: return
        link = null
        val stats = TProxyService.TProxyGetStats()
        bytesUpBase += stats[1]
        bytesDownBase += stats[3]
        TProxyService.TProxyStopService()
        lossCallback?.let {
            try {
                getSystemService(ConnectivityManager::class.java)?.unregisterNetworkCallback(it)
            } catch (e: IllegalArgumentException) {
                // Already unregistered.
            }
        }
        lossCallback = null
        getSystemService(ConnectivityManager::class.java)?.bindProcessToNetwork(null)
        current.joiner?.release()
    }

    // endregion

    // region Loss detection

    private fun watchNetwork(network: Network) {
        val cm = getSystemService(ConnectivityManager::class.java) ?: return
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onLost(lost: Network) {
                if (lost != network) return
                mainHandler.post {
                    onLinkLost(network, ClientErrorCodes.CONNECTION_LOST, "Wi-Fi Direct network lost")
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
            lossCallback = callback
        } catch (e: RuntimeException) {
            Log.w(TAG, "registerNetworkCallback failed", e)
        }
    }

    /**
     * Main thread, every [PROBE_INTERVAL_MS]: checks Phone A still answers. This catches Phone A's
     * proxy restarting or hanging while the Wi-Fi link itself stays up.
     */
    private fun probeCurrentLink() {
        val current = link ?: return
        background.execute {
            val alive = probe(current.network, InetAddress.getByName(current.host), port)
            mainHandler.post {
                if (link !== current) return@post
                if (alive) {
                    probeFailures = 0
                } else if (++probeFailures >= PROBE_FAILURES_BEFORE_LOST) {
                    onLinkLost(current.network, ClientErrorCodes.HOST_UNREACHABLE, "Phone A stopped answering")
                    return@post
                }
                mainHandler.postDelayed(healthProbe, PROBE_INTERVAL_MS)
            }
        }
    }

    /** Any thread. True if Phone A's proxy accepts a TCP connection over [network]. */
    private fun probe(network: Network, host: InetAddress, port: Int): Boolean = try {
        Socket().use { socket ->
            network.bindSocket(socket)
            socket.connect(InetSocketAddress(host, port), PROBE_TIMEOUT_MS)
        }
        true
    } catch (e: IOException) {
        false
    }

    // endregion

    /**
     * When the user left the network name empty (Android's picker was used), ask Phone A for its
     * exact name and save it, so later reconnects can rejoin without the picker.
     */
    private fun learnPhoneANetworkName(current: Link) {
        val settings = ShareSettings(this)
        if (!settings.clientAutoJoin || settings.clientSsid.isNotEmpty()) return
        background.execute {
            try {
                val url = URL("http", current.host, port, PHONE_A_INFO_PATH)
                val connection = current.network.openConnection(url, Proxy.NO_PROXY) as HttpURLConnection
                connection.connectTimeout = PROBE_TIMEOUT_MS
                connection.readTimeout = PROBE_TIMEOUT_MS
                val body = try {
                    connection.inputStream.bufferedReader().use { it.readText() }
                } finally {
                    connection.disconnect()
                }
                parseInfoSsid(body)?.let {
                    settings.saveClientSsid(it)
                    Log.i(TAG, "Learned Phone A's network name: $it")
                }
            } catch (e: IOException) {
                // Older Phone A without the info endpoint; reconnects will use the picker.
            }
        }
    }

    private fun ensureNativeTunnelLoaded() {
        // Load the native library before creating the VPN, so a broken library can't leave a
        // VPN up that swallows all traffic.
        try {
            TProxyService.TProxyIsRunning()
        } catch (e: Throwable) {
            throw ClientException(ClientErrorCodes.VPN_FAILED, "Native tunnel unavailable: $e")
        }
    }

    private fun createVpnInterface(): ParcelFileDescriptor {
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
        return builder.establish()
            ?: throw ClientException(ClientErrorCodes.VPN_DENIED, "VPN permission not granted")
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

    /** Only used when the first connect fails; drops are handled by reconnecting instead. */
    private fun fail(code: String, detail: String?) {
        Log.e(TAG, "Client failed: $code ($detail)")
        disconnect()
        ClientState.update { ClientSnapshot(status = ClientStatus.ERROR, errorCode = code, errorDetail = detail) }
        stopSelf()
    }

    private fun disconnect() {
        if (!active && vpnFd == null) return
        active = false
        reconnecting = false
        generation++
        // Cancels a join still waiting on Android's dialog.
        pendingJoiner?.release()
        mainHandler.removeCallbacks(reconnectAttempt)
        stopLink()
        closeQuietly(vpnFd)
        vpnFd = null
        bytesUpBase = 0
        bytesDownBase = 0
        releaseWifiLock()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        ClientState.update { if (it.status == ClientStatus.ERROR) it else ClientSnapshot() }
    }

    // region Keep-alive: foreground notification and Wi-Fi lock

    /** Foreground importance lets the reconnect loop join Wi-Fi while the app is in the background. */
    private fun startForegroundNotification() {
        try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                buildNotification(ClientState.current),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
                } else {
                    0
                },
            )
        } catch (e: Exception) {
            // Still works while the app is open; only background reconnects get less reliable.
            Log.w(TAG, "Client startForeground failed", e)
        }
    }

    @SuppressLint("MissingPermission")
    private fun updateNotification() {
        if (!active) return
        try {
            getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, buildNotification(ClientState.current))
        } catch (e: SecurityException) {
            Log.w(TAG, "Cannot update notification", e)
        }
    }

    private fun buildNotification(state: ClientSnapshot): Notification {
        val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            flags,
        )
        val disconnect = PendingIntent.getService(
            this,
            2,
            Intent(this, ClientVpnService::class.java).setAction(ACTION_DISCONNECT),
            flags,
        )
        val title = when (state.status) {
            ClientStatus.CONNECTED -> getString(R.string.client_notif_connected)
            ClientStatus.RECONNECTING -> getString(R.string.client_notif_reconnecting, state.reconnectAttempt)
            else -> getString(R.string.client_notif_connecting)
        }
        val text = state.host?.let { "$it:${state.port}" }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_share)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(openApp)
            .addAction(0, getString(R.string.client_notif_disconnect), disconnect)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.client_notif_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        )
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    /** Keeps Phone B's Wi-Fi awake with the screen off, so the link drops less often. */
    @Suppress("DEPRECATION")
    private fun acquireWifiLock() {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        wifiLock = wifiManager.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "ShareLink:client-wifi").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseWifiLock() {
        wifiLock?.takeIf { it.isHeld }?.release()
        wifiLock = null
    }

    // endregion

    companion object {
        private const val ACTION_CONNECT = "com.example.share_link.action.CONNECT"
        private const val ACTION_DISCONNECT = "com.example.share_link.action.DISCONNECT"
        private const val EXTRA_PORT = "port"
        private const val CHANNEL_ID = "share_link_client"
        private const val NOTIFICATION_ID = 2
        private const val TUNNEL_MTU = 8500
        private const val TUNNEL_IPV4 = "198.18.0.1"
        private const val TUNNEL_IPV6 = "fc00::1"
        private const val MAPPED_DNS = "198.18.0.2"
        private const val PROBE_TIMEOUT_MS = 3000
        private const val PROBE_INTERVAL_MS = 15_000L
        private const val PROBE_FAILURES_BEFORE_LOST = 2
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
