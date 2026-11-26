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
    fun groupFrequencyFor_staysOnTheWifiChannelUnlessTheOtherBandWasChosen() {
        assertEquals(2437, groupFrequencyFor("auto", 2437))
        assertEquals(5180, groupFrequencyFor("auto", 5180))
        assertEquals(5180, groupFrequencyFor("5", 5180))
        assertEquals(2437, groupFrequencyFor("2.4", 2437))
        // The user asked for the other band on purpose: keep it (the app warns about the cost).
        assertEquals(0, groupFrequencyFor("5", 2437))
        assertEquals(0, groupFrequencyFor("2.4", 5180))
        assertEquals(0, groupFrequencyFor("auto", 0))
    }

    @Test
    fun channelMismatch_onlyWhenBothAreKnownAndDiffer() {
        assertTrue(channelMismatch(2437, 5180))
        assertTrue(channelMismatch(2412, 2437))
        assertFalse(channelMismatch(2437, 2437))
        assertFalse(channelMismatch(0, 5180))
        assertFalse(channelMismatch(2437, 0))
    }

    @Test
    fun directSubnet_detectsARouterOn192_168_49() {
        assertTrue(NetworkUtils.isDirectSubnetAddress("192.168.49.23"))
        assertFalse(NetworkUtils.isDirectSubnetAddress("192.168.1.23"))
        assertFalse(NetworkUtils.isDirectSubnetAddress(null))
    }

    @Test
    fun configBand_unknownMeansAuto() {
        assertEquals(WifiP2pConfig.GROUP_OWNER_BAND_2GHZ, configBand("2.4"))
        assertEquals(WifiP2pConfig.GROUP_OWNER_BAND_5GHZ, configBand("5"))
        assertEquals(WifiP2pConfig.GROUP_OWNER_BAND_AUTO, configBand("auto"))
        assertEquals(WifiP2pConfig.GROUP_OWNER_BAND_AUTO, configBand("60"))
    }
}
