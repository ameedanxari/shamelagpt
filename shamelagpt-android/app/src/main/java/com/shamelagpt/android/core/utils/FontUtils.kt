package com.shamelagpt.android.core.utils

import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import com.shamelagpt.android.R

object FontUtils {

    /**
     * Detects if the text is predominantly Urdu or Arabic.
     * Returns "ur" for Urdu, "ar" for Arabic, or null if neither/indeterminate.
     */
    fun detectLanguage(text: String): String? {
        // Specific Urdu characters
        // ٹ (U+0679), ڈ (U+0688), ڑ (U+0691), ں (U+06BA), ے (U+06D2), ہ (U+06C1), 
        // ھ (U+06BE), ژ (U+0698), گ (U+06AF), چ (U+0686), پ (U+067E)
        val urduSpecificChars = "[\\u0679\\u0688\\u0691\\u06BA\\u06D2\\u06C1\\u06BE\\u0698\\u06AF\\u0686\\u067E]".toRegex()
        
        if (urduSpecificChars.containsMatchIn(text)) {
            return "ur"
        }

        // Arabic script block (approximate U+0600 - U+06FF)
        val arabicScript = "[\\u0600-\\u06FF]".toRegex()
        if (arabicScript.containsMatchIn(text)) {
            return "ar"
        }

        return null
    }

    /**
     * Returns the appropriate FontFamily for the given language code.
     * Falls back to Naskh for "ar" and Nastaliq for "ur".
     */
    fun getFontFamilyForLanguage(language: String?): FontFamily {
        return when (language) {
            "ur" -> FontFamily(Font(R.font.noto_nastaliq_urdu_regular))
            "ar" -> FontFamily(Font(R.font.noto_naskh_arabic_regular))
            // Add more languages/fonts here if needed
            else -> FontFamily.Default // Or a primary app font
        }
    }
}
