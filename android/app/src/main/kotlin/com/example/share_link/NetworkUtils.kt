package com.example.share_link

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import java.net.Inet4Address
import java.net.InetAddress

object NetworkUtils {
    /** The Wi-Fi network that has internet access, or null if Wi-Fi isn't connected. */
    fun findWifiNetwork(context: Context): Network? {
        val cm = context.getSystemService(ConnectivityManager::class.java) ?: return null
        @Suppress("DEPRECATION")
        return cm.allNetworks.firstOrNull { network ->
            val caps = cm.getNetworkCapabilities(network) ?: return@firstOrNull false
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) &&
                caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        }
    }

    /** The Wi-Fi network on Phone A's Wi-Fi Direct subnet, and Phone A's address (its gateway). */
    fun findDirectNetwork(cm: ConnectivityManager): Pair<Network, InetAddress>? {
        @Suppress("DEPRECATION")
        for (network in cm.allNetworks) {
            val caps = cm.getNetworkCapabilities(network) ?: continue
            if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) continue
            val link = cm.getLinkProperties(network) ?: continue
            if (isOnDirectSubnet(link)) return network to phoneAAddress(link)
        }
        return null
    }

    fun isOnDirectSubnet(link: LinkProperties): Boolean = link.linkAddresses.any {
        it.address is Inet4Address && it.address.hostAddress?.startsWith(DIRECT_SUBNET_PREFIX) == true
    }

    /** Phone A is the gateway of its Wi-Fi Direct group; fall back to Android's fixed owner address. */
    fun phoneAAddress(link: LinkProperties): InetAddress =
        link.routes.firstOrNull { it.isDefaultRoute && it.gateway is Inet4Address }?.gateway
            ?.takeUnless { it.isAnyLocalAddress }
            ?: InetAddress.getByName(DIRECT_OWNER_IP)
}
