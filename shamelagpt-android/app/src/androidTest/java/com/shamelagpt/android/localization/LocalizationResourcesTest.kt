package com.shamelagpt.android.localization

import android.content.Context
import android.content.res.Configuration
import androidx.annotation.StringRes
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.shamelagpt.android.R
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.util.Locale

@RunWith(AndroidJUnit4::class)
class LocalizationResourcesTest {

    private val criticalKeys = listOf(
        R.string.chat,
        R.string.history,
        R.string.settings,
        R.string.network_no_connection,
        R.string.network_too_many_requests,
        R.string.welcome_title,
        R.string.common_share
    )

    private val rtlSensitiveKeys = listOf(
        R.string.welcome_message,
        R.string.history_locked_message,
        R.string.network_access_forbidden
    )

    @Test
    fun requiredKeysExistInEnglishAndArabic() {
        criticalKeys.forEach { key ->
            val english = localizedString("en", key)
            val arabic = localizedString("ar", key)

            assertFalse("English translation missing for key=$key", english.isBlank())
            assertFalse("Arabic translation missing for key=$key", arabic.isBlank())
        }
    }

    @Test
    fun arabicRtlStringsContainArabicScript() {
        rtlSensitiveKeys.forEach { key ->
            val arabic = localizedString("ar", key)
            assertTrue(
                "Arabic translation should contain Arabic script for key=$key",
                arabic.any { Character.UnicodeBlock.of(it) == Character.UnicodeBlock.ARABIC }
            )
        }
    }

    private fun localizedString(language: String, @StringRes resId: Int): String {
        val baseContext = InstrumentationRegistry.getInstrumentation().targetContext
        val locale = Locale(language)
        val config = Configuration(baseContext.resources.configuration)
        config.setLocale(locale)
        val localizedContext: Context = baseContext.createConfigurationContext(config)
        return localizedContext.resources.getString(resId)
    }
}
