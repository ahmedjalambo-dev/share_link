package com.example.share_link

/** Receive mode stops retrying after this long, so the phone gets its own internet back. */
internal const val GIVE_UP_MS = 10 * 60_000L

/** True once reconnecting that started at [sinceMs] has gone on for [GIVE_UP_MS] (elapsed realtime). */
internal fun shouldGiveUp(sinceMs: Long, nowMs: Long): Boolean = nowMs - sinceMs >= GIVE_UP_MS

/** Wait before reconnect attempt [attempt] (1-based): 2 s, 4 s, 8 s, 16 s, then every 30 s. */
internal fun reconnectDelayMs(attempt: Int): Long {
    if (attempt <= 1) return FIRST_DELAY_MS
    val doublings = (attempt - 1).coerceAtMost(MAX_DOUBLINGS)
    return (FIRST_DELAY_MS shl doublings).coerceAtMost(MAX_DELAY_MS)
}

private const val FIRST_DELAY_MS = 2_000L
private const val MAX_DELAY_MS = 30_000L
private const val MAX_DOUBLINGS = 5
