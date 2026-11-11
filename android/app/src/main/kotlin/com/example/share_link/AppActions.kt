package com.example.share_link

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.VpnService
import android.net.wifi.WifiManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat

/**
 * Start/stop actions with their pre-checks, shared by the app ([MainActivity]) and the Quick
 * Settings tile ([ShareTileService]). Failures are reported through [ShareState] / [ClientState],
 * so the app shows the same error card whichever started it.
 */
object AppActions {

    // region Sharing (Phone A)

    /** Runs the pre-start checks and starts sharing. False if a check failed (state shows why). */
    fun startSharing(context: Context): Boolean {
        val status = ShareState.current.status
        if (status == ShareStatus.STARTING || status == ShareStatus.RUNNING) return true

        val error = sharePreflightError(context)
        if (error != null) {
            ShareState.update { ShareSnapshot(status = ShareStatus.ERROR, errorCode = error) }
            return false
        }
        // The Quick Settings tile follows the last thing started.
        ShareSettings(context).mode = ShareSettings.MODE_SHARE
        ShareService.start(context)
        return true
    }

    fun stopSharing(context: Context) {
        ShareService.stop(context)
        // Clears an error left by a failed start (the service may not be running at all).
        ShareState.update { if (it.status == ShareStatus.ERROR) ShareSnapshot() else it }
    }

    /** Also run by [ShareService] itself when started from the notification's Start button. */
    internal fun sharePreflightError(context: Context): String? {
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT)) {
            return ErrorCodes.P2P_UNSUPPORTED
        }
        if (!hasRequiredPermissions(context)) return ErrorCodes.PERMISSION_DENIED
        if (!wifiManager(context).isWifiEnabled) return ErrorCodes.WIFI_DISABLED
        if (NetworkUtils.findWifiNetwork(context) == null) return ErrorCodes.WIFI_NOT_CONNECTED
        if (locationRequiredButOff(context)) return ErrorCodes.LOCATION_DISABLED
        return null
    }

    // endregion

    // region Client mode (Phone B)

    /** Connects with the saved client settings. False if a check failed (state shows why). */
    fun connectClient(context: Context): Boolean {
        val status = ClientState.current.status
        if (status == ClientStatus.CONNECTING || status == ClientStatus.CONNECTED ||
            status == ClientStatus.RECONNECTING
        ) {
            return true
        }
        val error = clientPreflightError(context)
        if (error != null) {
            ClientState.update { ClientSnapshot(status = ClientStatus.ERROR, errorCode = error) }
            return false
        }
        val settings = ShareSettings(context)
        // The Quick Settings tile follows the last thing started.
        settings.mode = ShareSettings.MODE_CONNECT
        ClientVpnService.connect(context, settings.clientPort)
        return true
    }

    /**
     * Checks before connecting with the saved settings. Also run by [ClientVpnService] itself when
     * started from the notification's Connect button.
     */
    internal fun clientPreflightError(context: Context): String? {
        val settings = ShareSettings(context)
        return when {
            VpnService.prepare(context) != null -> ClientErrorCodes.VPN_DENIED
            settings.clientAutoJoin -> joinPreflightError(context, settings)
            else -> null
        }
    }

    fun disconnectClient(context: Context) {
        ClientVpnService.disconnect(context)
        ClientState.update { if (it.status == ClientStatus.ERROR) ClientSnapshot() else it }
    }

    /** Checks needed only when the app will join Phone A's network itself. */
    private fun joinPreflightError(context: Context, settings: ShareSettings): String? {
        val cm = context.getSystemService(ConnectivityManager::class.java)
        if (cm != null && NetworkUtils.findDirectNetwork(cm) != null) return null // already joined
        // Nothing to join with yet (e.g. the tile was tapped before Phone A's details were entered).
        val needsName = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q && settings.clientSsid.isEmpty()
        if (settings.clientPassphrase.isEmpty() || needsName) return ClientErrorCodes.SETUP_NEEDED
        if (!hasRequiredPermissions(context)) return ErrorCodes.PERMISSION_DENIED
        // From Android 10 apps can't turn Wi-Fi on; below that the joiner does it.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !wifiManager(context).isWifiEnabled) {
            return ErrorCodes.WIFI_DISABLED
        }
        if (locationRequiredButOff(context)) return ErrorCodes.LOCATION_DISABLED
        return null
    }

    // endregion

    // region Shared checks

    /** Permissions without which Wi-Fi Direct (sharing or joining) can't work. */
    fun requiredPermissions(): List<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.NEARBY_WIFI_DEVICES)
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    fun isGranted(context: Context, permission: String) =
        ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED

    fun hasRequiredPermissions(context: Context) = requiredPermissions().all { isGranted(context, it) }

    private fun wifiManager(context: Context) =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

    /** Android 12 and below only allow Wi-Fi Direct and Wi-Fi network requests while Location is on. */
    private fun locationRequiredButOff(context: Context): Boolean {
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) return false
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return !LocationManagerCompat.isLocationEnabled(locationManager)
    }

    // endregion
}
