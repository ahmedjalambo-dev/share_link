package com.example.share_link

import android.annotation.SuppressLint
import android.content.Context
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.net.Inet4Address
import java.net.NetworkInterface

/**
 * Creates and removes the Wi-Fi Direct group that makes this phone the group owner.
 * All callbacks run on the main thread. Permissions are checked by [MainActivity] before starting.
 */
@SuppressLint("MissingPermission")
class WifiDirectController(context: Context) {

    data class GroupDetails(val ssid: String, val passphrase: String, val ownerIp: String)

    class GroupException(val code: String, message: String) : Exception(message)

    private val appContext = context.applicationContext
    private val manager = appContext.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private val handler = Handler(Looper.getMainLooper())
    private var channel: WifiP2pManager.Channel? = null
    private var cancelled = false

    /** Called if the Wi-Fi Direct framework disconnects while a group is active. */
    var onChannelLost: (() -> Unit)? = null

    fun createGroup(networkName: String, passphrase: String, onResult: (Result<GroupDetails>) -> Unit) {
        val mgr = manager
        if (mgr == null) {
            onResult(Result.failure(GroupException(ErrorCodes.P2P_UNSUPPORTED, "WifiP2pManager unavailable")))
            return
        }
        cancelled = false
        val ch = mgr.initialize(appContext, Looper.getMainLooper()) {
            Log.w(TAG, "Wi-Fi Direct channel disconnected")
            channel = null
            if (!cancelled) onChannelLost?.invoke()
        }
        if (ch == null) {
            onResult(Result.failure(GroupException(ErrorCodes.P2P_UNSUPPORTED, "Wi-Fi Direct channel unavailable")))
            return
        }
        channel = ch

        // Remove any leftover group first (e.g. from a crash); failure just means there was none.
        mgr.removeGroup(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                handler.postDelayed({ attemptCreate(mgr, ch, networkName, passphrase, 1, onResult) }, 500)
            }

            override fun onFailure(reason: Int) {
                attemptCreate(mgr, ch, networkName, passphrase, 1, onResult)
            }
        })
    }

    fun removeGroup() {
        cancelled = true
        handler.removeCallbacksAndMessages(null)
        val mgr = manager ?: return
        val ch = channel ?: return
        channel = null
        mgr.removeGroup(ch, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.i(TAG, "Group removed")
                closeChannel(ch)
            }

            override fun onFailure(reason: Int) {
                Log.w(TAG, "removeGroup failed: reason=$reason")
                closeChannel(ch)
            }
        })
    }

    private fun attemptCreate(
        mgr: WifiP2pManager,
        ch: WifiP2pManager.Channel,
        networkName: String,
        passphrase: String,
        attempt: Int,
        onResult: (Result<GroupDetails>) -> Unit,
    ) {
        if (cancelled) return
        val listener = object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.i(TAG, "createGroup succeeded")
                if (cancelled) {
                    mgr.removeGroup(ch, null)
                    return
                }
                fetchGroupInfo(mgr, ch, 1, onResult)
            }

            override fun onFailure(reason: Int) {
                Log.w(TAG, "createGroup failed: reason=$reason attempt=$attempt")
                if (reason == WifiP2pManager.BUSY && attempt < MAX_CREATE_ATTEMPTS) {
                    handler.postDelayed(
                        { attemptCreate(mgr, ch, networkName, passphrase, attempt + 1, onResult) },
                        RETRY_DELAY_MS,
                    )
                    return
                }
                onResult(Result.failure(GroupException(codeForReason(reason), "createGroup failed (reason $reason)")))
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val config = try {
                WifiP2pConfig.Builder()
                    .setNetworkName(networkName)
                    .setPassphrase(passphrase)
                    .enablePersistentMode(false)
                    .setGroupOperatingBand(WifiP2pConfig.GROUP_OWNER_BAND_AUTO)
                    .build()
            } catch (e: IllegalArgumentException) {
                onResult(Result.failure(GroupException(ErrorCodes.INVALID_SETTINGS, e.message ?: "Invalid config")))
                return
            }
            mgr.createGroup(ch, config, listener)
        } else {
            mgr.createGroup(ch, listener)
        }
    }

    /** Group info can be null for a short while after createGroup succeeds, so poll a few times. */
    private fun fetchGroupInfo(
        mgr: WifiP2pManager,
        ch: WifiP2pManager.Channel,
        attempt: Int,
        onResult: (Result<GroupDetails>) -> Unit,
    ) {
        if (cancelled) return
        mgr.requestGroupInfo(ch) { group ->
            if (cancelled) return@requestGroupInfo
            val ssid = group?.networkName
            val pass = group?.passphrase
            if (group == null || !group.isGroupOwner || ssid.isNullOrEmpty() || pass.isNullOrEmpty()) {
                if (attempt < MAX_INFO_ATTEMPTS) {
                    handler.postDelayed({ fetchGroupInfo(mgr, ch, attempt + 1, onResult) }, INFO_POLL_MS)
                } else {
                    onResult(Result.failure(GroupException(ErrorCodes.P2P_ERROR, "Group info unavailable")))
                }
                return@requestGroupInfo
            }
            mgr.requestConnectionInfo(ch) { info ->
                if (cancelled) return@requestConnectionInfo
                val ip = info?.groupOwnerAddress?.hostAddress
                    ?: interfaceIpv4(group.`interface`)
                    ?: DIRECT_OWNER_IP
                Log.i(TAG, "Group ready: ssid=$ssid ip=$ip")
                onResult(Result.success(GroupDetails(ssid, pass, ip)))
            }
        }
    }

    private fun interfaceIpv4(name: String?): String? = try {
        name?.let { NetworkInterface.getByName(it) }
            ?.inetAddresses?.toList()
            ?.firstOrNull { it is Inet4Address && !it.isLoopbackAddress }
            ?.hostAddress
    } catch (e: Exception) {
        null
    }

    private fun closeChannel(ch: WifiP2pManager.Channel) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) ch.close()
    }

    private fun codeForReason(reason: Int) = when (reason) {
        WifiP2pManager.P2P_UNSUPPORTED -> ErrorCodes.P2P_UNSUPPORTED
        WifiP2pManager.BUSY -> ErrorCodes.P2P_BUSY
        else -> ErrorCodes.P2P_ERROR
    }

    companion object {
        private const val MAX_CREATE_ATTEMPTS = 3
        private const val RETRY_DELAY_MS = 1000L
        private const val MAX_INFO_ATTEMPTS = 10
        private const val INFO_POLL_MS = 500L
    }
}
