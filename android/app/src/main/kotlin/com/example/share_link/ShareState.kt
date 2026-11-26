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
    /** The Wi-Fi itself uses 192.168.49.x, the addresses Wi-Fi Direct always takes. */
    const val WIFI_SUBNET_CONFLICT = "wifi_subnet_conflict"

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
    /** Bytes per second over the last stats tick. */
    val speedUp: Long = 0,
    val speedDown: Long = 0,
    /** When this session started (epoch ms); null until running. */
    val startedAt: Long? = null,
    /** False while Phone A's Wi-Fi is down; the proxy keeps running and recovers when it returns. */
    val upstreamAvailable: Boolean = true,
    /** Phone A's Wi-Fi passed Android's internet check (false: ISP down or a login page). */
    val upstreamInternet: Boolean = true,
    /** The WhatsApp proxy ports (WhatsAppRelay) are open. */
    val whatsAppProxy: Boolean = false,
    /** Android dropped the Wi-Fi Direct group and it's being recreated (still RUNNING). */
    val recovering: Boolean = false,
    /** The group's actual band ("2.4", "5" or "6"); null when Android doesn't report it. */
    val band: String? = null,
    /** A specific band was chosen in Settings but the group isn't on it. */
    val bandNotHonored: Boolean = false,
    /** The group and the shared Wi-Fi are on different channels, which slows this phone's internet. */
    val channelMismatch: Boolean = false,
    /** Every device that used the proxy this session (see [DeviceRegistry]). */
    val devices: List<DeviceSnapshot> = emptyList(),
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
        "speedUp" to speedUp,
        "speedDown" to speedDown,
        "startedAt" to startedAt,
        "upstreamAvailable" to upstreamAvailable,
        "upstreamInternet" to upstreamInternet,
        "whatsAppProxy" to whatsAppProxy,
        "recovering" to recovering,
        "band" to band,
        "bandNotHonored" to bandNotHonored,
        "channelMismatch" to channelMismatch,
        "devices" to devices.map { it.toMap() },
    )
}

/** Sharing state (Phone A), written by [ShareService]. */
object ShareState : ObservableState<ShareSnapshot>(ShareSnapshot())
