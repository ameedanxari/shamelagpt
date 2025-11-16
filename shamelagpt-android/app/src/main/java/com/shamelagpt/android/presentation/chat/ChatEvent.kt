package com.shamelagpt.android.presentation.chat

import android.content.Intent

/**
 * One-time events emitted by the ChatViewModel.
 * These events are consumed by the UI and should be handled once.
 */
sealed class ChatEvent {
    /**
     * Show an error message to the user.
     */
    data class ShowError(val message: String) : ChatEvent()

    /**
     * Show a short toast message to the user.
     */
    data class ShowToast(val message: String) : ChatEvent()

    /**
     * Message was sent successfully.
     */
    object MessageSent : ChatEvent()

    /**
     * Scroll the message list to the bottom.
     */
    object ScrollToBottom : ChatEvent()

    /**
     * Auth is required; navigate to auth screen.
     */
    object RequireAuth : ChatEvent()

    /**
     * Launch fallback voice recognition activity.
     */
    data class LaunchVoiceRecognition(val intent: Intent) : ChatEvent()

    /**
     * Prompt user to configure/install a speech service and open settings.
     */
    data class ShowVoiceSetupPrompt(
        val message: String,
        val actionLabel: String,
        val intent: Intent
    ) : ChatEvent()

    /**
     * Show an in-app help sheet explaining how to enable voice input.
     */
    data class ShowVoiceSetupHelp(
        val intent: Intent?
    ) : ChatEvent()
}
