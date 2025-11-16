package com.shamelagpt.android.core.util

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent

/**
 * Handles opening donation links using Chrome Custom Tabs with fallback to browser
 */
object DonationLinkHandler {
    private const val DONATION_URL = "https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU"

    /**
     * Open the PayPal donation link
     * Uses Chrome Custom Tabs for a better user experience, falls back to default browser if unavailable
     */
    fun openDonationLink(context: Context) {
        try {
            // Try to open with Chrome Custom Tabs
            val builder = CustomTabsIntent.Builder()
            val customTabsIntent = builder.build()
            customTabsIntent.launchUrl(context, Uri.parse(DONATION_URL))
        } catch (e: Exception) {
            // Fallback to opening in default browser
            try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(DONATION_URL))
                context.startActivity(intent)
            } catch (e: Exception) {
                // If all else fails, do nothing (user may not have a browser)
                e.printStackTrace()
            }
        }
    }

    /**
     * Open a custom URL (for other links like Privacy Policy, Terms, etc.)
     */
    fun openUrl(context: Context, url: String) {
        try {
            val builder = CustomTabsIntent.Builder()
            val customTabsIntent = builder.build()
            customTabsIntent.launchUrl(context, Uri.parse(url))
        } catch (e: Exception) {
            try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                context.startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
