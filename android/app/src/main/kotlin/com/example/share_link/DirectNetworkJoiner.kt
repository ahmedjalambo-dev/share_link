package com.example.share_link

import android.annotation.SuppressLint
import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.PatternMatcher
import android.util.Log
import androidx.annotation.RequiresApi
import java.net.InetAddress
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Joins Phone A's Wi-Fi Direct network from the app (client mode on Phone B).
 *
 * - Android 10+: a [WifiNetworkSpecifier] request. Android shows its own "connect to this
 *   device?" dialog (a picker of DIRECT- networks when no name is given) and the result is an
 *   app-only network with no internet, which is all the tunnel needs. It's never saved.
 * - Android 7–9: a temporary saved network (needs the exact name), removed again on [release].
 *
 * One instance per connection. [join] blocks, so call it off the main thread; [release] may be
 * called from any thread, including while [join] is waiting (it cancels the join).
 */
@SuppressLint("MissingPermission")
internal class DirectNetworkJoiner(context: Context) {

    private val appContext = context.applicationContext
    private val cm = appContext.getSystemService(ConnectivityManager::class.java)
    private val joinedLatch = CountDownLatch(1)

    @Volatile
    private var joined: Network? = null

    @Volatile
    private var released = false

    @Volatile
    private var callback: ConnectivityManager.NetworkCallback? = null

    @Volatile
    private var legacyNetId = NO_NETWORK_ID

    /** True when Android reports the network's loss through `onLost` passed to [join]. */
    val reportsLoss: Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    /**
     * Joins the network and returns it with Phone A's address. [ssid] may be empty on Android
     * 10+ (the user then picks a DIRECT- network). Throws [ClientException] (JOIN_FAILED).
     */
    fun join(ssid: String, passphrase: String, onLost: () -> Unit): Pair<Network, InetAddress> {
        val network = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            joinWithSpecifier(ssid, passphrase, onLost)
        } else {
            joinLegacy(ssid, passphrase)
        }
        val link = waitForAddress(network)
            ?: fail("Joined ${ssid.ifEmpty { "DIRECT-" }} but got no address")
        Log.i(TAG, "Joined Phone A's network: $network")
        return network to NetworkUtils.phoneAAddress(link)
    }

    @Synchronized
    fun release() {
        if (released) return
        released = true
        callback?.let {
            try {
                cm.unregisterNetworkCallback(it)
            } catch (e: IllegalArgumentException) {
                // Already unregistered.
            }
        }
        callback = null
        if (legacyNetId != NO_NETWORK_ID) {
            @Suppress("DEPRECATION")
            wifiManager().removeNetwork(legacyNetId)
            legacyNetId = NO_NETWORK_ID
        }
        joinedLatch.countDown()
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun joinWithSpecifier(ssid: String, passphrase: String, onLost: () -> Unit): Network {
        val specifier = WifiNetworkSpecifier.Builder().apply {
            if (ssid.isEmpty()) {
                setSsidPattern(PatternMatcher(DIRECT_SSID_PREFIX, PatternMatcher.PATTERN_PREFIX))
            } else {
                setSsid(ssid)
            }
            setWpa2Passphrase(passphrase)
        }.build()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(specifier)
            .build()
        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                if (joined == null) {
                    joined = network
                    joinedLatch.countDown()
                }
            }

            // Timeout, wrong password, or the user dismissed Android's dialog.
            override fun onUnavailable() = joinedLatch.countDown()

            override fun onLost(network: Network) {
                if (!released && network == joined) onLost()
            }
        }
        synchronized(this) {
            if (released) fail("Cancelled")
            callback = networkCallback
            cm.requestNetwork(request, networkCallback, JOIN_TIMEOUT_MS)
        }
        joinedLatch.await(JOIN_TIMEOUT_MS + LATCH_GRACE_MS, TimeUnit.MILLISECONDS)
        if (released) fail("Cancelled")
        return joined ?: fail("Couldn't join ${ssid.ifEmpty { "a DIRECT- network" }}")
    }

    @Suppress("DEPRECATION")
    private fun joinLegacy(ssid: String, passphrase: String): Network {
        val wifi = wifiManager()
        if (!wifi.isWifiEnabled) wifi.isWifiEnabled = true
        val config = WifiConfiguration().apply {
            SSID = "\"$ssid\""
            preSharedKey = "\"$passphrase\""
        }
        val netId = wifi.addNetwork(config)
        if (netId == NO_NETWORK_ID) fail("Android refused to add $ssid")
        synchronized(this) {
            legacyNetId = netId
            if (released) fail("Cancelled")
        }
        wifi.enableNetwork(netId, true)
        val deadline = System.currentTimeMillis() + LEGACY_JOIN_TIMEOUT_MS
        while (System.currentTimeMillis() < deadline) {
            if (released) fail("Cancelled")
            NetworkUtils.findDirectNetwork(cm)?.let { return it.first }
            Thread.sleep(POLL_MS)
        }
        fail("Couldn't join $ssid")
    }

    /** The network can be reported before DHCP finishes; wait briefly for a DIRECT address. */
    private fun waitForAddress(network: Network): LinkProperties? {
        val deadline = System.currentTimeMillis() + ADDRESS_TIMEOUT_MS
        while (!released) {
            val link = cm.getLinkProperties(network)
            if (link != null && NetworkUtils.isOnDirectSubnet(link)) return link
            if (System.currentTimeMillis() >= deadline) return null
            Thread.sleep(POLL_MS)
        }
        return null
    }

    private fun wifiManager() = appContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

    /** Undoes any partial join, then throws. */
    private fun fail(message: String): Nothing {
        release()
        throw ClientException(ClientErrorCodes.JOIN_FAILED, message)
    }

    private companion object {
        const val DIRECT_SSID_PREFIX = "DIRECT-"
        const val NO_NETWORK_ID = -1
        const val JOIN_TIMEOUT_MS = 60_000
        const val LATCH_GRACE_MS = 5_000L
        const val LEGACY_JOIN_TIMEOUT_MS = 20_000L
        const val ADDRESS_TIMEOUT_MS = 10_000L
        const val POLL_MS = 500L
    }
}
