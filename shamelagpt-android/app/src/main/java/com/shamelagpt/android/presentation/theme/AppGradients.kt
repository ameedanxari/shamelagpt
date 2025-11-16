package com.shamelagpt.android.presentation.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

/**
 * App-wide gradient definitions matching shamelagpt.com design.
 */
object AppGradients {
    
    /**
     * Primary brand gradient: Emerald → Teal → Cyan
     * Used for buttons, headers, and brand moments.
     */
    val Primary: Brush
        get() = Brush.linearGradient(
            colors = listOf(Emerald500, Teal400, Cyan400)
        )
    
    /**
     * Horizontal button gradient: Emerald → Teal
     * Slightly simpler gradient for buttons.
     */
    val Button: Brush
        get() = Brush.horizontalGradient(
            colors = listOf(Emerald500, Teal400)
        )
    
    /**
     * Vertical gradient for backgrounds and headers.
     */
    val Vertical: Brush
        get() = Brush.verticalGradient(
            colors = listOf(Emerald500, Teal400, Cyan400)
        )
    
    /**
     * Radial gradient for splash/highlight effects.
     */
    val Radial: Brush
        get() = Brush.radialGradient(
            colors = listOf(Emerald400, Emerald500, Teal400)
        )
    
    /**
     * Creates a diagonal gradient from top-left to bottom-right.
     */
    fun diagonal(startColor: Color = Emerald500, endColor: Color = Teal400): Brush {
        return Brush.linearGradient(
            colors = listOf(startColor, endColor),
            start = Offset.Zero,
            end = Offset.Infinite
        )
    }
}

/**
 * Extension to create a text brush for gradient text.
 */
@Composable
fun gradientTextBrush(): Brush = AppGradients.Primary
