package com.example.share_link

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ReconnectTest {

    @Test
    fun reconnectDelay_backsOffThenCaps() {
        assertEquals(2_000L, reconnectDelayMs(1))
        assertEquals(4_000L, reconnectDelayMs(2))
        assertEquals(8_000L, reconnectDelayMs(3))
        assertEquals(16_000L, reconnectDelayMs(4))
        assertEquals(30_000L, reconnectDelayMs(5))
        assertEquals(30_000L, reconnectDelayMs(50))
        assertEquals(2_000L, reconnectDelayMs(0))
    }

    @Test
    fun isInfoRequest_onlyDirectGet() {
        assertTrue(isInfoRequest("GET", PHONE_A_INFO_PATH))
        assertFalse(isInfoRequest("POST", PHONE_A_INFO_PATH))
        assertFalse(isInfoRequest("GET", "http://example.com$PHONE_A_INFO_PATH"))
        assertFalse(isInfoRequest("GET", "/"))
    }

    @Test
    fun infoJson_roundTrip() {
        val json = buildInfoJson("DIRECT-ab-ShareLink")
        assertEquals("""{"ssid":"DIRECT-ab-ShareLink","v":1}""", json)
        assertEquals("DIRECT-ab-ShareLink", parseInfoSsid(json))
    }

    @Test
    fun infoJson_escapesQuotesAndBackslashes() {
        val name = """DIRECT-ab-My "Net" \1"""
        assertEquals(name, parseInfoSsid(buildInfoJson(name)))
    }

    @Test
    fun parseInfoSsid_rejectsNonDirectOrGarbage() {
        assertNull(parseInfoSsid("""{"ssid":"HomeWifi","v":1}"""))
        assertNull(parseInfoSsid("not json"))
        assertNull(parseInfoSsid(""))
    }
}
