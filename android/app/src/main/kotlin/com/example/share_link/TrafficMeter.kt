package com.example.share_link

/** Turns running byte totals into per-second speeds, sampled by the services' stats tickers. */
internal class TrafficMeter {
    private var lastUp = -1L
    private var lastDown = -1L
    private var lastMs = 0L

    /** Bytes per second (up, down) since the previous sample; the first sample after [reset] is 0. */
    fun sample(totalUp: Long, totalDown: Long, nowMs: Long): Pair<Long, Long> {
        val elapsed = nowMs - lastMs
        val first = lastUp < 0 || elapsed <= 0
        val speeds = if (first) {
            0L to 0L
        } else {
            perSecond(totalUp - lastUp, elapsed) to perSecond(totalDown - lastDown, elapsed)
        }
        lastUp = totalUp
        lastDown = totalDown
        lastMs = nowMs
        return speeds
    }

    fun reset() {
        lastUp = -1L
        lastDown = -1L
    }

    // A total that went down means the counter restarted; count it as no traffic.
    private fun perSecond(bytes: Long, elapsedMs: Long): Long =
        if (bytes <= 0) 0 else bytes * 1000 / elapsedMs
}
