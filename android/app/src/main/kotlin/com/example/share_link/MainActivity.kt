package com.example.share_link

import android.Manifest
import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.Uri
import android.net.VpnService
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var settings: ShareSettings
    private val channelDetachers = mutableListOf<() -> Unit>()
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingVpnResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        settings = ShareSettings(this)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, CONTROL_CHANNEL).setMethodCallHandler(::onMethodCall)
        stateChannel(messenger, STATUS_CHANNEL, ShareState, ShareSnapshot::toMap)
        stateChannel(messenger, CLIENT_STATUS_CHANNEL, ClientState, ClientSnapshot::toMap)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channelDetachers.forEach { it() }
        channelDetachers.clear()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** Streams a state object to Flutter: the current value on listen, then every change. */
    private fun <T> stateChannel(
        messenger: BinaryMessenger,
        name: String,
        state: ObservableState<T>,
        toMap: (T) -> Map<String, Any?>,
    ) {
        var active: ((T) -> Unit)? = null
        val detach = {
            active?.let(state::removeListener)
            active = null
        }
        channelDetachers += detach
        EventChannel(messenger, name).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                detach()
                lateinit var listener: (T) -> Unit
                listener = { value ->
                    mainHandler.post { if (active === listener) events.success(toMap(value)) }
                }
                active = listener
                state.addListener(listener)
                events.success(toMap(state.current))
            }

            override fun onCancel(arguments: Any?) = detach()
        })
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> result.success(ShareState.current.toMap())
            "start" -> result.success(startSharing())
            "stop" -> {
                stopSharing()
                result.success(null)
            }
            "getSettings" -> result.success(settings.toMap())
            "saveSettings" -> {
                val error = settings.save(
                    call.argument<String>("networkName") ?: "",
                    call.argument<String>("passphrase") ?: "",
                    call.argument<Int>("port") ?: -1,
                )
                if (error == null) result.success(settings.toMap()) else result.error(error, null, null)
            }
            "setLanguage" -> {
                val language = call.argument<String>("language") ?: ""
                if (language in ShareSettings.LANGUAGES) {
                    settings.language = language
                    result.success(null)
                } else {
                    result.error("invalid_language", null, null)
                }
            }
            "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
            "requestIgnoreBatteryOptimizations" -> {
                requestIgnoreBatteryOptimizations()
                result.success(null)
            }
            "setMode" -> {
                val mode = call.argument<String>("mode") ?: ""
                if (mode in ShareSettings.MODES) {
                    settings.mode = mode
                    result.success(null)
                } else {
                    result.error("invalid_mode", null, null)
                }
            }
            "getClientStatus" -> result.success(ClientState.current.toMap())
            "prepareVpn" -> prepareVpn(result)
            "connectClient" -> connectClient(call.argument<Int>("port") ?: settings.clientPort, result)
            "disconnectClient" -> {
                ClientVpnService.disconnect(this)
                ClientState.update { if (it.status == ClientStatus.ERROR) ClientSnapshot() else it }
                result.success(null)
            }
            "checkPermissions" -> result.success(permissionMap(afterRequest = false))
            "requestPermissions" -> requestSharePermissions(result)
            "openSystemSettings" -> {
                openSystemSettings(call.argument<String>("target"))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // region Start / stop

    /** Runs the pre-start checks and starts the service. Failures are reported through [ShareState]. */
    private fun startSharing(): Boolean {
        val status = ShareState.current.status
        if (status == ShareStatus.STARTING || status == ShareStatus.RUNNING) return true

        val error = preflightError()
        if (error != null) {
            ShareState.update { ShareSnapshot(status = ShareStatus.ERROR, errorCode = error) }
            return false
        }
        ShareService.start(this)
        return true
    }

    private fun stopSharing() {
        ShareService.stop(this)
        // Clears an error left by a failed start (the service may not be running at all).
        ShareState.update { if (it.status == ShareStatus.ERROR) ShareSnapshot() else it }
    }

    private fun preflightError(): String? {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT)) return ErrorCodes.P2P_UNSUPPORTED
        if (!hasRequiredPermissions()) return ErrorCodes.PERMISSION_DENIED

        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (!wifiManager.isWifiEnabled) return ErrorCodes.WIFI_DISABLED
        if (NetworkUtils.findWifiNetwork(this) == null) return ErrorCodes.WIFI_NOT_CONNECTED

        // Android 12 and below only allow Wi-Fi Direct while Location is on.
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.S_V2) {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            if (!LocationManagerCompat.isLocationEnabled(locationManager)) return ErrorCodes.LOCATION_DISABLED
        }
        return null
    }

    // endregion

    // region Client mode (Phone B)

    /** Shows the system "Connection request" dialog if needed; resolves to true when the VPN is allowed. */
    private fun prepareVpn(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent == null) {
            result.success(true)
            return
        }
        if (pendingVpnResult != null) {
            result.error("busy", "A VPN request is already in progress", null)
            return
        }
        pendingVpnResult = result
        try {
            startActivityForResult(intent, REQUEST_VPN)
        } catch (e: ActivityNotFoundException) {
            pendingVpnResult = null
            result.success(false)
        }
    }

    private fun connectClient(port: Int, result: MethodChannel.Result) {
        if (port !in 1024..65535) {
            result.error(ErrorCodes.INVALID_PORT, null, null)
            return
        }
        if (VpnService.prepare(this) != null) {
            ClientState.update { ClientSnapshot(status = ClientStatus.ERROR, errorCode = ClientErrorCodes.VPN_DENIED) }
            result.success(false)
            return
        }
        settings.clientPort = port
        ClientVpnService.connect(this, port)
        result.success(true)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_VPN) return
        pendingVpnResult?.success(resultCode == RESULT_OK)
        pendingVpnResult = null
    }

    // endregion

    // region Permissions

    /** Permissions without which the Wi-Fi Direct group can't be created. */
    private fun requiredPermissions(): List<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.NEARBY_WIFI_DEVICES)
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    /** Everything to ask for: required ones plus notifications, and COARSE alongside FINE (needed on Android 12). */
    private fun requestablePermissions(): List<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.NEARBY_WIFI_DEVICES, Manifest.permission.POST_NOTIFICATIONS)
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
        }

    private fun isGranted(permission: String) =
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED

    private fun hasRequiredPermissions() = requiredPermissions().all(::isGranted)

    private fun notificationsGranted() =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || isGranted(Manifest.permission.POST_NOTIFICATIONS)

    private fun permissionMap(afterRequest: Boolean): Map<String, Boolean> {
        val granted = hasRequiredPermissions()
        // After a denial, "no rationale" means the user chose "Don't ask again".
        val permanentlyDenied = afterRequest && !granted && requiredPermissions().any {
            !isGranted(it) && !ActivityCompat.shouldShowRequestPermissionRationale(this, it)
        }
        return mapOf(
            "granted" to granted,
            "notificationsGranted" to notificationsGranted(),
            "permanentlyDenied" to permanentlyDenied,
        )
    }

    private fun requestSharePermissions(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error("busy", "A permission request is already in progress", null)
            return
        }
        val missing = requestablePermissions().filterNot(::isGranted)
        if (missing.isEmpty()) {
            result.success(permissionMap(afterRequest = false))
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(this, missing.toTypedArray(), REQUEST_PERMISSIONS)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_PERMISSIONS) return
        pendingPermissionResult?.success(permissionMap(afterRequest = true))
        pendingPermissionResult = null
    }

    // endregion

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    /** Shows the system "Allow app to run in background?" dialog, or the list screen as a fallback. */
    @SuppressLint("BatteryLife")
    private fun requestIgnoreBatteryOptimizations() {
        if (isIgnoringBatteryOptimizations()) return
        try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")),
            )
        } catch (e: Exception) {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    private fun openSystemSettings(target: String?) {
        val intent = when (target) {
            "location" -> Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
            "wifi" -> Intent(Settings.ACTION_WIFI_SETTINGS)
            else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }

    companion object {
        private const val CONTROL_CHANNEL = "share_link/control"
        private const val STATUS_CHANNEL = "share_link/status"
        private const val CLIENT_STATUS_CHANNEL = "share_link/client_status"
        private const val REQUEST_PERMISSIONS = 4201
        private const val REQUEST_VPN = 4202
    }
}
