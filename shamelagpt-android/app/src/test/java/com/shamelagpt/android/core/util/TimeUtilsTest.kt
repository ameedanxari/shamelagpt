package com.shamelagpt.android.core.util

import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.util.Locale

class TimeUtilsTest {

    @Test
    fun localizeDigits_usesArabicIndicDigitsForArabicLocale() {
        val localized = localizeDigits("12:34", Locale("ar"))
        assertThat(localized).isEqualTo("١٢:٣٤")
    }

    @Test
    fun localizeDigits_keepsAsciiDigitsForEnglishLocale() {
        val localized = localizeDigits("12:34", Locale.ENGLISH)
        assertThat(localized).isEqualTo("12:34")
    }
}

