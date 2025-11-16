package com.shamelagpt.android.presentation.chat

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
     * Message was sent successfully.
     */
    object MessageSent : ChatEvent()

    /**
     * Scroll the message list to the bottom.
     */
    object ScrollToBottom : ChatEvent()
}
