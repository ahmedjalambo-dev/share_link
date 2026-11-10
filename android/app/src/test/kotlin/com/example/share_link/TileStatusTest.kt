package com.example.share_link

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TileStatusTest {

    @Test
    fun shareMode_followsSharingState() {
        val client = ClientStatus.CONNECTED // ignored in share mode
        assertEquals(TileStatus.OFF, tileStatus(ShareSettings.MODE_SHARE, ShareStatus.STOPPED, client))
        assertEquals(TileStatus.STARTING, tileStatus(ShareSettings.MODE_SHARE, ShareStatus.STARTING, client))
        assertEquals(TileStatus.SHARING, tileStatus(ShareSettings.MODE_SHARE, ShareStatus.RUNNING, client))
        assertEquals(TileStatus.ERROR, tileStatus(ShareSettings.MODE_SHARE, ShareStatus.ERROR, client))
    }

    @Test
    fun connectMode_followsClientState() {
        val share = ShareStatus.RUNNING // ignored in connect mode
        val mode = ShareSettings.MODE_CONNECT
        assertEquals(TileStatus.OFF, tileStatus(mode, share, ClientStatus.DISCONNECTED))
        assertEquals(TileStatus.CONNECTING, tileStatus(mode, share, ClientStatus.CONNECTING))
        assertEquals(TileStatus.CONNECTED, tileStatus(mode, share, ClientStatus.CONNECTED))
        assertEquals(TileStatus.RECONNECTING, tileStatus(mode, share, ClientStatus.RECONNECTING))
        assertEquals(TileStatus.ERROR, tileStatus(mode, share, ClientStatus.ERROR))
    }

    @Test
    fun unknownMode_isTreatedAsShare() {
        assertEquals(TileStatus.SHARING, tileStatus("", ShareStatus.RUNNING, ClientStatus.DISCONNECTED))
    }

    @Test
    fun onlyRunningStatesAreActive() {
        val active = TileStatus.entries.filter { it.isActive }.toSet()
        assertEquals(
            setOf(
                TileStatus.STARTING,
                TileStatus.SHARING,
                TileStatus.CONNECTING,
                TileStatus.CONNECTED,
                TileStatus.RECONNECTING,
            ),
            active,
        )
        assertFalse(TileStatus.OFF.isActive)
        assertFalse(TileStatus.ERROR.isActive)
        assertTrue(TileStatus.RECONNECTING.isActive)
    }
}
