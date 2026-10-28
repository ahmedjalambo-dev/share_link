package com.example.share_link

/** Wait before reconnect attempt [attempt] (1-based): 2 s, 4 s, 8 s, 16 s, then every 30 s. */
internal fun reconnectDelayMs(attempt: Int): Long {
    if (attempt <= 1) return FIRST_DELAY_MS
    val doublings = (attempt - 1).coerceAtMost(MAX_DOUBLINGS)
    return (FIRST_DELAY_MS shl doublings).coerceAtMost(MAX_DELAY_MS)
}

private const val FIRST_DELAY_MS = 2_000L
private const val MAX_DELAY_MS = 30_000L
private const val MAX_DOUBLINGS = 5
