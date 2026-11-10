package com.example.share_link

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log

/**
 * Quick Settings tile. Follows the app's mode: in Share mode it starts/stops sharing (Phone A),
 * in Connect mode it connects/disconnects (Phone B). Uses the same checks as the app
 * ([AppActions]); when something stops a start, it opens the app, which shows the problem.
 */
class ShareTileService : TileService() {

    private val mainHandler = Handler(Looper.getMainLooper())

    // Services update the states from any thread; the tile is only touched on the main thread.
    private val shareListener: (ShareSnapshot) -> Unit = { mainHandler.post(::refresh) }
    private val clientListener: (ClientSnapshot) -> Unit = { mainHandler.post(::refresh) }

    override fun onStartListening() {
        super.onStartListening()
        ShareState.addListener(shareListener)
        ClientState.addListener(clientListener)
        refresh()
    }

    override fun onStopListening() {
        ShareState.removeListener(shareListener)
        ClientState.removeListener(clientListener)
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        val status = currentStatus()
        when {
            // Stopping is always allowed, even on the lock screen.
            status.isActive -> stop()
            // The subtitle says "Tap to see the problem".
            status == TileStatus.ERROR -> openApp()
            // Starting shares the phone's connection, so it needs an unlocked phone.
            isLocked -> unlockAndRun { start() }
            else -> start()
        }
    }

    private fun isConnectMode() = ShareSettings(this).mode == ShareSettings.MODE_CONNECT

    private fun currentStatus() =
        tileStatus(ShareSettings(this).mode, ShareState.current.status, ClientState.current.status)

    private fun start() {
        val started = try {
            if (isConnectMode()) AppActions.connectClient(this) else AppActions.startSharing(this)
        } catch (e: IllegalStateException) {
            // Android refused to start a service from here (includes
            // ForegroundServiceStartNotAllowedException); the app can start it.
            Log.w(TAG, "Tile couldn't start the service", e)
            false
        }
        if (!started) openApp()
        refresh()
    }

    private fun stop() {
        if (isConnectMode()) AppActions.disconnectClient(this) else AppActions.stopSharing(this)
        refresh()
    }

    /** Collapses the shade and opens the app (in its saved mode, showing any error). */
    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun openApp() {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            startActivityAndCollapse(PendingIntent.getActivity(this, 0, intent, flags))
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun refresh() {
        val tile = qsTile ?: return
        val mode = ShareSettings(this).mode
        val status = tileStatus(mode, ShareState.current.status, ClientState.current.status)
        tile.state = if (status.isActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = getString(labelFor(mode))
        tile.icon = Icon.createWithResource(this, iconFor(mode))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) tile.subtitle = getString(subtitleFor(status))
        tile.updateTile()
    }

    companion object {
        fun labelFor(mode: String) =
            if (mode == ShareSettings.MODE_CONNECT) R.string.tile_connect else R.string.tile_share

        fun iconFor(mode: String) =
            if (mode == ShareSettings.MODE_CONNECT) R.drawable.ic_tile_connect else R.drawable.ic_stat_share

        private fun subtitleFor(status: TileStatus) = when (status) {
            TileStatus.OFF -> R.string.tile_off
            TileStatus.STARTING -> R.string.tile_starting
            TileStatus.SHARING -> R.string.tile_sharing
            TileStatus.CONNECTING -> R.string.tile_connecting
            TileStatus.CONNECTED -> R.string.tile_connected
            TileStatus.RECONNECTING -> R.string.tile_reconnecting
            TileStatus.ERROR -> R.string.tile_error
        }
    }
}
