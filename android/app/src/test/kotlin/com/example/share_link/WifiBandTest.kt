package com.example.share_link

import android.net.wifi.p2p.WifiP2pConfig
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WifiBandTest {

    @Test
    fun bandOfFrequency_mapsChannels() {
        assertEquals("2.4", bandOfFrequency(2437))
        assertEquals("5", bandOfFrequency(5180))
        assertEquals("5", bandOfFrequency(5825))
        assertEquals("6", bandOfFrequency(5955))
        assertNull(bandOfFrequency(0))
    }

    @Test
    fun bandHonored_onlyFailsForASpecificBand() {
        assertTrue(bandHonored("auto", fallback = true, actual = "2.4"))
        assertTrue(bandHonored("5", fallback = false, actual = "5"))
        // Unknown frequency (Android 10): trust that the request was applied.
        assertTrue(bandHonored("5", fallback = false, actual = null))
        assertFalse(bandHonored("5", fallback = false, actual = "2.4"))
        assertFalse(bandHonored("2.4", fallback = true, actual = null))
    }

    @Test
    fun configBand_unknownMeansAuto() {
        assertEquals(WifiP2pConfig.GROUP_OWNER_BAND_2GHZ, configBand("2.4"))
        assertEquals(WifiP2pConfig.GROUP_OWNER_BAND_5GHZ, configBand("5"))
        assertEquals(WifiP2pConfig.GROUP_OWNER_BAND_AUTO, configBand("auto"))
        assertEquals(WifiP2pConfig.GROUP_OWNER_BAND_AUTO, configBand("60"))
    }
}
