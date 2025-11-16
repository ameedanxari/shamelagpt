package com.shamelagpt.android.presentation.theme

import androidx.compose.ui.graphics.Color

// =============================================================================
// BRAND COLORS - Core identity colors matching shamelagpt.com
// =============================================================================

// Primary - Emerald (main brand color)
val Emerald500 = Color(0xFF10B981)  // Primary
val Emerald400 = Color(0xFF5CDBB3)  // Light variant
val Emerald600 = Color(0xFF059669)  // Dark variant

// Gradient colors
val Teal400 = Color(0xFF2DD4BF)     // Gradient middle
val Cyan400 = Color(0xFF22D3EE)     // Gradient end

// Accent - Amber (highlights, source links)
val Amber500 = Color(0xFFF59E0B)    // Accent
val Amber400 = Color(0xFFFBBF24)    // Light variant

// =============================================================================
// SEMANTIC COLORS - Light Theme
// =============================================================================

// Primary Colors
val Primary = Emerald500
val PrimaryContainer = Color(0xFFD1FAE5)  // Emerald-100
val OnPrimary = Color(0xFFFFFFFF)
val OnPrimaryContainer = Color(0xFF064E3B)  // Emerald-900

// Secondary Colors
val Secondary = Color(0xFF2E7D32)
val SecondaryContainer = Color(0xFFC8E6C9)
val OnSecondary = Color(0xFFFFFFFF)
val OnSecondaryContainer = Color(0xFF1B5E20)

// Tertiary Colors (Amber accent)
val Tertiary = Amber500
val TertiaryContainer = Color(0xFFFEF3C7)  // Amber-100
val OnTertiary = Color(0xFF000000)
val OnTertiaryContainer = Color(0xFF78350F)  // Amber-900

// Error Colors
val Error = Color(0xFFEF4444)
val ErrorContainer = Color(0xFFFEE2E2)
val OnError = Color(0xFFFFFFFF)
val OnErrorContainer = Color(0xFF7F1D1D)

// Background & Surface - Light
val Background = Color(0xFFFAFAFA)
val OnBackground = Color(0xFF111827)
val Surface = Color(0xFFF1F3F6)
val OnSurface = Color(0xFF111827)
val SurfaceVariant = Color(0xFFE3E7EC)
val OnSurfaceVariant = Color(0xFF374151)

// Outline
val Outline = Color(0xFFB6BFCB)
val OutlineVariant = Color(0xFFD5DBE3)

// =============================================================================
// SEMANTIC COLORS - Dark Theme (matching website)
// =============================================================================

// Primary Colors - Dark
val PrimaryDark = Emerald500  // Keep emerald vibrant in dark mode
val PrimaryContainerDark = Color(0xFF064E3B)  // Emerald-900
val OnPrimaryDark = Color(0xFFFFFFFF)
val OnPrimaryContainerDark = Color(0xFFD1FAE5)  // Emerald-100

// Secondary Colors - Dark
val SecondaryDark = Color(0xFF66BB6A)
val SecondaryContainerDark = Color(0xFF2E7D32)
val OnSecondaryDark = Color(0xFF000000)
val OnSecondaryContainerDark = Color(0xFFFFFFFF)

// Tertiary Colors - Dark (Amber accent)
val TertiaryDark = Amber500
val TertiaryContainerDark = Color(0xFF78350F)  // Amber-900
val OnTertiaryDark = Color(0xFF000000)
val OnTertiaryContainerDark = Color(0xFFFEF3C7)  // Amber-100

// Error Colors - Dark
val ErrorDark = Color(0xFFF87171)
val ErrorContainerDark = Color(0xFF7F1D1D)
val OnErrorDark = Color(0xFF000000)
val OnErrorContainerDark = Color(0xFFFEE2E2)

// Background & Surface - Dark (matching website: #0f0f0f, #171717)
val BackgroundDark = Color(0xFF0F0F0F)  // Deep black (website main bg)
val OnBackgroundDark = Color(0xFFE5E7EB)  // Light gray text
val SurfaceDark = Color(0xFF171717)  // Charcoal (website secondary bg)
val OnSurfaceDark = Color(0xFFE5E7EB)
val SurfaceVariantDark = Color(0xFF1F2937)  // Gray-800 (cards)
val OnSurfaceVariantDark = Color(0xFF9CA3AF)  // Gray-400

// Outline - Dark
val OutlineDark = Color(0xFF4B5563)  // Gray-600
val OutlineVariantDark = Color(0xFF374151)  // Gray-700

// =============================================================================
// MESSAGE COLORS
// =============================================================================

// User messages - subtle distinction without heavy background
val UserMessageBg = Color(0xFF1F2937)  // Gray-800 (dark mode)
val UserMessageBgLight = Color(0xFFF3F4F6)  // Gray-100 (light mode)

// AI messages
val AiMessageBg = Color(0xFF171717)  // Charcoal (dark mode)
val AiMessageBgLight = Color(0xFFF9FAFB)  // Gray-50 (light mode)

// Source links
val SourceLinkColor = Amber500
