package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName
import com.google.gson.JsonElement

/**
 * Data transfer object for chat API requests.
 *
 * @property question User's question/message
 * @property threadId Optional thread ID from previous conversation
 * @property promptConfig Optional prompt configuration (string preset or object)
 * @property languagePreference Optional requested language (e.g., "Arabic", "English")
 * @property customSystemPrompt Optional additional system prompt appended to default
 * @property sessionId Optional session identifier for guest/local-only conversations
 * @property enableThinking Optional flag to enable/disable chain-of-thought
 */
data class ChatRequest(
    val question: String,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("prompt_config")
    val promptConfig: JsonElement? = null,
    @SerializedName("language_preference")
    val languagePreference: String? = null,
    @SerializedName("custom_system_prompt")
    val customSystemPrompt: String? = null,
    @SerializedName("session_id")
    val sessionId: String? = null,
    @SerializedName("enable_thinking")
    val enableThinking: Boolean? = null
)
