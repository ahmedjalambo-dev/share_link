package com.example.share_link

import java.io.Closeable
import java.io.IOException
import java.util.concurrent.CopyOnWriteArraySet

/** Logcat tag for the whole app: `adb logcat -s ShareLink`. */
internal const val TAG = "ShareLink"

/** Android always gives the Wi-Fi Direct group owner (Phone A) this address. */
internal const val DIRECT_OWNER_IP = "192.168.49.1"
internal const val DIRECT_SUBNET_PREFIX = "192.168.49."

internal fun closeQuietly(closeable: Closeable?) {
    try {
        closeable?.close()
    } catch (e: IOException) {
        // Ignore.
    }
}

/**
 * Process-wide state written by a service and observed by [MainActivity]. Listeners run on the
 * caller's thread; [MainActivity] re-posts them to the main thread for Flutter.
 */
open class ObservableState<T>(initial: T) {
    @Volatile
    var current: T = initial
        private set

    private val listeners = CopyOnWriteArraySet<(T) -> Unit>()

    @Synchronized
    fun update(transform: (T) -> T) {
        val next = transform(current)
        if (next == current) return
        current = next
        listeners.forEach { it(next) }
    }

    fun addListener(listener: (T) -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: (T) -> Unit) {
        listeners.remove(listener)
    }
}
