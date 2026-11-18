package com.example.share_link

import android.net.wifi.p2p.WifiP2pConfig

// Wi-Fi Direct band choice ("auto", "2.4" or "5", see ShareSettings.band). Pure helpers,
// unit-tested in WifiBandTest.

internal const val BAND_AUTO = "auto"
internal const val BAND_2GHZ = "2.4"
internal const val BAND_5GHZ = "5"

/** The [WifiP2pConfig] band for a saved choice; anything unknown means automatic. */
internal fun configBand(band: String): Int = when (band) {
    BAND_2GHZ -> WifiP2pConfig.GROUP_OWNER_BAND_2GHZ
    BAND_5GHZ -> WifiP2pConfig.GROUP_OWNER_BAND_5GHZ
    else -> WifiP2pConfig.GROUP_OWNER_BAND_AUTO
}

/** "2.4", "5" or "6" for a channel frequency in MHz, or null when unknown (0). */
internal fun bandOfFrequency(mhz: Int): String? = when {
    mhz <= 0 -> null
    mhz < 3000 -> BAND_2GHZ
    mhz < 5925 -> BAND_5GHZ
    else -> "6"
}

/**
 * False when a specific band was asked for but the group isn't on it: creating it needed the
 * automatic fallback, or Android quietly picked another band (usually the shared Wi-Fi's).
 */
internal fun bandHonored(requested: String, fallback: Boolean, actual: String?): Boolean {
    if (requested == BAND_AUTO) return true
    if (fallback) return false
    return actual == null || actual == requested
}
