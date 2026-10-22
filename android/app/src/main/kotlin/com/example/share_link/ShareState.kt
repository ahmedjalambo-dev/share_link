package com.example.share_link

import java.util.concurrent.CopyOnWriteArraySet

/** Error codes sent to Flutter; the UI maps them to localized messages. */
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

/** Process-wide sharing state, written by [ShareService] and observed by [MainActivity]. */
object ShareState {
    @Volatile
    var current = ShareSnapshot()
        private set

    private val listeners = CopyOnWriteArraySet<(ShareSnapshot) -> Unit>()

    @Synchronized
    fun update(transform: (ShareSnapshot) -> ShareSnapshot) {
        val next = transform(current)
        if (next == current) return
        current = next
        listeners.forEach { it(next) }
    }

    fun addListener(listener: (ShareSnapshot) -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: (ShareSnapshot) -> Unit) {
        listeners.remove(listener)
    }
}
