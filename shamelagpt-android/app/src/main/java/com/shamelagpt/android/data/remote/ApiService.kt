package com.shamelagpt.android.data.remote

import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.dto.ChatRequest
import com.shamelagpt.android.data.remote.dto.ChatResponse
import com.shamelagpt.android.data.remote.dto.ConversationRequest
import com.shamelagpt.android.data.remote.dto.ConversationResponse
import com.shamelagpt.android.data.remote.dto.HealthResponse
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.data.remote.dto.UpdateUserRequest
import com.shamelagpt.android.data.remote.dto.UserPreferencesRequest
import com.shamelagpt.android.data.remote.dto.UserResponse
import com.shamelagpt.android.data.remote.dto.EmptyResponse
import com.shamelagpt.android.data.remote.dto.ConversationMessagesResponse
import com.shamelagpt.android.data.remote.dto.ForgotPasswordRequest
import com.shamelagpt.android.data.remote.dto.GoogleSignInRequest
import com.shamelagpt.android.data.remote.dto.RefreshTokenRequest
import com.shamelagpt.android.data.remote.dto.OCRRequest
import com.shamelagpt.android.data.remote.dto.OCRResponse
import com.shamelagpt.android.data.remote.dto.ConfirmFactCheckRequest
import okhttp3.ResponseBody
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Streaming

/**
 * Retrofit API service interface for ShamelaGPT API.
 */
interface ApiService {

    /**
     * Health check endpoint.
     */
    @GET("api/health")
    suspend fun checkHealth(): HealthResponse

    /**
     * Chat endpoint - sends a message and receives AI response.
     */
    @POST("api/chat")
    suspend fun sendMessage(@Body request: ChatRequest): ChatResponse

    /**
     * Guest chat endpoint - unauthenticated chat.
     */
    @POST("api/guest/chat")
    suspend fun sendGuestMessage(@Body request: ChatRequest): ChatResponse

    /**
     * Streaming chat endpoint (SSE).
     */
    @Streaming
    @POST("api/chat/stream")
    suspend fun streamMessage(@Body request: ChatRequest): ResponseBody

    /**
     * Guest streaming chat endpoint (SSE).
     */
    @Streaming
    @POST("api/guest/chat/stream")
    suspend fun streamGuestMessage(@Body request: ChatRequest): ResponseBody

    /**
     * Signup endpoint.
     */
    @POST("api/auth/signup")
    suspend fun signup(@Body request: SignupRequest): AuthResponse

    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): AuthResponse

    /**
     * Forgot password endpoint.
     */
    @POST("api/auth/forgot-password")
    suspend fun forgotPassword(@Body request: ForgotPasswordRequest): EmptyResponse

    /**
     * Google Sign-In endpoint.
     */
    @POST("api/auth/google")
    suspend fun googleSignIn(@Body request: GoogleSignInRequest): AuthResponse

    /**
     * Refresh token endpoint.
     */
    @POST("api/auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): AuthResponse

    /**
     * Fetch current user.
     */
    @GET("api/auth/me")
    suspend fun getCurrentUser(): UserResponse

    /**
     * Update current user.
     */
    @PUT("api/auth/me")
    suspend fun updateCurrentUser(@Body request: UpdateUserRequest): UserResponse

    /**
     * Delete current user.
     */
    @DELETE("api/auth/me")
    suspend fun deleteCurrentUser(): EmptyResponse

    /**
     * Verify token.
     */
    @GET("api/auth/verify")
    suspend fun verifyToken(): EmptyResponse

    /**
     * Get user preferences.
     */
    @GET("api/auth/me/preferences")
    suspend fun getPreferences(): UserPreferencesRequest

    /**
     * Update user preferences.
     */
    @PUT("api/auth/me/preferences")
    suspend fun setPreferences(@Body request: UserPreferencesRequest): EmptyResponse

    @POST("api/chat/generate-title")
    suspend fun generateTitle(@Body request: ConversationRequest): com.shamelagpt.android.data.remote.dto.GenerateTitleResponse

    /**
     * OCR endpoint for extracting text from images.
     */
    @POST("api/chat/ocr")
    suspend fun ocr(@Body request: OCRRequest): OCRResponse

    /**
     * Confirm and fact-check endpoint (SSE).
     */
    @Streaming
    @POST("api/chat/confirm-factcheck")
    suspend fun confirmFactCheck(@Body request: ConfirmFactCheckRequest): ResponseBody

    /**
     * List conversations.
     */
    @GET("api/conversations")
    suspend fun listConversations(): List<ConversationResponse>

    /**
     * Create conversation.
     */
    @POST("api/conversations")
    suspend fun createConversation(@Body request: ConversationRequest): ConversationResponse

    /**
     * Delete all conversations.
     */
    @DELETE("api/conversations")
    suspend fun deleteAllConversations(): EmptyResponse

    /**
     * Delete a conversation.
     */
    @DELETE("api/conversations/{conversation_id}")
    suspend fun deleteConversation(@Path("conversation_id") conversationId: String): EmptyResponse

    /**
     * Fetch messages for a conversation.
     */
    @GET("api/conversations/{conversation_id}/messages")
    suspend fun getMessages(@Path("conversation_id") conversationId: String): ConversationMessagesResponse
}
