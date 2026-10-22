package com.example.share_link

import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.Socket

/** HTTP proxy: CONNECT tunnels (HTTPS) and plain requests, one request per connection. */
internal class HttpProxyHandler(private val server: ProxyServer) {

    fun handle(client: Socket, input: InputStream) {
        val head = readHead(input) ?: return
        val parts = head.first().split(' ')
        if (parts.size < 3) return sendError(client, 400, "Bad Request")
        val method = parts[0].uppercase()
        val target = parts[1]
        val version = parts[2]

        if (method == "CONNECT") {
            val (host, port) = parseHostPort(target, 443) ?: return sendError(client, 400, "Bad Request")
            val upstream = openUpstream(client, host, port) ?: return
            try {
                client.getOutputStream().write(CONNECT_OK)
                server.tunnel(client, input, upstream)
            } finally {
                server.release(upstream)
            }
        } else {
            val request = parseHttpTarget(target, head) ?: return sendError(client, 400, "Bad Request")
            val upstream = openUpstream(client, request.host, request.port) ?: return
            try {
                val rewritten = buildRequestHead(method, request.path, version, head)
                upstream.getOutputStream().write(rewritten)
                server.bytesUp.addAndGet(rewritten.size.toLong())
                server.tunnel(client, input, upstream)
            } finally {
                server.release(upstream)
            }
        }
    }

    /** Connects to the target, or replies 502 to the client and returns null. */
    private fun openUpstream(client: Socket, host: String, port: Int): Socket? = try {
        server.connectUpstream(host, port)
    } catch (e: IOException) {
        Log.d(TAG, "Upstream $host:$port failed: ${e.message}")
        sendError(client, 502, "Bad Gateway")
        null
    }

    private fun sendError(client: Socket, code: Int, reason: String) {
        val body = "$code $reason\n"
        val response = "HTTP/1.1 $code $reason\r\n" +
            "Content-Type: text/plain\r\n" +
            "Content-Length: ${body.length}\r\n" +
            "Connection: close\r\n\r\n" +
            body
        try {
            client.getOutputStream().write(response.toByteArray(Charsets.ISO_8859_1))
        } catch (e: IOException) {
            // Client already gone.
        }
    }
}

// Pure parsing helpers (unit-tested in ProxyParsingTest).

internal data class HttpTarget(val host: String, val port: Int, val path: String)

/** Reads the request line and headers (up to the blank line). Returns null on EOF or oversize. */
internal fun readHead(input: InputStream): List<String>? {
    val buffer = ByteArrayOutputStream()
    var tail = 0
    while (true) {
        if (buffer.size() >= MAX_HEAD_BYTES) return null
        val b = input.read()
        if (b < 0) return null
        buffer.write(b)
        tail = (tail shl 8) or b
        if (tail == CRLF_CRLF || (tail and 0xFFFF) == LF_LF) break
    }
    val lines = String(buffer.toByteArray(), Charsets.ISO_8859_1)
        .lines()
        .dropWhile { it.isEmpty() }
        .takeWhile { it.isNotEmpty() }
    return lines.ifEmpty { null }
}

/** Accepts "http://host[:port]/path" (proxy form) or "/path" with a Host header. */
internal fun parseHttpTarget(target: String, head: List<String>): HttpTarget? {
    val authority: String
    val path: String
    if (target.startsWith("http://", ignoreCase = true)) {
        val rest = target.substring("http://".length)
        val slash = rest.indexOf('/').let { if (it < 0) rest.length else it }
        authority = rest.substring(0, slash)
        path = rest.substring(slash).ifEmpty { "/" }
    } else if (target.startsWith("/")) {
        authority = headerValue(head, "Host") ?: return null
        path = target
    } else {
        return null
    }
    val (host, port) = parseHostPort(authority, 80) ?: return null
    return HttpTarget(host, port, path)
}

/** "host", "host:port", "[ipv6]:port" or "user@host:port" → host and port. */
internal fun parseHostPort(authority: String, defaultPort: Int): Pair<String, Int>? {
    val value = authority.substringAfterLast('@').trim()
    val host: String
    val portText: String
    if (value.startsWith("[")) {
        val end = value.indexOf(']')
        if (end < 0) return null
        host = value.substring(1, end)
        portText = value.substring(end + 1).removePrefix(":")
    } else {
        val colon = value.lastIndexOf(':')
        host = if (colon >= 0) value.substring(0, colon) else value
        portText = if (colon >= 0) value.substring(colon + 1) else ""
    }
    val port = if (portText.isEmpty()) defaultPort else portText.toIntOrNull() ?: return null
    if (host.isEmpty() || port !in 1..65535) return null
    return host to port
}

/** Origin-form request line, hop-by-hop/proxy headers removed, one request per connection. */
internal fun buildRequestHead(method: String, path: String, version: String, head: List<String>): ByteArray {
    val builder = StringBuilder("$method $path $version\r\n")
    for (line in head.drop(1)) {
        val name = line.substringBefore(':').trim()
        if (DROPPED_HEADERS.any { it.equals(name, ignoreCase = true) }) continue
        builder.append(line).append("\r\n")
    }
    builder.append("Connection: close\r\n\r\n")
    return builder.toString().toByteArray(Charsets.ISO_8859_1)
}

private fun headerValue(head: List<String>, name: String): String? =
    head.drop(1).firstOrNull { it.substringBefore(':').trim().equals(name, ignoreCase = true) }
        ?.substringAfter(':')?.trim()

private const val MAX_HEAD_BYTES = 64 * 1024
private const val CRLF_CRLF = 0x0D0A0D0A
private const val LF_LF = 0x0A0A
private val CONNECT_OK = "HTTP/1.1 200 Connection Established\r\n\r\n".toByteArray(Charsets.ISO_8859_1)
private val DROPPED_HEADERS = listOf("Proxy-Connection", "Proxy-Authorization", "Connection", "Keep-Alive")
