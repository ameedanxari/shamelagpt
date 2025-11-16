package com.shamelagpt.android.core.util

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import java.util.Locale

/**
 * Wraps a Context to apply the provided locale for older Android versions
 * as a fallback when AppCompat's application locales are not supported.
 */
object LocaleContextWrapper {
    fun wrap(context: Context, languageCode: String?): Context {
        if (languageCode.isNullOrBlank()) return context

        val locale = Locale(languageCode)
        Locale.setDefault(locale)

        val res = context.resources
        val config = Configuration(res.configuration)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val localeList = LocaleList(locale)
            LocaleList.setDefault(localeList)
            config.setLocales(localeList)
        } else {
            @Suppress("DEPRECATION")
            config.locale = locale
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            context.createConfigurationContext(config)
        } else {
            @Suppress("DEPRECATION")
            res.updateConfiguration(config, res.displayMetrics)
            context
        }
    }
}
