package com.example.share_link

import java.io.Closeable
import java.net.InetAddress
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

/** Where a device's name came from; a better source replaces a worse one, never the reverse. */
internal enum class NameSource { USER_AGENT, WIFI_DIRECT, APP }

/** One client of the proxy, as sent to Flutter for the devices list. */
data class DeviceSnapshot(
    val address: String,
    val name: String? = null,
    val nickname: String? = null,
    val bytesUp: Long = 0,
    val bytesDown: Long = 0,
    val speedUp: Long = 0,
    val speedDown: Long = 0,
    val connections: Int = 0,
    val blocked: Boolean = false,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "address" to address,
        "name" to name,
        "nickname" to nickname,
        "bytesUp" to bytesUp,
        "bytesDown" to bytesDown,
        "speedUp" to speedUp,
        "speedDown" to speedDown,
        "connections" to connections,
        "blocked" to blocked,
    )
}

/**
 * Per-client traffic, names and blocking for one sharing session (owned by [ProxyServer]).
 * Clients are told apart by their IP address on the Wi-Fi Direct network.
 */
internal class DeviceRegistry {

    private class Entry(val order: Long) {
        val bytesUp = AtomicLong()
        val bytesDown = AtomicLong()
        val sockets: MutableSet<Closeable> = ConcurrentHashMap.newKeySet()
        val meter = TrafficMeter()

        @Volatile
        var name: String? = null

        @Volatile
        var nameSource: NameSource? = null
    }

    private val entries = ConcurrentHashMap<InetAddress, Entry>()
    private val blocked: MutableSet<InetAddress> = ConcurrentHashMap.newKeySet()
    private val seen = AtomicLong()

    /** Called (on a proxy thread) the first time an address shows up, e.g. to look up its name. */
    @Volatile
    var onNewDevice: ((InetAddress) -> Unit)? = null

    fun isBlocked(address: InetAddress) = address in blocked

    /** Tracks [connection] as one of [address]'s open connections until [closed]. */
    fun opened(address: InetAddress, connection: Closeable) {
        entry(address).sockets.add(connection)
        // Accepted just before a block: don't let it through.
        if (address in blocked) closeQuietly(connection)
    }

    fun closed(address: InetAddress, connection: Closeable) {
        entries[address]?.sockets?.remove(connection)
    }

    fun countUp(address: InetAddress, bytes: Long) {
        entry(address).bytesUp.addAndGet(bytes)
    }

    fun countDown(address: InetAddress, bytes: Long) {
        entry(address).bytesDown.addAndGet(bytes)
    }

    /** Names [address] unless it already has a name from a better [source]. */
    fun nameDevice(address: InetAddress, name: String?, source: NameSource) {
        val clean = name?.trim()?.take(MAX_NAME_LENGTH)
        if (clean.isNullOrEmpty()) return
        val entry = entry(address)
        synchronized(entry) {
            val current = entry.nameSource
            if (current == null || source >= current) {
                entry.name = clean
                entry.nameSource = source
            }
        }
    }

    /** Cuts every connection of [address] and refuses new ones until [unblock]. */
    fun block(address: InetAddress) {
        blocked.add(address)
        entries[address]?.sockets?.forEach(::closeQuietly)
    }

    fun unblock(address: InetAddress) {
        blocked.remove(address)
    }

    /** Every device seen this session: active ones first, then by data used. Samples the speeds. */
    fun snapshot(nowMs: Long, nicknames: Map<String, String>): List<DeviceSnapshot> =
        entries.entries
            .sortedBy { it.value.order }
            .map { (address, entry) ->
                val up = entry.bytesUp.get()
                val down = entry.bytesDown.get()
                val (speedUp, speedDown) = entry.meter.sample(up, down, nowMs)
                val ip = address.hostAddress ?: address.toString()
                DeviceSnapshot(
                    address = ip,
                    name = entry.name,
                    nickname = nicknames[ip],
                    bytesUp = up,
                    bytesDown = down,
                    speedUp = speedUp,
                    speedDown = speedDown,
                    connections = entry.sockets.size,
                    blocked = address in blocked,
                )
            }
            .sortedWith(
                compareByDescending<DeviceSnapshot> { it.connections > 0 && !it.blocked }
                    .thenByDescending { it.bytesUp + it.bytesDown },
            )

    private fun entry(address: InetAddress): Entry {
        entries[address]?.let { return it }
        val created = Entry(seen.incrementAndGet())
        val existing = entries.putIfAbsent(address, created)
        if (existing != null) return existing
        onNewDevice?.invoke(address)
        return created
    }

    private companion object {
        const val MAX_NAME_LENGTH = 40
    }
}

/**
 * A rough device name from a browser's User-Agent ("iPhone", an Android model, …), or null.
 * Recent Chrome hides the Android model ("Android 10; K"), so that gives null too.
 */
internal fun deviceFromUserAgent(userAgent: String): String? {
    when {
        "iPhone" in userAgent -> return "iPhone"
        "iPad" in userAgent -> return "iPad"
    }
    Regex("""Android [\d.]+; ([^;)]+)""").find(userAgent)?.let { match ->
        val model = match.groupValues[1].substringBefore(" Build/").trim()
        return model.takeIf { it.length > 1 && it != "wv" }
    }
    return when {
        "Windows" in userAgent -> "Windows PC"
        "Macintosh" in userAgent -> "Mac"
        else -> null
    }
}
