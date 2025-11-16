package com.shamelagpt.android.core.util

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView

/**
 * Haptic feedback utilities for improved user experience.
 */

/**
 * Provides different types of haptic feedback.
 */
enum class HapticFeedbackType {
    CLICK,
    LONG_PRESS,
    SUCCESS,
    ERROR,
    WARNING
}

/**
 * Performs haptic feedback using the device vibrator.
 *
 * @param context Android context
 * @param type Type of haptic feedback
 */
fun performHapticFeedback(context: Context, type: HapticFeedbackType) {
    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
        vibratorManager.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    if (!vibrator.hasVibrator()) return

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        val effect = when (type) {
            HapticFeedbackType.CLICK -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
            HapticFeedbackType.LONG_PRESS -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
            HapticFeedbackType.SUCCESS -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
            HapticFeedbackType.ERROR -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_DOUBLE_CLICK)
            HapticFeedbackType.WARNING -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
        }
        vibrator.vibrate(effect)
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val duration = when (type) {
            HapticFeedbackType.CLICK -> 10L
            HapticFeedbackType.LONG_PRESS -> 50L
            HapticFeedbackType.SUCCESS -> 10L
            HapticFeedbackType.ERROR -> 30L
            HapticFeedbackType.WARNING -> 40L
        }
        @Suppress("DEPRECATION")
        vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE))
    } else {
        val duration = when (type) {
            HapticFeedbackType.CLICK -> 10L
            HapticFeedbackType.LONG_PRESS -> 50L
            HapticFeedbackType.SUCCESS -> 10L
            HapticFeedbackType.ERROR -> 30L
            HapticFeedbackType.WARNING -> 40L
        }
        @Suppress("DEPRECATION")
        vibrator.vibrate(duration)
    }
}

/**
 * Composable helper to easily add haptic feedback to UI elements.
 */
@Composable
fun rememberHapticFeedback(): (HapticFeedbackType) -> Unit {
    val context = LocalContext.current
    return { type ->
        performHapticFeedback(context, type)
    }
}

/**
 * Extension function to perform haptic feedback on a View.
 */
fun View.performHaptic(type: HapticFeedbackType) {
    val feedbackConstant = when (type) {
        HapticFeedbackType.CLICK -> HapticFeedbackConstants.VIRTUAL_KEY
        HapticFeedbackType.LONG_PRESS -> HapticFeedbackConstants.LONG_PRESS
        else -> HapticFeedbackConstants.VIRTUAL_KEY
    }
    performHapticFeedback(feedbackConstant)
}
