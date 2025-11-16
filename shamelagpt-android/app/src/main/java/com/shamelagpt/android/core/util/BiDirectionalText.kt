package com.shamelagpt.android.core.util

import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.LayoutDirection
import com.shamelagpt.android.core.utils.FontUtils

/**
 * Utility for detecting and rendering bidirectional text with appropriate layout direction.
 */

/**
 * Checks if a character is a right-to-left character (Arabic, Hebrew, etc.)
 */
fun isRTLChar(char: Char): Boolean {
    return char.code in 0x0590..0x08FF || // Hebrew, Arabic, Syriac
            char.code in 0xFB1D..0xFDFF ||
            char.code in 0xFE70..0xFEFF
}

/**
 * Detects the layout direction based on the first non-space character in the text.
 */
fun detectLayoutDirection(text: String): LayoutDirection {
    val firstChar = text.firstOrNull { !it.isWhitespace() }
    return if (firstChar != null && isRTLChar(firstChar)) {
        LayoutDirection.Rtl
    } else {
        LayoutDirection.Ltr
    }
}

/**
 * Text composable that automatically detects and applies the correct layout direction
 * based on the text content.
 *
 * @param text The text to display
 * @param modifier Modifier for the text
 * @param style Text style
 * @param color Text color
 */
@Composable
fun BiDirectionalText(
    text: String,
    modifier: Modifier = Modifier,
    style: TextStyle = LocalTextStyle.current,
    color: Color = Color.Unspecified
) {
    val layoutDirection = remember(text) {
        detectLayoutDirection(text)
    }

    // Detect language and get appropriate font family
    val fontFamily = remember(text) {
        FontUtils.getFontFamilyForLanguage(FontUtils.detectLanguage(text))
    }

    CompositionLocalProvider(LocalLayoutDirection provides layoutDirection) {
        Text(
            fontFamily = fontFamily,
            text = text,
            modifier = modifier,
            style = style,
            color = color
        )
    }
}
