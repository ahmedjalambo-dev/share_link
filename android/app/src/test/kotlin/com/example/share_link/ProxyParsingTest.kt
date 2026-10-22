package com.example.share_link

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.DataInputStream
import java.net.InetAddress
import java.net.InetSocketAddress

class ProxyParsingTest {

    // region HTTP

    @Test
    fun parseHostPort_variants() {
        assertEquals("example.com" to 80, parseHostPort("example.com", 80))
        assertEquals("example.com" to 8080, parseHostPort("example.com:8080", 80))
        assertEquals("example.com" to 443, parseHostPort("user:pass@example.com:443", 80))
        assertEquals("::1" to 8443, parseHostPort("[::1]:8443", 443))
        assertEquals("::1" to 443, parseHostPort("[::1]", 443))
    }

    @Test
    fun parseHostPort_rejectsInvalid() {
        assertNull(parseHostPort("example.com:abc", 80))
        assertNull(parseHostPort("example.com:70000", 80))
        assertNull(parseHostPort(":80", 80))
        assertNull(parseHostPort("[::1", 80))
    }

    @Test
    fun parseHttpTarget_absoluteAndOriginForm() {
        assertEquals(
            HttpTarget("example.com", 80, "/a?b=1"),
            parseHttpTarget("http://example.com/a?b=1", listOf("GET http://example.com/a?b=1 HTTP/1.1")),
        )
        assertEquals(
            HttpTarget("example.com", 8080, "/"),
            parseHttpTarget("http://example.com:8080", listOf("GET http://example.com:8080 HTTP/1.1")),
        )
        assertEquals(
            HttpTarget("host.local", 80, "/x"),
            parseHttpTarget("/x", listOf("GET /x HTTP/1.1", "Host: host.local")),
        )
        assertNull(parseHttpTarget("/x", listOf("GET /x HTTP/1.1")))
        assertNull(parseHttpTarget("https://example.com/", listOf("GET https://example.com/ HTTP/1.1")))
    }

    @Test
    fun readHead_stopsAtBlankLine() {
        val raw = "GET / HTTP/1.1\r\nHost: a\r\n\r\nBODY"
        val input = ByteArrayInputStream(raw.toByteArray())
        assertEquals(listOf("GET / HTTP/1.1", "Host: a"), readHead(input))
        // The body is left unread for the tunnel.
        assertEquals('B'.code, input.read())
    }

    @Test
    fun readHead_returnsNullOnEof() {
        assertNull(readHead(ByteArrayInputStream("GET / HTTP/1.1\r\n".toByteArray())))
    }

    @Test
    fun buildRequestHead_rewritesForOrigin() {
        val head = listOf(
            "GET http://a/x HTTP/1.1",
            "Host: a",
            "Proxy-Connection: keep-alive",
            "Connection: keep-alive",
            "Accept: */*",
        )
        val result = String(buildRequestHead("GET", "/x", "HTTP/1.1", head), Charsets.ISO_8859_1)
        assertEquals("GET /x HTTP/1.1\r\nHost: a\r\nAccept: */*\r\nConnection: close\r\n\r\n", result)
    }

    // endregion

    // region SOCKS5

    @Test
    fun readSocksTarget_allAddressTypes() {
        assertEquals(SocksTarget("1.2.3.4", 443), readSocksTarget(data(0x01, 1, 2, 3, 4, 0x01, 0xBB)))
        val domain = "a.io".toByteArray()
        assertEquals(
            SocksTarget("a.io", 80),
            readSocksTarget(data(0x03, domain.size, *domain.map { it.toInt() }.toIntArray(), 0x00, 0x50)),
        )
        assertNull(readSocksTarget(data(0x09)))
    }

    @Test
    fun udpHeader_ipv4RoundTrip() {
        val address = InetSocketAddress(InetAddress.getByName("8.8.8.8"), 53)
        val header = udpHeaderFor(address)
        assertArrayEquals(bytes(0, 0, 0, 0x01, 8, 8, 8, 8, 0, 53), header)

        val datagram = header + byteArrayOf(0x42)
        assertEquals(10, udpHeaderLength(datagram, datagram.size))
        assertEquals(SocksTarget("8.8.8.8", 53), parseUdpTarget(datagram))
    }

    @Test
    fun udpHeader_domain() {
        val datagram = bytes(0, 0, 0, 0x03, 3, 'x'.code, '.'.code, 'y'.code, 0x01, 0xBB, 0x42)
        // RSV RSV FRAG ATYP (4) + length byte (1) + "x.y" (3) + port (2)
        assertEquals(10, udpHeaderLength(datagram, datagram.size))
        assertEquals(SocksTarget("x.y", 443), parseUdpTarget(datagram))
    }

    @Test
    fun udpHeaderLength_rejectsFragmentsAndTruncation() {
        assertNull(udpHeaderLength(bytes(0, 0, 1, 0x01, 8, 8, 8, 8, 0, 53), 10)) // FRAG != 0
        assertNull(udpHeaderLength(bytes(0, 0, 0, 0x01, 8, 8, 8), 7)) // too short
        assertNull(udpHeaderLength(bytes(0, 0, 0, 0x09, 0, 0), 6)) // unknown ATYP
    }

    // endregion

    private fun bytes(vararg values: Int) = ByteArray(values.size) { values[it].toByte() }

    private fun data(vararg values: Int) = DataInputStream(ByteArrayInputStream(bytes(*values)))
}
