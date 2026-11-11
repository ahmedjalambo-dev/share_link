package com.example.share_link

import android.util.Log
import java.io.IOException
import java.net.InetAddress

/**
 * WhatsApp-compatible proxy on Phone A, started with every share, so a phone without Share Link
 * can use WhatsApp's own proxy setting (Settings → Storage and data → Proxy). Verified on
 * devices for chat and media.
 *
 * Mirrors WhatsApp's official proxy (github.com/WhatsApp/proxy): plain TCP relays routed by port,
 * with no TLS on these ports. Its FAQ: "You are free to run your own pure TCP proxy … as long as
 * it forwards to g.whatsapp.net." Ports below 1024 (443/80) can't be opened by an Android app, so
 * the chat and media ports are the official 5222 and 7777. Calls are not supported by WhatsApp's
 * proxy at all.
 */
object WhatsAppRelay {
    const val CHAT_PORT = 5222
    const val MEDIA_PORT = 7777
    private const val CHAT_HOST = "g.whatsapp.net"
    private const val CHAT_TARGET_PORT = 5222
    private const val MEDIA_HOST = "whatsapp.net"
    private const val MEDIA_TARGET_PORT = 443

    /** Starts both relays on [proxy]. False if a port couldn't be opened (sharing still works). */
    fun start(proxy: ProxyServer, bindAddress: InetAddress): Boolean = try {
        proxy.startTcpRelay(bindAddress, CHAT_PORT, CHAT_HOST, CHAT_TARGET_PORT)
        proxy.startTcpRelay(bindAddress, MEDIA_PORT, MEDIA_HOST, MEDIA_TARGET_PORT)
        true
    } catch (e: IOException) {
        Log.w(TAG, "WhatsApp proxy unavailable: ${e.message}")
        false
    }
}
