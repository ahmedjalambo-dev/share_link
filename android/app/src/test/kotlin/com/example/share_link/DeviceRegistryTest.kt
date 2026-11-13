package com.example.share_link

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.Closeable
import java.net.InetAddress

class DeviceRegistryTest {

    private val phone = InetAddress.getByName("192.168.49.37")
    private val other = InetAddress.getByName("192.168.49.80")

    private class FakeConnection : Closeable {
        var closed = false
        override fun close() {
            closed = true
        }
    }

    @Test
    fun betterNameSourceWins_worseNeverReplaces() {
        val registry = DeviceRegistry()
        registry.nameDevice(phone, "iPhone", NameSource.USER_AGENT)
        registry.nameDevice(phone, "Redmi Note 14", NameSource.APP)
        registry.nameDevice(phone, "Android", NameSource.USER_AGENT)
        registry.nameDevice(phone, "DIRECT name", NameSource.WIFI_DIRECT)
        assertEquals("Redmi Note 14", registry.snapshot(0, emptyMap()).single().name)
    }

    @Test
    fun block_closesConnections_untilUnblocked() {
        val registry = DeviceRegistry()
        val first = FakeConnection()
        val second = FakeConnection()
        registry.opened(phone, first)
        registry.opened(other, second)

        registry.block(phone)
        assertTrue(first.closed)
        assertFalse(second.closed)
        assertTrue(registry.isBlocked(phone))
        // A connection that slipped in after the block is closed straight away.
        val late = FakeConnection()
        registry.opened(phone, late)
        assertTrue(late.closed)

        registry.unblock(phone)
        assertFalse(registry.isBlocked(phone))
    }

    @Test
    fun snapshot_countsTrafficAndNicknames_activeFirst() {
        val registry = DeviceRegistry()
        registry.countDown(phone, 5_000)
        registry.countUp(phone, 100)
        registry.countDown(other, 50)
        registry.opened(other, FakeConnection())

        val devices = registry.snapshot(1_000, mapOf("192.168.49.37" to "Ali"))
        assertEquals(listOf("192.168.49.80", "192.168.49.37"), devices.map { it.address })
        val ali = devices[1]
        assertEquals("Ali", ali.nickname)
        assertEquals(5_000L, ali.bytesDown)
        assertEquals(100L, ali.bytesUp)
        assertEquals(0, ali.connections)
        assertEquals(1, devices[0].connections)
    }

    @Test
    fun newDeviceCallback_firesOncePerAddress() {
        val registry = DeviceRegistry()
        val seen = mutableListOf<InetAddress>()
        registry.onNewDevice = { seen.add(it) }
        registry.countUp(phone, 1)
        registry.countUp(phone, 1)
        registry.opened(other, FakeConnection())
        assertEquals(listOf(phone, other), seen)
    }

    @Test
    fun deviceFromUserAgent_guessesOnlyWhenSure() {
        assertEquals(
            "iPhone",
            deviceFromUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15"),
        )
        assertEquals(
            "SM-S918B",
            deviceFromUserAgent("Mozilla/5.0 (Linux; Android 14; SM-S918B Build/UP1A.231005.007) AppleWebKit/537.36"),
        )
        assertNull(deviceFromUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 Chrome/126.0"))
        assertEquals("Windows PC", deviceFromUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64)"))
        assertNull(deviceFromUserAgent("okhttp/4.12.0"))
    }

    @Test
    fun deviceHeader_roundTripsArabicNames() {
        val encoded = encodeDeviceHeader("هاتف أحمد")
        assertTrue(encoded.all { it.code < 128 })
        assertEquals("هاتف أحمد", decodeDeviceHeader(encoded))
        assertNull(decodeDeviceHeader("%zz"))
        assertNull(decodeDeviceHeader("  "))
    }
}
