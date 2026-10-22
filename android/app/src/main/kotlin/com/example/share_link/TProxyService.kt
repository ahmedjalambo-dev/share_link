package com.example.share_link

/**
 * JNI bridge to libhev-socks5-tunnel (tun2socks). The library's JNI_OnLoad registers these
 * natives on this exact class name (see PKGNAME in src/main/jni/Application.mk).
 */
@Suppress("FunctionName")
object TProxyService {
    init {
        System.loadLibrary("hev-socks5-tunnel")
    }

    /** Starts the tunnel on its own native thread. */
    @JvmStatic
    external fun TProxyStartService(configPath: String, fd: Int): Boolean

    /** Stops the tunnel and waits for its thread to finish. */
    @JvmStatic
    external fun TProxyStopService(): Boolean

    @JvmStatic
    external fun TProxyIsRunning(): Boolean

    /** [txPackets, txBytes, rxPackets, rxBytes]; tx = from apps (upload), rx = to apps (download). */
    @JvmStatic
    external fun TProxyGetStats(): LongArray
}
