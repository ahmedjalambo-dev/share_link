package com.example.share_link

import org.junit.Assert.assertEquals
import org.junit.Test

class TrafficMeterTest {

    @Test
    fun firstSample_isZero() {
        val meter = TrafficMeter()
        assertEquals(0L to 0L, meter.sample(5_000, 9_000, 1_000))
    }

    @Test
    fun speed_isBytesOverRealTime() {
        val meter = TrafficMeter()
        meter.sample(0, 0, 1_000)
        assertEquals(1_024L to 4_096L, meter.sample(1_024, 4_096, 2_000))
        // A late tick (2 s) halves the per-second rate.
        assertEquals(512L to 0L, meter.sample(2_048, 4_096, 4_000))
    }

    @Test
    fun fallingCounter_isZero() {
        val meter = TrafficMeter()
        meter.sample(10_000, 10_000, 1_000)
        assertEquals(0L to 0L, meter.sample(100, 200, 2_000))
    }

    @Test
    fun reset_startsOver() {
        val meter = TrafficMeter()
        meter.sample(0, 0, 1_000)
        meter.reset()
        assertEquals(0L to 0L, meter.sample(50_000, 50_000, 2_000))
        assertEquals(1_000L to 1_000L, meter.sample(51_000, 51_000, 3_000))
    }
}
