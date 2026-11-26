package com.example.share_link

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class EdgeCasesTest {

    @Test
    fun infoV2_carriesInternetAndBlocked() {
        val ok = parseInfo(buildInfoJson("DIRECT-ab-Home", internet = true))!!
        assertEquals("DIRECT-ab-Home", ok.ssid)
        assertEquals(true, ok.internet)
        assertFalse(ok.blocked)

        val cutOff = parseInfo(buildInfoJson("DIRECT-ab-Home", internet = false, blocked = true))!!
        assertEquals(false, cutOff.internet)
        assertTrue(cutOff.blocked)
    }

    @Test
    fun infoV1_fromAnOlderPhoneA_hasUnknownInternet() {
        val old = parseInfo("""{"ssid":"DIRECT-ab-Home","v":1}""")!!
        assertEquals("DIRECT-ab-Home", old.ssid)
        assertNull(old.internet)
        assertFalse(old.blocked)
        assertNull(parseInfo(""))
        // The HTTP head in front of the body doesn't get in the way.
        val response = "HTTP/1.1 200 OK\r\nContent-Length: 9\r\n\r\n" + buildInfoJson("DIRECT-x-A", internet = false)
        assertEquals(false, parseInfo(response)!!.internet)
    }

    @Test
    fun giveUp_afterTenMinutes() {
        assertFalse(shouldGiveUp(sinceMs = 1_000, nowMs = 1_000 + 9 * 60_000))
        assertTrue(shouldGiveUp(sinceMs = 1_000, nowMs = 1_000 + GIVE_UP_MS))
    }

    @Test
    fun capNicknames_keepsTheNewest() {
        val names = linkedMapOf("a" to "1", "b" to "2", "c" to "3")
        assertEquals(mapOf("b" to "2", "c" to "3"), capNicknames(names, 2))
        assertEquals(names, capNicknames(names, 5))
    }
}
