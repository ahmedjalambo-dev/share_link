package com.example.share_link

/** Error codes sent to Flutter; the UI maps them to localized messages (lib/utils/messages.dart). */
object ErrorCodes {
    const val PERMISSION_DENIED = "permission_denied"
    const val LOCATION_DISABLED = "location_disabled"
    const val WIFI_DISABLED = "wifi_disabled"
    const val WIFI_NOT_CONNECTED = "wifi_not_connected"
    const val P2P_UNSUPPORTED = "p2p_unsupported"
    const val P2P_BUSY = "p2p_busy"
    const val P2P_ERROR = "p2p_error"
    const val INVALID_SETTINGS = "invalid_settings"
    const val SERVICE_FAILED = "service_failed"
    const val PORT_IN_USE = "port_in_use"
    const val PROXY_FAILED = "proxy_failed"

    // Settings validation (ShareSettings.save)
    const val INVALID_NAME = "invalid_name"
    const val NAME_TOO_LONG = "name_too_long"
    const val INVALID_PASSWORD = "invalid_password"
    const val INVALID_PORT = "invalid_port"
}

enum class ShareStatus(val wire: String) {
    STOPPED("stopped"),
    STARTING("starting"),
    RUNNING("running"),
    ERROR("error"),
}

data class ShareSnapshot(
    val status: ShareStatus = ShareStatus.STOPPED,
    val ssid: String? = null,
    val passphrase: String? = null,
    val ownerIp: String? = null,
    val port: Int? = null,
    val errorCode: String? = null,
    val errorDetail: String? = null,
    val activeConnections: Int = 0,
    val bytesUp: Long = 0,
    val bytesDown: Long = 0,
    /** False while Phone A's Wi-Fi is down; the proxy keeps running and recovers when it returns. */
    val upstreamAvailable: Boolean = true,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "status" to status.wire,
        "ssid" to ssid,
        "passphrase" to passphrase,
        "ownerIp" to ownerIp,
        "port" to port,
        "errorCode" to errorCode,
        "errorDetail" to errorDetail,
        "activeConnections" to activeConnections,
        "bytesUp" to bytesUp,
        "bytesDown" to bytesDown,
        "upstreamAvailable" to upstreamAvailable,
    )
}

/** Sharing state (Phone A), written by [ShareService]. */
object ShareState : ObservableState<ShareSnapshot>(ShareSnapshot())
