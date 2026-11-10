package com.example.share_link

import android.content.Context
import android.os.Build
import androidx.core.content.edit
import java.security.SecureRandom

/** User settings stored natively so the service can read them without Flutter. */
class ShareSettings(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences("share_link_settings", Context.MODE_PRIVATE)

    /** "DIRECT-xy-" where xy is generated once, as Android requires for custom group names. */
    val ssidPrefix: String
        get() {
            val code = prefs.getString(KEY_CODE, null)
                ?: randomString(2, ALPHANUMERIC).also { prefs.edit { putString(KEY_CODE, it) } }
            return "DIRECT-$code-"
        }

    val networkName: String
        get() = prefs.getString(KEY_NAME, null) ?: DEFAULT_NAME

    val passphrase: String
        get() = prefs.getString(KEY_PASS, null)
            ?: randomString(10, PASS_CHARS).also { prefs.edit { putString(KEY_PASS, it) } }

    val port: Int
        get() = prefs.getInt(KEY_PORT, DEFAULT_PORT)

    val fullSsid: String
        get() = ssidPrefix + networkName

    /** UI language: "system", "en" or "ar". */
    var language: String
        get() = prefs.getString(KEY_LANGUAGE, null) ?: LANGUAGE_SYSTEM
        set(value) = prefs.edit { putString(KEY_LANGUAGE, value) }

    /** Home screen mode: "share" (Phone A) or "connect" (Phone B). */
    var mode: String
        get() = prefs.getString(KEY_MODE, null) ?: MODE_SHARE
        set(value) = prefs.edit { putString(KEY_MODE, value) }

    // Client mode (Phone B): Phone A's port and network, as entered on Phone B.

    val clientPort: Int
        get() = prefs.getInt(KEY_CLIENT_PORT, DEFAULT_PORT)

    /** Phone A's network name; may be empty on Android 10+ (the user picks it from a list). */
    val clientSsid: String
        get() = prefs.getString(KEY_CLIENT_SSID, null) ?: ""

    val clientPassphrase: String
        get() = prefs.getString(KEY_CLIENT_PASS, null) ?: ""

    /** Join Phone A's network from the app when not already on it. */
    val clientAutoJoin: Boolean
        get() = prefs.getBoolean(KEY_CLIENT_AUTO_JOIN, true)

    fun toMap(): Map<String, Any> = mapOf(
        "ssidPrefix" to ssidPrefix,
        "networkName" to networkName,
        "passphrase" to passphrase,
        "port" to port,
        "language" to language,
        "mode" to mode,
        "clientPort" to clientPort,
        "clientSsid" to clientSsid,
        "clientPassphrase" to clientPassphrase,
        "clientAutoJoin" to clientAutoJoin,
        "apiLevel" to Build.VERSION.SDK_INT,
        "customNetworkSupported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q),
    )

    /** Validates and stores the settings. Returns an error code, or null on success. */
    fun save(name: String, pass: String, newPort: Int): String? {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return ErrorCodes.INVALID_NAME
        if ((ssidPrefix + trimmed).toByteArray(Charsets.UTF_8).size > MAX_SSID_BYTES) return ErrorCodes.NAME_TOO_LONG
        if (!isValidPassphrase(pass)) return ErrorCodes.INVALID_PASSWORD
        if (newPort !in 1024..65535) return ErrorCodes.INVALID_PORT
        prefs.edit {
            putString(KEY_NAME, trimmed)
            putString(KEY_PASS, pass)
            putInt(KEY_PORT, newPort)
        }
        return null
    }

    /** Validates and stores Phone B's connection details. Returns an error code, or null on success. */
    fun saveClient(port: Int, ssid: String, passphrase: String, autoJoin: Boolean): String? {
        val name = ssid.trim()
        if (port !in 1024..65535) return ErrorCodes.INVALID_PORT
        if (autoJoin) {
            // Below Android 10 there's no network picker, so the exact name is needed.
            if (name.isEmpty() && Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return ErrorCodes.INVALID_NAME
            if (!isValidPassphrase(passphrase)) return ErrorCodes.INVALID_PASSWORD
        }
        prefs.edit {
            putInt(KEY_CLIENT_PORT, port)
            putString(KEY_CLIENT_SSID, name)
            putString(KEY_CLIENT_PASS, passphrase)
            putBoolean(KEY_CLIENT_AUTO_JOIN, autoJoin)
        }
        return null
    }

    /** WPA2 passphrase: 8–63 printable ASCII characters. */
    private fun isValidPassphrase(pass: String) = pass.length in 8..63 && pass.all { it.code in 32..126 }

    private fun randomString(length: Int, alphabet: String): String {
        val random = SecureRandom()
        return String(CharArray(length) { alphabet[random.nextInt(alphabet.length)] })
    }

    companion object {
        const val DEFAULT_NAME = "ShareLink"
        const val DEFAULT_PORT = 8282
        private const val MAX_SSID_BYTES = 32
        private const val KEY_CODE = "ssid_code"
        private const val KEY_NAME = "network_name"
        private const val KEY_PASS = "passphrase"
        private const val KEY_PORT = "port"
        private const val KEY_LANGUAGE = "language"
        private const val KEY_MODE = "mode"
        private const val KEY_CLIENT_PORT = "client_port"
        private const val KEY_CLIENT_SSID = "client_ssid"
        private const val KEY_CLIENT_PASS = "client_passphrase"
        private const val KEY_CLIENT_AUTO_JOIN = "client_auto_join"
        private const val MODE_SHARE = "share"
        val MODES = setOf(MODE_SHARE, "connect")
        private const val LANGUAGE_SYSTEM = "system"
        val LANGUAGES = setOf(LANGUAGE_SYSTEM, "en", "ar")
        private const val ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        // No look-alike characters (0/O, 1/l/I) so the password is easy to type on Phone B.
        private const val PASS_CHARS = "abcdefghjkmnpqrstuvwxyz23456789"
    }
}
