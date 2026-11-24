package com.example.share_link

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import java.io.IOException
import java.net.BindException
import java.net.Inet4Address
import java.net.InetAddress

/** Foreground service that owns the Wi-Fi Direct group and the proxy server. */
class ShareService : Service() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var settings: ShareSettings
    private lateinit var wifiDirect: WifiDirectController
    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var proxy: ProxyServer? = null
    private var started = false
    private var destroyed = false

    /** Phone A's Wi-Fi network; all proxy traffic goes out through it. */
    @Volatile
    private var upstreamNetwork: Network? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    private val meter = TrafficMeter()

    /** Name, password and band of this session; a lost group is recreated with them. */
    private var shareName = ""
    private var sharePassphrase = ""
    private var shareBand = BAND_AUTO

    /** Recreating the group after Android dropped it. */
    private var recovering = false
    private var recoveryAttempt = 0

    /** Checks in a row that didn't find the group; one can be a passing hiccup. */
    private var groupMisses = 0

    /** The Wi-Fi passed Android's internet check; see [registerWifiCallback]. */
    @Volatile
    private var upstreamValidated = true
    private var p2pReceiver: BroadcastReceiver? = null

    private val groupWatch = Runnable { checkGroup() }
    private val recoveryRetry = Runnable { recoverGroup() }

    private val statsTicker = object : Runnable {
        override fun run() {
            val server = proxy ?: return
            val up = server.bytesUp.get()
            val down = server.bytesDown.get()
            val now = SystemClock.elapsedRealtime()
            val (speedUp, speedDown) = meter.sample(up, down, now)
            val devices = server.devices.snapshot(now, settings.deviceNicknames)
            ShareState.update {
                it.copy(
                    activeConnections = server.activeConnections.get(),
                    bytesUp = up,
                    bytesDown = down,
                    speedUp = speedUp,
                    speedDown = speedDown,
                    upstreamAvailable = upstreamNetwork != null,
                    devices = devices,
                )
            }
            mainHandler.postDelayed(this, STATS_INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        settings = ShareSettings(this)
        wifiDirect = WifiDirectController(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startSharing()
            else -> stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        destroyed = true
        mainHandler.removeCallbacks(statsTicker)
        mainHandler.removeCallbacks(groupWatch)
        mainHandler.removeCallbacks(recoveryRetry)
        unregisterP2pReceiver()
        runningProxy = null
        proxy?.stop()
        proxy = null
        unregisterWifiCallback()
        wifiDirect.onChannelLost = null
        wifiDirect.removeGroup()
        releaseLocks()
        // Keep the notification and turn it into "Sharing stopped" [Start], so sharing can be
        // toggled from the notification shade.
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_DETACH)
        // Keep an error visible to the UI; otherwise go back to "stopped".
        ShareState.update { if (it.status == ShareStatus.ERROR) it else ShareSnapshot() }
        postStoppedNotification()
        Log.i(TAG, "Service destroyed")
        super.onDestroy()
    }

    private fun startSharing() {
        if (started) return
        started = true

        val starting = ShareSnapshot(status = ShareStatus.STARTING, port = settings.port)
        try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                buildNotification(starting),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
                } else {
                    0
                },
            )
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed", e)
            fail(ErrorCodes.SERVICE_FAILED, e.message)
            return
        }
        // The notification's Start button starts this service without going through the app,
        // so run the same checks here (after startForeground, which must come first).
        AppActions.sharePreflightError(this)?.let { code ->
            fail(code, null)
            return
        }

        acquireLocks()
        registerWifiCallback()
        ShareState.update { starting }

        wifiDirect.onChannelLost = {
            if (proxy != null) {
                startRecovery("Wi-Fi Direct framework disconnected")
            } else {
                fail(ErrorCodes.P2P_ERROR, "Wi-Fi Direct framework disconnected")
            }
        }
        shareName = settings.fullSsid
        sharePassphrase = settings.passphrase
        shareBand = settings.band
        val band = shareBand
        wifiDirect.createGroup(shareName, sharePassphrase, band) { result ->
            result.onSuccess { group -> startProxy(group, band) }
                .onFailure { e ->
                    fail((e as? WifiDirectController.GroupException)?.code ?: ErrorCodes.P2P_ERROR, e.message)
                }
        }
    }

    /** Binds the proxy off the main thread; the group's IP can take a moment to appear on the interface. */
    private fun startProxy(group: WifiDirectController.GroupDetails, band: String) {
        val port = settings.port
        Thread({
            val server = ProxyServer(port, { upstreamNetwork }, ::upstreamDnsServer) { ShareState.current.ssid }
            // Give DHCP and the group info a moment before asking Wi-Fi Direct for the name.
            server.devices.onNewDevice = { mainHandler.postDelayed(::lookUpDeviceNames, NAME_LOOKUP_DELAY_MS) }
            var error: IOException? = null
            for (attempt in 1..BIND_ATTEMPTS) {
                try {
                    server.start(InetAddress.getByName(group.ownerIp))
                    error = null
                    break
                } catch (e: IOException) {
                    error = e
                    Log.w(TAG, "Proxy bind attempt $attempt failed: ${e.message}")
                    Thread.sleep(BIND_RETRY_MS)
                }
            }
            mainHandler.post { onProxyStarted(group, band, port, server, error) }
        }, "proxy-start").start()
    }

    private fun onProxyStarted(
        group: WifiDirectController.GroupDetails,
        requestedBand: String,
        port: Int,
        server: ProxyServer,
        error: IOException?,
    ) {
        if (destroyed) {
            server.stop()
            return
        }
        if (error != null) {
            server.stop()
            val inUse = error is BindException && error.message?.contains("in use", ignoreCase = true) == true
            fail(if (inUse) ErrorCodes.PORT_IN_USE else ErrorCodes.PROXY_FAILED, error.message)
            return
        }
        proxy = server
        runningProxy = server
        // WhatsApp proxy for phones without the app; if its ports can't be opened, sharing still runs.
        val whatsApp = WhatsAppRelay.start(server, InetAddress.getByName(group.ownerIp))
        val band = bandOfFrequency(group.frequencyMhz)
        ShareState.update {
            it.copy(
                whatsAppProxy = whatsApp,
                status = ShareStatus.RUNNING,
                ssid = group.ssid,
                passphrase = group.passphrase,
                ownerIp = group.ownerIp,
                port = port,
                upstreamAvailable = upstreamNetwork != null,
                startedAt = System.currentTimeMillis(),
                band = band,
                bandNotHonored = !bandHonored(requestedBand, group.bandFallback, band),
            )
        }
        meter.reset()
        updateNotification()
        mainHandler.post(statsTicker)
        registerP2pReceiver()
        scheduleGroupCheck()
    }

    // region Group recovery: some phones drop the Wi-Fi Direct group when their own Wi-Fi
    // disconnects or changes channel, without telling the app. Watch it and recreate it.

    private fun scheduleGroupCheck(delayMs: Long = GROUP_CHECK_MS) {
        mainHandler.removeCallbacks(groupWatch)
        mainHandler.postDelayed(groupWatch, delayMs)
    }

    private fun checkGroup() {
        if (destroyed || recovering || proxy == null) return
        // Below Android 10 the name is random, so only the group's existence is checked.
        val expected = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ShareState.current.ssid else null
        wifiDirect.checkGroup(expected) { ok ->
            if (destroyed || recovering) return@checkGroup
            when {
                ok -> {
                    groupMisses = 0
                    scheduleGroupCheck()
                }
                ++groupMisses < GROUP_MISSES_BEFORE_LOST -> scheduleGroupCheck(GROUP_RECHECK_MS)
                else -> startRecovery("group gone")
            }
        }
    }

    private fun startRecovery(reason: String) {
        if (destroyed || recovering) return
        Log.w(TAG, "Wi-Fi Direct group lost ($reason); recreating it")
        recovering = true
        recoveryAttempt = 0
        groupMisses = 0
        mainHandler.removeCallbacks(groupWatch)
        ShareState.update { it.copy(recovering = true) }
        updateNotification()
        recoverGroup()
    }

    /** Same name, password and band as before, so the other phones rejoin by themselves. */
    private fun recoverGroup() {
        if (destroyed) return
        recoveryAttempt++
        wifiDirect.createGroup(shareName, sharePassphrase, shareBand) { result ->
            if (destroyed) return@createGroup
            result.onSuccess { group -> rebindProxy(group) }
                .onFailure { e ->
                    retryRecovery((e as? WifiDirectController.GroupException)?.code ?: ErrorCodes.P2P_ERROR, e.message)
                }
        }
    }

    private fun retryRecovery(code: String, detail: String?) {
        if (recoveryAttempt >= MAX_RECOVERY_ATTEMPTS) {
            fail(code, detail)
            return
        }
        Log.w(TAG, "Recreating the group failed (attempt $recoveryAttempt): $detail")
        mainHandler.postDelayed(recoveryRetry, reconnectDelayMs(recoveryAttempt))
    }

    /** Listens on the recreated group's address; counters, devices and blocks are kept. */
    private fun rebindProxy(group: WifiDirectController.GroupDetails) {
        val server = proxy ?: return
        Thread({
            var error: IOException? = null
            for (attempt in 1..BIND_ATTEMPTS) {
                try {
                    server.rebind(InetAddress.getByName(group.ownerIp))
                    error = null
                    break
                } catch (e: IOException) {
                    error = e
                    Thread.sleep(BIND_RETRY_MS)
                }
            }
            mainHandler.post { onGroupRecovered(group, error) }
        }, "proxy-rebind").start()
    }

    private fun onGroupRecovered(group: WifiDirectController.GroupDetails, error: IOException?) {
        if (destroyed) return
        if (error != null) {
            retryRecovery(ErrorCodes.PROXY_FAILED, error.message)
            return
        }
        recovering = false
        recoveryAttempt = 0
        // Connections from before the drop are dead; let clients open new ones right away.
        proxy?.resetUpstream()
        val band = bandOfFrequency(group.frequencyMhz)
        ShareState.update {
            it.copy(
                recovering = false,
                ssid = group.ssid,
                passphrase = group.passphrase,
                ownerIp = group.ownerIp,
                band = band,
                bandNotHonored = !bandHonored(shareBand, group.bandFallback, band),
            )
        }
        updateNotification()
        Log.i(TAG, "Wi-Fi Direct group recreated")
        scheduleGroupCheck()
    }

    /** Android announces Wi-Fi Direct changes; check the group then instead of waiting. */
    private fun registerP2pReceiver() {
        if (p2pReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (!recovering && proxy != null) scheduleGroupCheck(GROUP_RECHECK_MS)
            }
        }
        ContextCompat.registerReceiver(
            this,
            receiver,
            IntentFilter(WifiDirectController.CONNECTION_CHANGED),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        p2pReceiver = receiver
    }

    private fun unregisterP2pReceiver() {
        val receiver = p2pReceiver ?: return
        p2pReceiver = null
        try {
            unregisterReceiver(receiver)
        } catch (e: IllegalArgumentException) {
            // Already unregistered.
        }
    }

    // endregion

    /**
     * Any thread. Closes connections that went out through a Wi-Fi network that is gone or that
     * just got its internet back, so clients reconnect now instead of hanging for minutes.
     */
    private fun resetUpstream(reason: String) {
        mainHandler.post {
            val closed = proxy?.resetUpstream() ?: return@post
            if (closed > 0) Log.i(TAG, "Upstream reset ($reason): closed $closed connections")
        }
    }

    /** Names devices from the Wi-Fi Direct group's client list (Android 15+ knows their IPs). */
    private fun lookUpDeviceNames() {
        val server = proxy ?: return
        wifiDirect.requestClientNames { names ->
            names.forEach { (address, name) -> server.devices.nameDevice(address, name, NameSource.WIFI_DIRECT) }
        }
    }

    private fun fail(code: String, detail: String?) {
        Log.e(TAG, "Sharing failed: $code ($detail)")
        ShareState.update { ShareSnapshot(status = ShareStatus.ERROR, errorCode = code, errorDetail = detail) }
        stopSelf()
    }

    private fun upstreamDnsServer(): InetAddress? {
        val network = upstreamNetwork ?: return null
        return getSystemService(ConnectivityManager::class.java)
            ?.getLinkProperties(network)
            ?.dnsServers
            ?.firstOrNull { it is Inet4Address }
    }

    private fun registerWifiCallback() {
        upstreamNetwork = NetworkUtils.findWifiNetwork(this)
        val cm = getSystemService(ConnectivityManager::class.java) ?: return
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                Log.i(TAG, "Wi-Fi available: $network")
                val previous = upstreamNetwork
                upstreamNetwork = network
                if (previous != null && previous != network) resetUpstream("Wi-Fi switched")
            }

            override fun onLost(network: Network) {
                Log.w(TAG, "Wi-Fi lost: $network")
                if (upstreamNetwork == network) {
                    upstreamNetwork = null
                    resetUpstream("Wi-Fi lost")
                }
            }

            override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
                if (network != upstreamNetwork) return
                val validated = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
                // The Wi-Fi stayed connected but its internet dropped and came back (e.g. the
                // router's line): connections from the outage are stuck, so start fresh.
                if (validated && !upstreamValidated) resetUpstream("internet back")
                upstreamValidated = validated
            }
        }
        try {
            cm.registerNetworkCallback(request, callback)
            networkCallback = callback
        } catch (e: RuntimeException) {
            Log.w(TAG, "registerNetworkCallback failed", e)
        }
    }

    private fun unregisterWifiCallback() {
        val callback = networkCallback ?: return
        networkCallback = null
        try {
            getSystemService(ConnectivityManager::class.java)?.unregisterNetworkCallback(callback)
        } catch (e: IllegalArgumentException) {
            // Already unregistered.
        }
    }

    @SuppressLint("WakelockTimeout")
    @Suppress("DEPRECATION")
    private fun acquireLocks() {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        wifiLock = wifiManager.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "ShareLink:wifi").apply {
            setReferenceCounted(false)
            acquire()
        }
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ShareLink:cpu").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseLocks() {
        wifiLock?.takeIf { it.isHeld }?.release()
        wifiLock = null
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.notif_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        )
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    @SuppressLint("MissingPermission")
    private fun updateNotification() {
        try {
            getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, buildNotification(ShareState.current))
        } catch (e: SecurityException) {
            Log.w(TAG, "Cannot update notification", e)
        }
    }

    private fun buildNotification(state: ShareSnapshot): Notification {
        val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            flags,
        )
        val stop = PendingIntent.getService(
            this,
            1,
            Intent(this, ShareService::class.java).setAction(ACTION_STOP),
            flags,
        )
        val text = when {
            state.recovering -> getString(R.string.notif_recovering)
            state.status == ShareStatus.RUNNING ->
                getString(R.string.notif_running_text, state.ssid, state.passphrase, state.ownerIp, state.port ?: 0)
            else -> getString(R.string.notif_starting)
        }
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
        // Session timer; the system ticks it, so the notification isn't redrawn.
        state.startedAt?.let { builder.setWhen(it).setShowWhen(true).setUsesChronometer(true) }
        return builder
            .setSmallIcon(R.drawable.ic_stat_share)
            // Fills the icon's circle in the notification shade (Android 12+).
            .setColor(ContextCompat.getColor(this, R.color.brand_teal))
            .setContentTitle(getString(R.string.notif_title))
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(openApp)
            .addAction(0, getString(R.string.notif_stop), stop)
            .build()
    }

    /** Replaces the (detached) running notification with "Sharing stopped" [Start]; swipeable. */
    @SuppressLint("MissingPermission")
    private fun postStoppedNotification() {
        val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            flags,
        )
        val startIntent = Intent(this, ShareService::class.java).setAction(ACTION_START)
        val start = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(this, 3, startIntent, flags)
        } else {
            PendingIntent.getService(this, 3, startIntent, flags)
        }
        val failed = ShareState.current.status == ShareStatus.ERROR
        val text = getString(if (failed) R.string.notif_failed_text else R.string.notif_stopped_text)
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_share)
            // Fills the icon's circle in the notification shade (Android 12+).
            .setColor(ContextCompat.getColor(this, R.color.brand_teal))
            .setContentTitle(getString(R.string.notif_stopped_title))
            .setContentText(text)
            .setOngoing(false)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openApp)
            .addAction(0, getString(R.string.notif_start), start)
            .build()
        try {
            getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Cannot post stopped notification", e)
        }
    }

    companion object {
        private const val ACTION_START = "com.example.share_link.action.START"
        private const val ACTION_STOP = "com.example.share_link.action.STOP"
        private const val CHANNEL_ID = "share_link_service"
        private const val NOTIFICATION_ID = 1
        private const val BIND_ATTEMPTS = 6
        private const val BIND_RETRY_MS = 500L
        private const val STATS_INTERVAL_MS = 1000L
        private const val NAME_LOOKUP_DELAY_MS = 2000L
        private const val GROUP_CHECK_MS = 5000L
        private const val GROUP_RECHECK_MS = 1000L
        private const val GROUP_MISSES_BEFORE_LOST = 2
        /** About 2 minutes with the reconnect back-off (2, 4, 8, 16, then 30 s). */
        private const val MAX_RECOVERY_ATTEMPTS = 8

        /** The running proxy, so the app's devices list can block and allow devices. */
        @Volatile
        private var runningProxy: ProxyServer? = null

        /** Blocks or allows a device; false if sharing isn't running or [address] isn't an IP. */
        fun setDeviceBlocked(address: String, blocked: Boolean): Boolean {
            val server = runningProxy ?: return false
            // Only numeric addresses, so this never does a DNS lookup.
            if (!address.matches(Regex("[0-9a-fA-F:.]+"))) return false
            val ip = try {
                InetAddress.getByName(address)
            } catch (e: IOException) {
                return false
            }
            if (blocked) server.devices.block(ip) else server.devices.unblock(ip)
            // Show it right away instead of on the next stats tick.
            ShareState.update { state ->
                state.copy(devices = state.devices.map { if (it.address == address) it.copy(blocked = blocked) else it })
            }
            return true
        }

        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, ShareService::class.java).setAction(ACTION_START),
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ShareService::class.java))
        }
    }
}
