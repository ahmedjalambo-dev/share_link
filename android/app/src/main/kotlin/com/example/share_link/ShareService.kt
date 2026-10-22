package com.example.share_link

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
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

    private val statsTicker = object : Runnable {
        override fun run() {
            val server = proxy ?: return
            ShareState.update {
                it.copy(
                    activeConnections = server.activeConnections.get(),
                    bytesUp = server.bytesUp.get(),
                    bytesDown = server.bytesDown.get(),
                    upstreamAvailable = upstreamNetwork != null,
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
        proxy?.stop()
        proxy = null
        unregisterWifiCallback()
        wifiDirect.onChannelLost = null
        wifiDirect.removeGroup()
        releaseLocks()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        // Keep an error visible to the UI; otherwise go back to "stopped".
        ShareState.update { if (it.status == ShareStatus.ERROR) it else ShareSnapshot() }
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

        acquireLocks()
        registerWifiCallback()
        ShareState.update { starting }

        wifiDirect.onChannelLost = { fail(ErrorCodes.P2P_ERROR, "Wi-Fi Direct framework disconnected") }
        wifiDirect.createGroup(settings.fullSsid, settings.passphrase) { result ->
            result.onSuccess { group -> startProxy(group) }
                .onFailure { e ->
                    fail((e as? WifiDirectController.GroupException)?.code ?: ErrorCodes.P2P_ERROR, e.message)
                }
        }
    }

    /** Binds the proxy off the main thread; the group's IP can take a moment to appear on the interface. */
    private fun startProxy(group: WifiDirectController.GroupDetails) {
        val port = settings.port
        Thread({
            val server = ProxyServer(port, { upstreamNetwork }, ::upstreamDnsServer)
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
            mainHandler.post { onProxyStarted(group, port, server, error) }
        }, "proxy-start").start()
    }

    private fun onProxyStarted(
        group: WifiDirectController.GroupDetails,
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
        ShareState.update {
            it.copy(
                status = ShareStatus.RUNNING,
                ssid = group.ssid,
                passphrase = group.passphrase,
                ownerIp = group.ownerIp,
                port = port,
                upstreamAvailable = upstreamNetwork != null,
            )
        }
        updateNotification()
        mainHandler.post(statsTicker)
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
                upstreamNetwork = network
            }

            override fun onLost(network: Network) {
                Log.w(TAG, "Wi-Fi lost: $network")
                if (upstreamNetwork == network) upstreamNetwork = null
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
        val text = if (state.status == ShareStatus.RUNNING) {
            getString(R.string.notif_running_text, state.ssid, state.passphrase, state.ownerIp, state.port ?: 0)
        } else {
            getString(R.string.notif_starting)
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_share)
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

    companion object {
        private const val ACTION_START = "com.example.share_link.action.START"
        private const val ACTION_STOP = "com.example.share_link.action.STOP"
        private const val CHANNEL_ID = "share_link_service"
        private const val NOTIFICATION_ID = 1
        private const val BIND_ATTEMPTS = 6
        private const val BIND_RETRY_MS = 500L
        private const val STATS_INTERVAL_MS = 1000L

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
