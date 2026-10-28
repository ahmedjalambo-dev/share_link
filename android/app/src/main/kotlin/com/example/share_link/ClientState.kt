package com.example.share_link

/** Client-mode (Phone B) error codes; the UI maps them to localized messages. */
object ClientErrorCodes {
    const val VPN_DENIED = "vpn_denied"
    const val NOT_ON_DIRECT_NETWORK = "not_on_direct_network"
    const val HOST_UNREACHABLE = "host_unreachable"
    const val VPN_FAILED = "vpn_failed"
    const val CONNECTION_LOST = "connection_lost"
    const val JOIN_FAILED = "join_failed"
}

/** A client-mode failure with the code shown to the user. */
internal class ClientException(val code: String, message: String) : Exception(message)

enum class ClientStatus(val wire: String) {
    DISCONNECTED("disconnected"),
    CONNECTING("connecting"),
    CONNECTED("connected"),
    /** Phone A dropped; the VPN stays up and the service keeps retrying until DISCONNECT. */
    RECONNECTING("reconnecting"),
    ERROR("error"),
}

data class ClientSnapshot(
    val status: ClientStatus = ClientStatus.DISCONNECTED,
    val host: String? = null,
    val port: Int? = null,
    val bytesUp: Long = 0,
    val bytesDown: Long = 0,
    val errorCode: String? = null,
    val errorDetail: String? = null,
    /** True while connecting and the app is joining Phone A's Wi-Fi itself. */
    val joining: Boolean = false,
    /** Current retry number while RECONNECTING (errorCode/errorDetail hold the last failure). */
    val reconnectAttempt: Int = 0,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "status" to status.wire,
        "host" to host,
        "port" to port,
        "bytesUp" to bytesUp,
        "bytesDown" to bytesDown,
        "errorCode" to errorCode,
        "errorDetail" to errorDetail,
        "joining" to joining,
        "reconnectAttempt" to reconnectAttempt,
    )
}

/** Client-mode state (Phone B), written by [ClientVpnService]. */
object ClientState : ObservableState<ClientSnapshot>(ClientSnapshot())
