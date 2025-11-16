# Android Architecture Document - ShamelaGPT

## Version: 1.0
## Date: 2025-11-02
## Target Platform: Android API 26+ (Android 8.0 Oreo)

---

## Table of Contents
1. [Architectural Pattern](#architectural-pattern)
2. [Project Structure](#project-structure)
3. [Dependency Injection](#dependency-injection)
4. [State Management](#state-management)
5. [Navigation Architecture](#navigation-architecture)
6. [Data Layer](#data-layer)
7. [Networking Layer](#networking-layer)
8. [Error Handling](#error-handling)
9. [Testing Strategy](#testing-strategy)
10. [Third-Party Dependencies](#third-party-dependencies)

---

## 1. Architectural Pattern

### MVVM with Clean Architecture

The app follows **MVVM (Model-View-ViewModel)** combined with **Clean Architecture** principles for separation of concerns.

#### Rationale
- **Jetpack Compose Native**: MVVM works seamlessly with Compose's state management
- **Testability**: Each layer can be tested independently
- **Scalability**: Easy to add new features without affecting existing code
- **Maintainability**: Clear separation between UI, business logic, and data
- **Google Recommended**: Official Android architecture pattern

#### Architecture Layers

```
┌─────────────────────────────────────────────┐
│      Presentation Layer (Jetpack Compose)    │
│  - Composables (UI)                         │
│  - ViewModels (UI State & Logic)            │
│  - Navigation                               │
└──────────────┬──────────────────────────────┘
               │ Observes StateFlow/LiveData
               ▼
┌─────────────────────────────────────────────┐
│          Domain Layer (Business Logic)       │
│  - Use Cases / Interactors                  │
│  - Domain Models                            │
│  - Repository Interfaces                    │
└──────────────┬──────────────────────────────┘
               │ Implements
               ▼
┌─────────────────────────────────────────────┐
│            Data Layer (Data Sources)         │
│  - Repository Implementations               │
│  - Remote Data Sources (API)                │
│  - Local Data Sources (Room DB)             │
│  - Data Models & Mappers                    │
└─────────────────────────────────────────────┘
```

---

## 2. Project Structure

```
app/
├── src/
│   ├── main/
│   │   ├── java/com/shamelagpt/
│   │   │   ├── ShamelaGPTApplication.kt
│   │   │   │
│   │   │   ├── core/
│   │   │   │   ├── di/
│   │   │   │   │   ├── AppModule.kt
│   │   │   │   │   ├── NetworkModule.kt
│   │   │   │   │   ├── DatabaseModule.kt
│   │   │   │   │   └── ViewModelModule.kt
│   │   │   │   ├── network/
│   │   │   │   │   ├── ApiClient.kt
│   │   │   │   │   ├── ApiService.kt
│   │   │   │   │   ├── NetworkError.kt
│   │   │   │   │   └── interceptors/
│   │   │   │   ├── database/
│   │   │   │   │   ├── AppDatabase.kt
│   │   │   │   │   ├── Converters.kt
│   │   │   │   │   └── dao/
│   │   │   │   │       ├── ConversationDao.kt
│   │   │   │   │       └── MessageDao.kt
│   │   │   │   ├── util/
│   │   │   │   │   ├── Constants.kt
│   │   │   │   │   ├── Extensions.kt
│   │   │   │   │   └── Logger.kt
│   │   │   │   └── preferences/
│   │   │   │       └── PreferencesManager.kt
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── model/
│   │   │   │   │   ├── Message.kt
│   │   │   │   │   ├── Conversation.kt
│   │   │   │   │   ├── Source.kt
│   │   │   │   │   └── User.kt
│   │   │   │   ├── repository/
│   │   │   │   │   ├── ChatRepository.kt
│   │   │   │   │   ├── ConversationRepository.kt
│   │   │   │   │   └── UserRepository.kt
│   │   │   │   └── usecase/
│   │   │   │       ├── SendMessageUseCase.kt
│   │   │   │       ├── GetConversationsUseCase.kt
│   │   │   │       ├── DeleteConversationUseCase.kt
│   │   │   │       └── SaveConversationUseCase.kt
│   │   │   │
│   │   │   ├── data/
│   │   │   │   ├── remote/
│   │   │   │   │   ├── dto/
│   │   │   │   │   │   ├── ChatRequest.kt
│   │   │   │   │   │   ├── ChatResponse.kt
│   │   │   │   │   │   └── ErrorResponse.kt
│   │   │   │   │   └── datasource/
│   │   │   │   │       ├── ChatRemoteDataSource.kt
│   │   │   │   │       └── ConversationRemoteDataSource.kt
│   │   │   │   ├── local/
│   │   │   │   │   ├── entity/
│   │   │   │   │   │   ├── ConversationEntity.kt
│   │   │   │   │   │   └── MessageEntity.kt
│   │   │   │   │   └── datasource/
│   │   │   │   │       ├── ChatLocalDataSource.kt
│   │   │   │   │       └── ConversationLocalDataSource.kt
│   │   │   │   ├── mapper/
│   │   │   │   │   ├── ConversationMapper.kt
│   │   │   │   │   └── MessageMapper.kt
│   │   │   │   └── repository/
│   │   │   │       ├── ChatRepositoryImpl.kt
│   │   │   │       └── ConversationRepositoryImpl.kt
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── MainActivity.kt
│   │   │       ├── navigation/
│   │   │       │   ├── Navigation.kt
│   │   │       │   ├── Route.kt
│   │   │       │   └── NavGraph.kt
│   │   │       ├── theme/
│   │   │       │   ├── Color.kt
│   │   │       │   ├── Theme.kt
│   │   │       │   ├── Type.kt
│   │   │       │   └── Shape.kt
│   │   │       ├── components/
│   │   │       │   ├── MessageBubble.kt
│   │   │       │   ├── InputBar.kt
│   │   │       │   ├── TypingIndicator.kt
│   │   │       │   ├── LoadingState.kt
│   │   │       │   └── EmptyState.kt
│   │   │       ├── welcome/
│   │   │       │   ├── WelcomeScreen.kt
│   │   │       │   └── WelcomeViewModel.kt
│   │   │       ├── chat/
│   │   │       │   ├── ChatScreen.kt
│   │   │       │   ├── ChatViewModel.kt
│   │   │       │   └── ChatUiState.kt
│   │   │       ├── history/
│   │   │       │   ├── HistoryScreen.kt
│   │   │       │   ├── HistoryViewModel.kt
│   │   │       │   └── components/
│   │   │       │       └── ConversationCard.kt
│   │   │       └── settings/
│   │   │           ├── SettingsScreen.kt
│   │   │           ├── SettingsViewModel.kt
│   │   │           └── LanguageSelectionScreen.kt
│   │   │
│   │   ├── res/
│   │   │   ├── values/
│   │   │   │   ├── strings.xml
│   │   │   │   ├── colors.xml
│   │   │   │   ├── themes.xml
│   │   │   │   └── dimens.xml
│   │   │   ├── values-ar/
│   │   │   │   └── strings.xml
│   │   │   ├── drawable/
│   │   │   ├── mipmap/
│   │   │   └── xml/
│   │   │       └── network_security_config.xml
│   │   │
│   │   └── AndroidManifest.xml
│   │
│   ├── test/
│   │   └── java/com/shamelagpt/
│   │       ├── domain/usecase/
│   │       ├── data/repository/
│   │       └── presentation/
│   │
│   └── androidTest/
│       └── java/com/shamelagpt/
│           ├── ui/
│           └── database/
│
├── build.gradle.kts
└── proguard-rules.pro
```

---

## 3. Dependency Injection

### Framework: Koin

**Version**: 3.5.0+

#### Implementation

```kotlin
// AppModule.kt
val appModule = module {
    single { PreferencesManager(androidContext()) }
    single { NetworkMonitor(androidContext()) }
}

// NetworkModule.kt
val networkModule = module {
    single { provideOkHttpClient() }
    single { provideRetrofit(get()) }
    single { provideApiService(get()) }
    single<ChatRemoteDataSource> { ChatRemoteDataSourceImpl(get()) }
}

private fun provideOkHttpClient(): OkHttpClient {
    return OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        })
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

// DatabaseModule.kt
val databaseModule = module {
    single { AppDatabase.getDatabase(androidContext()) }
    single { get<AppDatabase>().conversationDao() }
    single { get<AppDatabase>().messageDao() }
    single<ChatLocalDataSource> { ChatLocalDataSourceImpl(get(), get()) }
    single<ConversationLocalDataSource> { ConversationLocalDataSourceImpl(get(), get()) }
}

// RepositoryModule.kt
val repositoryModule = module {
    single<ChatRepository> {
        ChatRepositoryImpl(
            remoteDataSource = get(),
            localDataSource = get()
        )
    }
    single<ConversationRepository> {
        ConversationRepositoryImpl(
            localDataSource = get()
        )
    }
}

// UseCaseModule.kt
val useCaseModule = module {
    factory { SendMessageUseCase(get()) }
    factory { GetConversationsUseCase(get()) }
    factory { DeleteConversationUseCase(get()) }
}

// ViewModelModule.kt
val viewModelModule = module {
    viewModel { ChatViewModel(get(), get()) }
    viewModel { HistoryViewModel(get(), get()) }
    viewModel { SettingsViewModel(get()) }
}

// Application.kt
class ShamelaGPTApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        startKoin {
            androidLogger()
            androidContext(this@ShamelaGPTApplication)
            modules(
                appModule,
                networkModule,
                databaseModule,
                repositoryModule,
                useCaseModule,
                viewModelModule
            )
        }
    }
}
```

#### Usage in Composables

```kotlin
@Composable
fun ChatScreen(
    viewModel: ChatViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    ChatContent(
        uiState = uiState,
        onSendMessage = viewModel::sendMessage
    )
}
```

---

## 4. State Management

### Kotlin Flow & StateFlow

#### ViewModel Pattern

```kotlin
data class ChatUiState(
    val messages: List<Message> = emptyList(),
    val inputText: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val conversationId: String? = null,
    val threadId: String? = null
)

class ChatViewModel(
    private val sendMessageUseCase: SendMessageUseCase,
    private val getConversationUseCase: GetConversationUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(ChatUiState())
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    private val _events = Channel<ChatEvent>()
    val events = _events.receiveAsFlow()

    fun sendMessage(text: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            sendMessageUseCase(
                question = text,
                threadId = _uiState.value.threadId
            )
                .onSuccess { response ->
                    _uiState.update {
                        it.copy(
                            messages = it.messages + response.message,
                            threadId = response.threadId,
                            isLoading = false,
                            inputText = ""
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message
                        )
                    }
                    _events.send(ChatEvent.ShowError(error.message ?: "Unknown error"))
                }
        }
    }

    fun updateInputText(text: String) {
        _uiState.update { it.copy(inputText = text) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

sealed class ChatEvent {
    data class ShowError(val message: String) : ChatEvent()
    object MessageSent : ChatEvent()
    object NavigateBack : ChatEvent()
}
```

#### State Collection in Compose

```kotlin
@Composable
fun ChatScreen(viewModel: ChatViewModel = koinViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is ChatEvent.ShowError -> {
                    // Show snackbar or toast
                }
                ChatEvent.MessageSent -> {
                    // Scroll to bottom
                }
                ChatEvent.NavigateBack -> {
                    // Navigate back
                }
            }
        }
    }

    ChatContent(
        uiState = uiState,
        onSendMessage = viewModel::sendMessage,
        onInputChange = viewModel::updateInputText
    )
}
```

---

## 5. Navigation Architecture

### Jetpack Navigation Compose (Type-Safe)

#### Route Definitions

```kotlin
import kotlinx.serialization.Serializable

@Serializable
object WelcomeRoute

@Serializable
data class ChatRoute(val conversationId: String? = null)

@Serializable
object HistoryRoute

@Serializable
object SettingsRoute

@Serializable
object LanguageSelectionRoute
```

#### Navigation Graph

```kotlin
@Composable
fun ShamelaGPTNavGraph(
    navController: NavHostController = rememberNavController(),
    startDestination: Any = WelcomeRoute
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable<WelcomeRoute> {
            WelcomeScreen(
                onNavigateToChat = {
                    navController.navigate(ChatRoute()) {
                        popUpTo<WelcomeRoute> { inclusive = true }
                    }
                }
            )
        }

        composable<ChatRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<ChatRoute>()
            ChatScreen(
                conversationId = route.conversationId,
                onNavigateBack = { navController.navigateUp() }
            )
        }

        composable<HistoryRoute> {
            HistoryScreen(
                onNavigateToChat = { conversationId ->
                    navController.navigate(ChatRoute(conversationId = conversationId))
                }
            )
        }

        composable<SettingsRoute> {
            SettingsScreen(
                onNavigateToLanguage = {
                    navController.navigate(LanguageSelectionRoute)
                },
                onNavigateBack = { navController.navigateUp() }
            )
        }

        composable<LanguageSelectionRoute> {
            LanguageSelectionScreen(
                onNavigateBack = { navController.navigateUp() }
            )
        }
    }
}
```

#### Main Activity

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            ShamelaGPTTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    ShamelaGPTApp()
                }
            }
        }
    }
}

@Composable
fun ShamelaGPTApp() {
    val navController = rememberNavController()

    Scaffold(
        bottomBar = {
            BottomNavigationBar(navController = navController)
        }
    ) { paddingValues ->
        ShamelaGPTNavGraph(
            navController = navController,
            modifier = Modifier.padding(paddingValues)
        )
    }
}
```

---

## 6. Data Layer

### Room Database Implementation

#### Entities

```kotlin
@Entity(tableName = "conversations")
data class ConversationEntity(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val threadId: String? = null,
    val title: String,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "messages",
    foreignKeys = [
        ForeignKey(
            entity = ConversationEntity::class,
            parentColumns = ["id"],
            childColumns = ["conversationId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("conversationId")]
)
data class MessageEntity(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val conversationId: String,
    val content: String,
    val isUserMessage: Boolean,
    val timestamp: Long = System.currentTimeMillis(),
    val sources: String? = null // JSON string
)
```

#### DAOs

```kotlin
@Dao
interface ConversationDao {
    @Query("SELECT * FROM conversations ORDER BY updatedAt DESC")
    fun getAllConversations(): Flow<List<ConversationEntity>>

    @Query("SELECT * FROM conversations WHERE id = :id")
    suspend fun getConversationById(id: String): ConversationEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertConversation(conversation: ConversationEntity)

    @Update
    suspend fun updateConversation(conversation: ConversationEntity)

    @Delete
    suspend fun deleteConversation(conversation: ConversationEntity)

    @Query("DELETE FROM conversations")
    suspend fun deleteAllConversations()
}

@Dao
interface MessageDao {
    @Query("SELECT * FROM messages WHERE conversationId = :conversationId ORDER BY timestamp ASC")
    fun getMessagesByConversationId(conversationId: String): Flow<List<MessageEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: MessageEntity)

    @Query("DELETE FROM messages WHERE conversationId = :conversationId")
    suspend fun deleteMessagesByConversationId(conversationId: String)
}
```

#### Database

```kotlin
@Database(
    entities = [ConversationEntity::class, MessageEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun conversationDao(): ConversationDao
    abstract fun messageDao(): MessageDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "shamelagpt_database"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
```

#### Repository Pattern

```kotlin
interface ChatRepository {
    suspend fun sendMessage(question: String, threadId: String?): Result<ChatResponse>
    fun getMessages(conversationId: String): Flow<List<Message>>
    suspend fun saveMessage(message: Message, conversationId: String): Result<Unit>
}

class ChatRepositoryImpl(
    private val remoteDataSource: ChatRemoteDataSource,
    private val localDataSource: ChatLocalDataSource
) : ChatRepository {

    override suspend fun sendMessage(
        question: String,
        threadId: String?
    ): Result<ChatResponse> {
        return try {
            // Call API
            val response = remoteDataSource.sendMessage(question, threadId)

            // Save to local database
            localDataSource.saveMessage(response.toMessageEntity())

            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun getMessages(conversationId: String): Flow<List<Message>> {
        return localDataSource.getMessages(conversationId)
            .map { entities ->
                entities.map { it.toDomainModel() }
            }
    }

    override suspend fun saveMessage(
        message: Message,
        conversationId: String
    ): Result<Unit> {
        return try {
            localDataSource.saveMessage(message.toEntity(conversationId))
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
```

---

## 7. Networking Layer

### Retrofit & OkHttp

```kotlin
interface ApiService {
    @POST("api/chat")
    suspend fun sendMessage(
        @Body request: ChatRequest
    ): ChatResponse

    @GET("api/health")
    suspend fun checkHealth(): HealthResponse
}

data class ChatRequest(
    val question: String,
    @SerializedName("thread_id")
    val threadId: String? = null,
    @SerializedName("user_id")
    val userId: String? = null
)

data class ChatResponse(
    val answer: String,
    @SerializedName("thread_id")
    val threadId: String
)
```

### Data Source Implementation

```kotlin
interface ChatRemoteDataSource {
    suspend fun sendMessage(question: String, threadId: String?): ChatResponse
    suspend fun checkHealth(): HealthResponse
}

class ChatRemoteDataSourceImpl(
    private val apiService: ApiService
) : ChatRemoteDataSource {

    override suspend fun sendMessage(
        question: String,
        threadId: String?
    ): ChatResponse {
        return withContext(Dispatchers.IO) {
            apiService.sendMessage(
                ChatRequest(
                    question = question,
                    threadId = threadId
                )
            )
        }
    }

    override suspend fun checkHealth(): HealthResponse {
        return withContext(Dispatchers.IO) {
            apiService.checkHealth()
        }
    }
}
```

---

## 8. Error Handling

### Error Types

```kotlin
sealed class NetworkError : Exception() {
    data class HttpError(val code: Int, override val message: String) : NetworkError()
    data class NetworkException(override val message: String) : NetworkError()
    data class UnknownError(override val message: String) : NetworkError()
}

sealed class RepositoryError : Exception() {
    object SaveFailed : RepositoryError()
    object FetchFailed : RepositoryError()
    object DeleteFailed : RepositoryError()
}
```

### Result Wrapper

```kotlin
suspend fun <T> safeApiCall(
    apiCall: suspend () -> T
): Result<T> {
    return try {
        Result.success(apiCall())
    } catch (e: HttpException) {
        Result.failure(
            NetworkError.HttpError(
                code = e.code(),
                message = e.message()
            )
        )
    } catch (e: IOException) {
        Result.failure(
            NetworkError.NetworkException(
                message = "Network error: ${e.message}"
            )
        )
    } catch (e: Exception) {
        Result.failure(
            NetworkError.UnknownError(
                message = e.message ?: "Unknown error"
            )
        )
    }
}
```

---

## 9. Testing Strategy

### Unit Tests

```kotlin
class SendMessageUseCaseTest {
    private lateinit var chatRepository: ChatRepository
    private lateinit var sendMessageUseCase: SendMessageUseCase

    @Before
    fun setup() {
        chatRepository = mockk()
        sendMessageUseCase = SendMessageUseCase(chatRepository)
    }

    @Test
    fun `sendMessage success returns ChatResponse`() = runTest {
        // Given
        val question = "What is Islam?"
        val mockResponse = ChatResponse(
            answer = "Islam is...",
            threadId = "thread-123"
        )
        coEvery { chatRepository.sendMessage(question, null) } returns Result.success(mockResponse)

        // When
        val result = sendMessageUseCase(question, null)

        // Then
        assertTrue(result.isSuccess)
        assertEquals(mockResponse, result.getOrNull())
    }
}
```

### UI Tests (Compose)

```kotlin
@Test
fun chatScreen_displayMessages() {
    composeTestRule.setContent {
        ShamelaGPTTheme {
            ChatScreen(
                viewModel = ChatViewModel(/* mocked dependencies */)
            )
        }
    }

    composeTestRule
        .onNodeWithTag("messageList")
        .assertExists()

    composeTestRule
        .onNodeWithText("What is Islam?")
        .assertIsDisplayed()
}
```

---

## 10. Third-Party Dependencies

### build.gradle.kts (Module Level)

```kotlin
dependencies {
    // Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")

    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // Koin (Dependency Injection)
    implementation("io.insert-koin:koin-android:3.5.3")
    implementation("io.insert-koin:koin-androidx-compose:3.5.3")

    // Retrofit (Networking)
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")

    // Room (Database)
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // Kotlin Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("io.mockk:mockk:1.13.9")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
}
```

---

## Architecture Benefits

### ✅ Pros
1. **Testability**: Each layer independently testable
2. **Maintainability**: Clear separation of concerns
3. **Scalability**: Easy feature addition
4. **Modern**: Uses latest Jetpack libraries
5. **Type-Safe Navigation**: Kotlin serialization-based routing
6. **Reactive**: Flow-based data streams
7. **Offline-First**: Room database with Flow

### ⚠️ Considerations
1. **Learning Curve**: Requires understanding of Clean Architecture
2. **Boilerplate**: More files and classes than simple architecture
3. **Complexity**: May be overkill for very small apps

---

## Conclusion

This architecture provides a solid, production-ready foundation for the ShamelaGPT Android app using modern Android development best practices, Jetpack Compose, and Clean Architecture principles.
