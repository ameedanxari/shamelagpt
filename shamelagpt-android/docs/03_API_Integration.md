# Android API Integration Document - ShamelaGPT

## Version: 1.0
## Date: 2025-11-02
## API Base URL: https://api.shamelagpt.com

---

## Table of Contents
1. [API Overview](#api-overview)
2. [API Testing Results](#api-testing-results)
3. [Endpoint Documentation](#endpoint-documentation)
4. [Request/Response Models](#requestresponse-models)
5. [Error Handling](#error-handling)
6. [Networking Implementation](#networking-implementation)
7. [Offline Support](#offline-support)
8. [Rate Limiting](#rate-limiting)
9. [Security Considerations](#security-considerations)

---

## 1. API Overview

### Base URL
```
https://api.shamelagpt.com
```

### API Type
- **RESTful HTTP API**
- **Content-Type**: `application/json`
- **Response Format**: JSON

### Authentication
- ⚠️ **No authentication required** (as of API testing on 2025-11-02)
- **Phase 1**: Anonymous usage with optional `user_id` parameter
- **Future**: JWT or OAuth 2.0 authentication expected for Phase 2

### API Documentation
- **ReDoc**: https://api.shamelagpt.com/redoc
- **Swagger UI**: https://api.shamelagpt.com/docs
- **OpenAPI Spec**: https://api.shamelagpt.com/openapi.json

---

## 2. API Testing Results

### Testing Date: 2025-11-02

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `/api/health` | GET | ✅ **WORKING** | Returns service status |
| `/api/chat` | POST | ✅ **WORKING** | Returns answer + thread_id |
| `/api/chat` (with thread_id) | POST | ✅ **WORKING** | Conversation continuation works |
| `/api/conversations` | POST | ❌ **NOT WORKING** | Returns "Internal Server Error" |
| `/api/conversations` | GET | ❌ **NOT WORKING** | Returns "Internal Server Error" |
| `/api/conversations` | DELETE | ⚠️ **NOT TESTED** | - |
| `/api/conversations/{id}` | DELETE | ❌ **NOT WORKING** | Returns "Internal Server Error" |
| `/api/conversations/{id}/messages` | GET | ❌ **NOT WORKING** | Returns "Internal Server Error" |

### Key Findings

#### ✅ Working Features
1. **Health Check**: API is responsive
2. **Basic Chat**: Can send questions and receive answers
3. **Conversation Continuation**: Using `thread_id` returned from previous responses works correctly

#### ❌ Broken Features
1. **Conversation Management**: All conversation CRUD endpoints return 500 errors
2. **Message Retrieval**: Cannot fetch messages for a conversation
3. **User-specific queries**: `user_id` parameter causes errors

#### 📝 Implications for Android App

**Phase 1 Strategy**:
- ✅ Use `/api/chat` endpoint only
- ✅ Manage conversations **locally** in Room Database
- ✅ Generate `thread_id` by extracting from chat responses
- ✅ Store all messages locally
- ⚠️ **No server-side conversation sync** until API is fixed

**Future Phase Strategy** (when API is fixed):
- Sync conversations to server
- Fetch conversation history from server
- Multi-device sync

---

## 3. Endpoint Documentation

### 3.1 Health Check

#### `GET /api/health`

**Description**: Check API service status

**Request**:
```http
GET /api/health HTTP/1.1
Host: api.shamelagpt.com
```

**Response**:
```json
{
  "status": "ok",
  "service": "shamela-llm"
}
```

**Status Codes**:
- `200 OK`: Service is healthy

**Android Implementation**:
```kotlin
@GET("api/health")
suspend fun checkHealth(): Response<HealthResponse>

data class HealthResponse(
    val status: String,
    val service: String
)

// Usage
suspend fun checkApiHealth(): Result<HealthResponse> {
    return try {
        val response = apiService.checkHealth()
        if (response.isSuccessful && response.body() != null) {
            Result.success(response.body()!!)
        } else {
            Result.failure(Exception("Health check failed"))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }
}
```

---

### 3.2 Send Message (Chat)

#### `POST /api/chat`

**Description**: Send a question and receive an AI-generated answer

**Request**:
```http
POST /api/chat HTTP/1.1
Host: api.shamelagpt.com
Content-Type: application/json

{
  "question": "What is Islam?",
  "thread_id": "a0525c8b-2e52-4d82-9d41-9e6e3ad34541"
}
```

**Request Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `question` | string | ✅ Yes | User's question/message |
| `thread_id` | string | ❌ No | Conversation thread identifier (returned from previous response) |
| `user_id` | string | ❌ No | User identifier (⚠️ causes errors currently) |
| `prompt_config` | string/object | ❌ No | Custom prompt configuration |

**Response**:
```json
{
  "answer": "Here's a comprehensive answer...\n\n# What is Islam?\n\n...",
  "thread_id": "a0525c8b-2e52-4d82-9d41-9e6e3ad34541"
}
```

**Response Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `answer` | string | AI-generated response with markdown formatting |
| `thread_id` | string | Conversation identifier (UUID format) |

**Status Codes**:
- `200 OK`: Success
- `400 Bad Request`: Invalid request body
- `500 Internal Server Error`: Server error

**Android Implementation**:
```kotlin
// API Service
interface ApiService {
    @POST("api/chat")
    suspend fun sendMessage(@Body request: ChatRequest): Response<ChatResponse>
}

// Request Model
data class ChatRequest(
    val question: String,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("user_id")
    val userId: String? = null,
    @SerializedName("prompt_config")
    val promptConfig: String? = null
)

// Response Model
data class ChatResponse(
    val answer: String,
    @SerializedName("thread_id")
    val threadId: String
)

// Remote Data Source
class ChatRemoteDataSourceImpl(
    private val apiService: ApiService
) : ChatRemoteDataSource {

    override suspend fun sendMessage(
        question: String,
        threadId: String?
    ): Result<ChatResponse> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.sendMessage(
                ChatRequest(
                    question = question,
                    threadId = threadId
                )
            )

            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!)
            } else {
                Result.failure(
                    HttpException(response.code(), response.message())
                )
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
```

---

### 3.3 Create Conversation (⚠️ Not Working)

#### `POST /api/conversations`

**Status**: ❌ **Returns 500 Internal Server Error**

**Android Workaround**:
Create conversations locally in Room Database instead.

---

### 3.4 List Conversations (⚠️ Not Working)

#### `GET /api/conversations?user_id={user_id}`

**Status**: ❌ **Returns 500 Internal Server Error**

**Android Workaround**:
Fetch conversations from Room Database.

---

### 3.5 Delete Conversation (⚠️ Not Working)

#### `DELETE /api/conversations/{conversation_id}`

**Status**: ❌ **Returns 500 Internal Server Error**

**Android Workaround**:
Delete conversations from Room Database only.

---

### 3.6 Get Conversation Messages (⚠️ Not Working)

#### `GET /api/conversations/{conversation_id}/messages`

**Status**: ❌ **Returns 500 Internal Server Error**

**Android Workaround**:
Fetch messages from Room Database.

---

## 4. Request/Response Models

### Data Models

```kotlin
// MARK: - API Models (Data Transfer Objects)

data class ChatRequest(
    val question: String,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("user_id")
    val userId: String? = null,
    @SerializedName("prompt_config")
    val promptConfig: String? = null
)

data class ChatResponse(
    val answer: String,
    @SerializedName("thread_id")
    val threadId: String
)

data class HealthResponse(
    val status: String,
    val service: String
)

data class ErrorResponse(
    val detail: String? = null,
    val message: String? = null,
    val error: String? = null
) {
    fun getErrorMessage(): String {
        return detail ?: message ?: error ?: "Unknown error occurred"
    }
}

// MARK: - Domain Models

data class Message(
    val id: String = UUID.randomUUID().toString(),
    val content: String,
    val isUserMessage: Boolean,
    val timestamp: Long = System.currentTimeMillis(),
    val sources: List<Source>? = null
)

data class Source(
    val bookName: String,
    val sourceURL: String
)

data class Conversation(
    val id: String = UUID.randomUUID().toString(),
    val threadId: String? = null,
    val title: String,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val messages: List<Message> = emptyList()
)
```

### Response Parsing

The `answer` field contains markdown-formatted text with source citations at the end:

```markdown
# Answer Content

## Section

Content...

Sources:

* **book_name:** Book Title, **source_url:** https://shamela.ws/book/12345/67
* **book_name:** Another Book, **source_url:** https://shamela.ws/book/67890/12
```

**Parsing Strategy**:

```kotlin
fun ChatResponse.parseAnswer(): Pair<String, List<Source>> {
    val parts = answer.split("Sources:")

    val content = parts.firstOrNull() ?: answer
    val sources = if (parts.size > 1) {
        parseSources(parts[1])
    } else {
        emptyList()
    }

    return Pair(content, sources)
}

private fun parseSources(sourcesText: String): List<Source> {
    val pattern = """\*\*book_name:\*\*\s*([^,]+),\s*\*\*source_url:\*\*\s*(https?://[^\s]+)""".toRegex()

    return pattern.findAll(sourcesText).map { matchResult ->
        Source(
            bookName = matchResult.groupValues[1].trim(),
            sourceURL = matchResult.groupValues[2].trim()
        )
    }.toList()
}
```

---

## 5. Error Handling

### Error Types

```kotlin
sealed class NetworkError : Exception() {
    data class HttpError(val code: Int, override val message: String) : NetworkError()
    data class NetworkException(override val message: String) : NetworkError()
    data class TimeoutException(override val message: String) : NetworkError()
    data class UnknownError(override val message: String) : NetworkError()

    fun toUserMessage(): String {
        return when (this) {
            is HttpError -> when (code) {
                400 -> "Invalid request. Please try again."
                404 -> "Resource not found."
                500 -> "Server error. Please try again later."
                else -> "HTTP error ($code): $message"
            }
            is NetworkException -> "No internet connection. Please check your network."
            is TimeoutException -> "Request timed out. Please try again."
            is UnknownError -> "An error occurred: $message"
        }
    }
}

sealed class RepositoryError : Exception() {
    object SaveFailed : RepositoryError()
    object FetchFailed : RepositoryError()
    object DeleteFailed : RepositoryError()
}
```

### Safe API Call Wrapper

```kotlin
suspend fun <T> safeApiCall(
    apiCall: suspend () -> Response<T>
): Result<T> {
    return try {
        val response = apiCall()

        if (response.isSuccessful && response.body() != null) {
            Result.success(response.body()!!)
        } else {
            val errorBody = response.errorBody()?.string()
            val errorMessage = try {
                Gson().fromJson(errorBody, ErrorResponse::class.java)?.getErrorMessage()
            } catch (e: Exception) {
                null
            } ?: response.message()

            Result.failure(
                NetworkError.HttpError(
                    code = response.code(),
                    message = errorMessage
                )
            )
        }
    } catch (e: SocketTimeoutException) {
        Result.failure(NetworkError.TimeoutException("Request timed out"))
    } catch (e: IOException) {
        Result.failure(NetworkError.NetworkException("Network error: ${e.message}"))
    } catch (e: Exception) {
        Result.failure(NetworkError.UnknownError(e.message ?: "Unknown error"))
    }
}

// Usage
suspend fun sendMessage(question: String, threadId: String?): Result<ChatResponse> {
    return safeApiCall {
        apiService.sendMessage(ChatRequest(question, threadId))
    }
}
```

### Retry Logic

```kotlin
fun <T> Flow<T>.retryWithBackoff(
    maxRetries: Int = 3,
    initialDelay: Long = 1000,
    maxDelay: Long = 10000,
    factor: Double = 2.0
): Flow<T> = retryWhen { cause, attempt ->
    if (attempt < maxRetries && cause is IOException) {
        val delay = (initialDelay * factor.pow(attempt.toDouble())).toLong().coerceAtMost(maxDelay)
        delay(delay)
        true
    } else {
        false
    }
}

// Usage
flow {
    emit(apiService.sendMessage(request))
}
    .retryWithBackoff()
    .collect { response ->
        // Handle response
    }
```

---

## 6. Networking Implementation

### Retrofit Setup

```kotlin
// NetworkModule.kt (Koin)
val networkModule = module {
    single { provideOkHttpClient() }
    single { provideRetrofit(get()) }
    single { provideApiService(get()) }
}

private fun provideOkHttpClient(): OkHttpClient {
    val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = if (BuildConfig.DEBUG) {
            HttpLoggingInterceptor.Level.BODY
        } else {
            HttpLoggingInterceptor.Level.NONE
        }
    }

    return OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(loggingInterceptor)
        .addInterceptor(HeaderInterceptor())
        .build()
}

private fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
    return Retrofit.Builder()
        .baseUrl("https://api.shamelagpt.com/")
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
}

private fun provideApiService(retrofit: Retrofit): ApiService {
    return retrofit.create(ApiService::class.java)
}
```

### Custom Interceptors

```kotlin
class HeaderInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): okhttp3.Response {
        val original = chain.request()

        val request = original.newBuilder()
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .method(original.method, original.body)
            .build()

        return chain.proceed(request)
    }
}

class AuthInterceptor(private val preferencesManager: PreferencesManager) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): okhttp3.Response {
        val original = chain.request()

        // Add auth token if available (for future use)
        val token = preferencesManager.getAuthToken()

        val request = if (token != null) {
            original.newBuilder()
                .header("Authorization", "Bearer $token")
                .build()
        } else {
            original
        }

        return chain.proceed(request)
    }
}
```

---

## 7. Offline Support

### Strategy: Local-First Architecture

Since conversation management endpoints are not working, the app will use a **local-first** approach:

1. **All data stored locally** in Room Database
2. **API calls for chat only**
3. **Optimistic UI updates**
4. **Offline queue** for pending messages

### Implementation

```kotlin
class ChatRepositoryImpl(
    private val remoteDataSource: ChatRemoteDataSource,
    private val localDataSource: ChatLocalDataSource
) : ChatRepository {

    override suspend fun sendMessage(
        question: String,
        conversationId: String,
        threadId: String?
    ): Result<Message> {
        // 1. Save user message locally first (optimistic update)
        val userMessage = Message(
            content = question,
            isUserMessage = true,
            timestamp = System.currentTimeMillis()
        )

        localDataSource.saveMessage(userMessage, conversationId)

        // 2. Call API
        return remoteDataSource.sendMessage(question, threadId)
            .mapCatching { response ->
                // 3. Parse response
                val (content, sources) = response.parseAnswer()

                // 4. Create AI message
                val aiMessage = Message(
                    content = content,
                    isUserMessage = false,
                    timestamp = System.currentTimeMillis(),
                    sources = sources
                )

                // 5. Save AI message locally
                localDataSource.saveMessage(aiMessage, conversationId)

                // 6. Update conversation thread_id
                localDataSource.updateConversationThreadId(conversationId, response.threadId)

                aiMessage
            }
            .onFailure { error ->
                // Handle offline scenario
                if (error is NetworkError.NetworkException) {
                    // Mark message as pending sync
                    localDataSource.markMessageAsPending(userMessage.id)
                }
            }
    }

    override fun getMessages(conversationId: String): Flow<List<Message>> {
        return localDataSource.getMessages(conversationId)
    }
}
```

### Network Monitoring

```kotlin
class NetworkMonitor(context: Context) {
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private val _isConnected = MutableStateFlow(checkConnection())
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            connectivityManager.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    _isConnected.value = true
                }

                override fun onLost(network: Network) {
                    _isConnected.value = false
                }
            })
        }
    }

    private fun checkConnection(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }
}

// Usage in Composable
@Composable
fun ChatScreen(networkMonitor: NetworkMonitor = get()) {
    val isConnected by networkMonitor.isConnected.collectAsState()

    Scaffold(
        topBar = {
            if (!isConnected) {
                Surface(
                    color = MaterialTheme.colorScheme.errorContainer,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(8.dp),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(Icons.Filled.WifiOff, "No connection")
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("No internet connection")
                    }
                }
            }
        }
    ) { /* ... */ }
}
```

---

## 8. Rate Limiting

### Current Status
⚠️ **No rate limiting information** in API documentation

### Recommended Client-Side Rate Limiting

```kotlin
class RateLimiter(
    private val minimumInterval: Long = 1000L // 1 second
) {
    private var lastRequestTime: Long = 0L

    fun canMakeRequest(): Boolean {
        val now = System.currentTimeMillis()
        val elapsed = now - lastRequestTime

        return if (elapsed >= minimumInterval) {
            lastRequestTime = now
            true
        } else {
            false
        }
    }

    fun timeUntilNextRequest(): Long {
        val now = System.currentTimeMillis()
        val elapsed = now - lastRequestTime
        return maxOf(0L, minimumInterval - elapsed)
    }
}

// Usage in ViewModel
private val rateLimiter = RateLimiter()

fun sendMessage(text: String) {
    if (!rateLimiter.canMakeRequest()) {
        val waitTime = rateLimiter.timeUntilNextRequest() / 1000
        showError("Please wait $waitTime seconds before sending another message.")
        return
    }

    viewModelScope.launch {
        // Proceed with API call
    }
}
```

---

## 9. Security Considerations

### 9.1 HTTPS Only

```xml
<!-- res/xml/network_security_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

```xml
<!-- AndroidManifest.xml -->
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
</application>
```

### 9.2 Certificate Pinning (Optional)

```kotlin
val hostname = "api.shamelagpt.com"
val certificatePinner = CertificatePinner.Builder()
    .add(hostname, "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
    .build()

val okHttpClient = OkHttpClient.Builder()
    .certificatePinner(certificatePinner)
    .build()
```

### 9.3 Input Validation

```kotlin
fun validateQuestion(question: String): Result<String> {
    val trimmed = question.trim()

    return when {
        trimmed.isEmpty() -> Result.failure(Exception("Question cannot be empty"))
        trimmed.length > 1000 -> Result.failure(Exception("Question is too long (max 1000 characters)"))
        else -> Result.success(trimmed)
    }
}
```

### 9.4 Secure Storage (EncryptedSharedPreferences)

```kotlin
class PreferencesManager(context: Context) {
    private val encryptedPrefs = EncryptedSharedPreferences.create(
        "secure_prefs",
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build(),
        context,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun saveAuthToken(token: String) {
        encryptedPrefs.edit().putString("auth_token", token).apply()
    }

    fun getAuthToken(): String? {
        return encryptedPrefs.getString("auth_token", null)
    }
}
```

---

## Conclusion

The ShamelaGPT API provides basic chat functionality, but conversation management endpoints are currently not working. The Android app will adopt a **local-first** architecture, storing all data in Room Database and only using the `/api/chat` endpoint for AI responses.

### Key Takeaways:
1. ✅ Use `/api/chat` for sending questions and receiving answers
2. ✅ Store all conversations and messages locally in Room Database
3. ✅ Extract `thread_id` from responses for conversation continuation
4. ⚠️ Do not rely on server-side conversation management
5. ⚠️ Implement client-side rate limiting
6. ✅ Handle offline scenarios gracefully with NetworkMonitor
7. ✅ Parse sources from markdown responses

When the API conversation endpoints are fixed in the future, the app can be updated to sync with the server while maintaining backward compatibility with local data.
