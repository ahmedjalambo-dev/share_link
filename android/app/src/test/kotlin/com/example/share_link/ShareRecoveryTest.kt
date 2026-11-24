package com.example.share_link

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.Closeable

class ShareRecoveryTest {

    private class FakeConnection : Closeable {
        var closed = false
        override fun close() {
            closed = true
        }
    }

    @Test
    fun isOurGroup_needsTheGroupWithUsAsOwner() {
        assertTrue(isOurGroup(present = true, isOwner = true, name = "DIRECT-ab-Home", expectedName = "DIRECT-ab-Home"))
        // Below Android 10 the name is random, so it isn't compared.
        assertTrue(isOurGroup(present = true, isOwner = true, name = "DIRECT-xy-Android", expectedName = null))
        assertFalse(isOurGroup(present = false, isOwner = false, name = null, expectedName = "DIRECT-ab-Home"))
        assertFalse(isOurGroup(present = true, isOwner = false, name = "DIRECT-ab-Home", expectedName = "DIRECT-ab-Home"))
        assertFalse(isOurGroup(present = true, isOwner = true, name = "DIRECT-zz-Other", expectedName = "DIRECT-ab-Home"))
    }

    @Test
    fun resetUpstream_closesTrackedConnectionsOnce() {
        val server = ProxyServer(8282, { null })
        val tunnel = FakeConnection()
        val udp = FakeConnection()
        val finished = FakeConnection()
        server.trackUpstream(tunnel)
        server.trackUpstream(udp)
        server.trackUpstream(finished)
        server.untrackUpstream(finished)

        assertEquals(2, server.resetUpstream())
        assertTrue(tunnel.closed)
        assertTrue(udp.closed)
        assertFalse(finished.closed)
        assertEquals(0, server.resetUpstream())
    }
}
