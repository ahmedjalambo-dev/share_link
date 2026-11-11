package com.example.share_link

import android.Manifest
import android.annotation.SuppressLint
import android.app.StatusBarManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.graphics.drawable.Icon
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
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
            "start" -> result.success(AppActions.startSharing(this))
            "stop" -> {
                AppActions.stopSharing(this)
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
            "getClientStatus" -> result.success(ClientState.current.toMap())
            "prepareVpn" -> prepareVpn(result)
            "connectClient" -> connectClient(call, result)
            "disconnectClient" -> {
                AppActions.disconnectClient(this)
                result.success(null)
            }
            "requestAddTile" -> requestAddTile(result)
            "checkPermissions" -> result.success(permissionMap(afterRequest = false))
            "requestPermissions" -> requestSharePermissions(result)
            "openSystemSettings" -> {
                openSystemSettings(call.argument<String>("target"))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

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

    /** Saves Phone B's connection details, runs the pre-checks and starts the VPN service. */
    private fun connectClient(call: MethodCall, result: MethodChannel.Result) {
        val port = call.argument<Int>("port") ?: settings.clientPort
        val autoJoin = call.argument<Boolean>("autoJoin") ?: settings.clientAutoJoin
        val invalid = settings.saveClient(
            port,
            call.argument<String>("ssid") ?: settings.clientSsid,
            call.argument<String>("passphrase") ?: settings.clientPassphrase,
            autoJoin,
        )
        if (invalid != null) {
            result.error(invalid, null, null)
            return
        }
        result.success(AppActions.connectClient(this))
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_VPN) return
        pendingVpnResult?.success(resultCode == RESULT_OK)
        pendingVpnResult = null
    }

    // endregion

    // region Permissions

    /** Everything to ask for: required ones plus notifications, and COARSE alongside FINE (needed on Android 12). */
    private fun requestablePermissions(): List<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            listOf(Manifest.permission.NEARBY_WIFI_DEVICES, Manifest.permission.POST_NOTIFICATIONS)
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
        }

    private fun isGranted(permission: String) = AppActions.isGranted(this, permission)

    private fun hasRequiredPermissions() = AppActions.hasRequiredPermissions(this)

    private fun notificationsGranted() =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || isGranted(Manifest.permission.POST_NOTIFICATIONS)

    private fun permissionMap(afterRequest: Boolean): Map<String, Boolean> {
        val granted = hasRequiredPermissions()
        // After a denial, "no rationale" means the user chose "Don't ask again".
        val permanentlyDenied = afterRequest && !granted && AppActions.requiredPermissions().any {
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

    /** Android 13+ "Add tile to Quick Settings?" prompt; resolves to added/alreadyAdded/notAdded/error/unsupported. */
    private fun requestAddTile(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success("unsupported")
            return
        }
        val statusBar = getSystemService(StatusBarManager::class.java)
        if (statusBar == null) {
            result.success("unsupported")
            return
        }
        val mode = settings.mode
        statusBar.requestAddTileService(
            ComponentName(this, ShareTileService::class.java),
            getString(ShareTileService.labelFor(mode)),
            Icon.createWithResource(this, ShareTileService.iconFor(mode)),
            mainExecutor,
        ) { code ->
            result.success(
                when (code) {
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED -> "added"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED -> "alreadyAdded"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED -> "notAdded"
                    else -> "error"
                },
            )
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
