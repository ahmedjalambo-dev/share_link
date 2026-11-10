package com.example.share_link

/** What the Quick Settings tile shows, derived from the app mode and the running state. */
enum class TileStatus(val isActive: Boolean) {
    OFF(false),
    STARTING(true),
    SHARING(true),
    CONNECTING(true),
    CONNECTED(true),
    RECONNECTING(true),

    /** The last start failed; tapping opens the app, which shows the problem. */
    ERROR(false),
}

/** Pure mapping, so it can be unit-tested: [mode] is "share" or "connect" (ShareSettings.mode). */
fun tileStatus(mode: String, share: ShareStatus, client: ClientStatus): TileStatus =
    if (mode == ShareSettings.MODE_CONNECT) {
        when (client) {
            ClientStatus.DISCONNECTED -> TileStatus.OFF
            ClientStatus.CONNECTING -> TileStatus.CONNECTING
            ClientStatus.CONNECTED -> TileStatus.CONNECTED
            ClientStatus.RECONNECTING -> TileStatus.RECONNECTING
            ClientStatus.ERROR -> TileStatus.ERROR
        }
    } else {
        when (share) {
            ShareStatus.STOPPED -> TileStatus.OFF
            ShareStatus.STARTING -> TileStatus.STARTING
            ShareStatus.RUNNING -> TileStatus.SHARING
            ShareStatus.ERROR -> TileStatus.ERROR
        }
    }
