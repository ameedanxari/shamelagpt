package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.core.network.safeApiCall
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.dto.ChatRequest
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.StreamEvent
import com.shamelagpt.android.data.remote.dto.HealthResponse
import android.util.Log
import com.google.gson.Gson
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import com.shamelagpt.android.data.remote.dto.OCRRequest
import com.shamelagpt.android.data.remote.dto.OCRResponse
import com.shamelagpt.android.data.remote.dto.ConfirmFactCheckRequest
import okhttp3.ResponseBody

/**
 * Implementation of ChatRemoteDataSource using Retrofit.
 *
 * @property apiService Retrofit API service
 */
class ChatRemoteDataSourceImpl(
    private val apiService: ApiService,
    private val authRetryManager: com.shamelagpt.android.core.network.AuthRetryManager
) : ChatRemoteDataSource {

    private suspend fun <T> callWithAuth(block: suspend () -> T): Result<T> {
        return safeApiCall(authRetry = { authRetryManager.trySilentLogin() }) { block() }
    }

    override suspend fun sendMessage(
        question: String,
        threadId: String?,
        promptConfig: com.google.gson.JsonElement?,
        languagePreference: String?,
        customSystemPrompt: String?,
        enableThinking: Boolean?
    ): Result<ChatResponse> {
        return callWithAuth {
            val request = ChatRequest(
                question = question,
                threadId = threadId,
                promptConfig = promptConfig,
                languagePreference = languagePreference,
                customSystemPrompt = customSystemPrompt,
                enableThinking = enableThinking
            )
            apiService.sendMessage(request)
        }
    }

    override suspend fun sendGuestMessage(
        question: String,
        sessionId: String?,
        promptConfig: com.google.gson.JsonElement?,
        languagePreference: String?,
        customSystemPrompt: String?,
        enableThinking: Boolean?
    ): Result<ChatResponse> {
        return safeApiCall {
            val request = ChatRequest(
                question = question,
                promptConfig = promptConfig,
                languagePreference = languagePreference,
                customSystemPrompt = customSystemPrompt,
                sessionId = sessionId,
                enableThinking = enableThinking
            )
            apiService.sendGuestMessage(request)
        }
    }

    override fun streamMessage(
        question: String,
        threadId: String?,
        promptConfig: com.google.gson.JsonElement?,
        languagePreference: String?,
        customSystemPrompt: String?,
        enableThinking: Boolean?
    ): Flow<StreamEvent> = flow {
        val request = ChatRequest(
            question = question,
            threadId = threadId,
            promptConfig = promptConfig,
            languagePreference = languagePreference,
            customSystemPrompt = customSystemPrompt,
            enableThinking = enableThinking
        )

        val result = callWithAuth { apiService.streamMessage(request) }
        processStreamResult(result)
    }

    override fun streamGuestMessage(
        question: String,
        sessionId: String?,
        promptConfig: com.google.gson.JsonElement?,
        languagePreference: String?,
        customSystemPrompt: String?,
        enableThinking: Boolean?
    ): Flow<StreamEvent> = flow {
        val request = ChatRequest(
            question = question,
            promptConfig = promptConfig,
            languagePreference = languagePreference,
            customSystemPrompt = customSystemPrompt,
            sessionId = sessionId,
            enableThinking = enableThinking
        )

        val result = safeApiCall { apiService.streamGuestMessage(request) }
        processStreamResult(result)
    }

    private suspend fun kotlinx.coroutines.flow.FlowCollector<StreamEvent>.processStreamResult(result: Result<ResponseBody>) {
        result.onSuccess { responseBody ->
            val source = responseBody.source()
            val gson = Gson()
            try {
                while (!source.exhausted()) {
                    val line = source.readUtf8Line() ?: break
                    val trimmed = line.trim()
                    if (trimmed.startsWith("data:")) {
                        val data = trimmed.substring(5).trim()
                        if (data == "[DONE]") break
                        if (data.isEmpty()) continue

                        try {
                            val event = gson.fromJson(data, StreamEvent::class.java)
                            emit(event)
                        } catch (e: Exception) {
                            Log.e("ChatRemoteDataSource", "Error parsing SSE chunk: $data", e)
                        }
                    } else if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
                        // Some guest streams might send raw JSON objects without "data:" prefix
                        try {
                            val event = gson.fromJson(trimmed, StreamEvent::class.java)
                            emit(event)
                        } catch (e: Exception) {
                            Log.e("ChatRemoteDataSource", "Error parsing raw JSON chunk: $trimmed", e)
                        }
                    }
                }
            } finally {
                responseBody.close()
            }
        }.onFailure { 
            Log.e("ChatRemoteDataSource", "Stream request failed", it)
            throw it 
        }
    }

    override suspend fun ocr(request: OCRRequest): Result<OCRResponse> {
        return callWithAuth {
            apiService.ocr(request)
        }
    }

    override fun confirmFactCheck(request: ConfirmFactCheckRequest): Flow<StreamEvent> = flow {
        val result = callWithAuth { apiService.confirmFactCheck(request) }
        processStreamResult(result)
    }

    override suspend fun checkHealth(): Result<HealthResponse> {
        return safeApiCall {
            apiService.checkHealth()
        }
    }
}
