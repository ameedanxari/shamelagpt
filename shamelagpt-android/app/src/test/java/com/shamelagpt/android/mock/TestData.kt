package com.shamelagpt.android.mock

import com.shamelagpt.android.data.local.entity.ConversationType
import com.shamelagpt.android.data.remote.dto.ChatRequest
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.model.Source
import java.util.UUID

/**
 * Test data fixtures for unit and integration tests.
 */
object TestData {

    // ===== Sources =====

    val sampleSource1 = Source(
        bookName = "صحيح البخاري",
        sourceURL = "https://shamela.ws/book/1234/56"
    )

    val sampleSource2 = Source(
        bookName = "صحيح مسلم",
        sourceURL = "https://shamela.ws/book/5678/90"
    )

    val sampleSource3 = Source(
        bookName = "Sahih Al-Bukhari",
        sourceURL = "https://shamela.ws/book/1234/78"
    )

    val sampleSources = listOf(sampleSource1, sampleSource2)

    // ===== Messages =====

    val sampleUserMessage = Message(
        id = UUID.randomUUID().toString(),
        content = "What is the ruling on prayer?",
        isUserMessage = true,
        timestamp = System.currentTimeMillis(),
        sources = null,
        imageData = null,
        detectedLanguage = null,
        isFactCheckMessage = false
    )

    val sampleAssistantMessage = Message(
        id = UUID.randomUUID().toString(),
        content = "Prayer is one of the five pillars of Islam...\n\n## Sources\n- [صحيح البخاري](https://shamela.ws/book/1234/56)\n- [صحيح مسلم](https://shamela.ws/book/5678/90)",
        isUserMessage = false,
        timestamp = System.currentTimeMillis() + 1000,
        sources = sampleSources,
        imageData = null,
        detectedLanguage = null,
        isFactCheckMessage = false
    )

    val sampleFactCheckMessage = Message(
        id = UUID.randomUUID().toString(),
        content = "Is this hadith authentic: 'Verily actions are by intentions'?",
        isUserMessage = true,
        timestamp = System.currentTimeMillis(),
        sources = null,
        imageData = byteArrayOf(1, 2, 3, 4, 5), // Mock compressed image
        detectedLanguage = "ar",
        isFactCheckMessage = true
    )

    val sampleMessages = listOf(sampleUserMessage, sampleAssistantMessage)

    // ===== Conversations =====

    val sampleConversation = Conversation(
        id = UUID.randomUUID().toString(),
        threadId = "thread_abc123",
        title = "What is the ruling on prayer?",
        createdAt = System.currentTimeMillis() - 3600000, // 1 hour ago
        updatedAt = System.currentTimeMillis(),
        messages = sampleMessages,
        conversationType = ConversationType.REGULAR
    )

    val sampleFactCheckConversation = Conversation(
        id = UUID.randomUUID().toString(),
        threadId = "thread_xyz789",
        title = "Fact-check: 'Verily actions are by intentions'",
        createdAt = System.currentTimeMillis() - 7200000, // 2 hours ago
        updatedAt = System.currentTimeMillis() - 3600000,
        messages = listOf(sampleFactCheckMessage),
        conversationType = ConversationType.FACT_CHECK
    )

    val sampleConversations = listOf(sampleConversation, sampleFactCheckConversation)

    // ===== API DTOs =====

    val sampleChatRequest = ChatRequest(
        question = "What is the ruling on prayer?",
        threadId = null
    )

    val sampleChatRequestWithThread = ChatRequest(
        question = "Can you elaborate on that?",
        threadId = "thread_abc123"
    )

    val sampleChatResponse = ChatResponse(
        answer = "Prayer is one of the five pillars of Islam...\n\n## Sources\n- [صحيح البخاري](https://shamela.ws/book/1234/56)\n- [صحيح مسلم](https://shamela.ws/book/5678/90)",
        threadId = "thread_abc123"
    )

    val sampleChatResponseWithoutSources = ChatResponse(
        answer = "This is a general response without specific citations.",
        threadId = "thread_xyz789"
    )

    // ===== Markdown Responses =====

    const val markdownWithSources = """Prayer is one of the five pillars of Islam and is obligatory upon every Muslim.

## Sources
- [صحيح البخاري](https://shamela.ws/book/1234/56)
- [صحيح مسلم](https://shamela.ws/book/5678/90)"""

    const val markdownWithoutSources = """This is a response without sources.
It contains multiple paragraphs.

And some more content here."""

    const val markdownWithCodeBlocks = """Here is an example:

```kotlin
fun example() {
    println("Hello, World!")
}
```

## Sources
- [Example Book](https://shamela.ws/book/1/1)"""

    const val markdownWithMultipleSources = """Content here...

## Sources
- [Book One](https://shamela.ws/book/1/1)
- [Book Two](https://shamela.ws/book/2/2)
- [Book Three](https://shamela.ws/book/3/3)
- [Book Four](https://shamela.ws/book/4/4)"""

    const val markdownWithMalformedSources = """Content here...

## Sources
- [Book One](https://shamela.ws/book/1/1)
- Missing URL here
- [](https://shamela.ws/book/3/3)
- [Book Four]"""

    // ===== OCR Results =====

    val arabicOcrText = "الصلاة عماد الدين"
    val englishOcrText = "Prayer is the pillar of religion"
    val mixedOcrText = "Prayer الصلاة is important"

    // ===== Error Messages =====

    val networkErrorMessage = "No internet connection"
    val timeoutErrorMessage = "Request timed out"
    val serverErrorMessage = "Server error occurred"
    val ocrNoTextError = "No text found in image"
    val voiceInputPermissionError = "Microphone permission denied"

    // ===== Helper Functions =====

    /**
     * Creates a sample message with custom properties.
     */
    fun createMessage(
        id: String = UUID.randomUUID().toString(),
        content: String = "Sample message",
        isUserMessage: Boolean = true,
        timestamp: Long = System.currentTimeMillis(),
        sources: List<Source>? = null,
        imageData: ByteArray? = null,
        detectedLanguage: String? = null,
        isFactCheckMessage: Boolean = false
    ) = Message(
        id = id,
        content = content,
        isUserMessage = isUserMessage,
        timestamp = timestamp,
        sources = sources,
        imageData = imageData,
        detectedLanguage = detectedLanguage,
        isFactCheckMessage = isFactCheckMessage
    )

    /**
     * Creates a sample conversation with custom properties.
     */
    fun createConversation(
        id: String = UUID.randomUUID().toString(),
        threadId: String? = null,
        title: String = "Sample Conversation",
        createdAt: Long = System.currentTimeMillis(),
        updatedAt: Long = System.currentTimeMillis(),
        messages: List<Message> = emptyList(),
        conversationType: ConversationType = ConversationType.REGULAR
    ) = Conversation(
        id = id,
        threadId = threadId,
        title = title,
        createdAt = createdAt,
        updatedAt = updatedAt,
        messages = messages,
        conversationType = conversationType
    )

    /**
     * Creates a sample chat response with custom properties.
     */
    fun createChatResponse(
        answer: String = "Sample answer",
        threadId: String = "thread_sample"
    ) = ChatResponse(
        answer = answer,
        threadId = threadId
    )

    val sampleAuthResponse = AuthResponse(
        token = "mock_token",
        refreshToken = "mock_refresh_token",
        expiresIn = "3600",
        user = com.google.gson.JsonObject()
    )
}
