# Android UI/UX Document - ShamelaGPT

## Version: 1.0
## Date: 2025-11-02
## Target Platform: Android API 26+ (Android 8.0 Oreo)
## Design Language: Material Design 3

---

## Table of Contents
1. [Design Philosophy](#design-philosophy)
2. [Material Design 3 Color System](#material-design-3-color-system)
3. [Typography](#typography)
4. [Navigation Structure](#navigation-structure)
5. [Screen Designs](#screen-designs)
6. [Component Library](#component-library)
7. [Multi-Language & RTL Support](#multi-language--rtl-support)
8. [Dark Theme](#dark-theme)
9. [Accessibility](#accessibility)
10. [Animations & Transitions](#animations--transitions)
11. [Material Design 3 Patterns](#material-design-3-patterns)

---

## 1. Design Philosophy

### Material Design 3 Principles
- **Personalization**: Dynamic color and Material You theming
- **Adaptive**: Responds to user preferences and context
- **Expressive**: Modern, bold, and intentional design
- **Accessible**: Built for all users

### Brand Values
- **Authenticity**: Trustworthy sources from Shamela.ws
- **Accessibility**: Knowledge for everyone
- **Respect**: Culturally sensitive Islamic content
- **Modern**: Contemporary interface with traditional values

---

## 2. Material Design 3 Color System

### Theme Setup

```kotlin
// Color.kt
val md_theme_light_primary = Color(0xFF10B981) // Emerald-500 (Islamic color)
val md_theme_light_onPrimary = Color(0xFFFFFFFF)
val md_theme_light_primaryContainer = Color(0xFF4C8C4A)
val md_theme_light_onPrimaryContainer = Color(0xFF000000)

val md_theme_light_secondary = Color(0xFF424242)
val md_theme_light_onSecondary = Color(0xFFFFFFFF)
val md_theme_light_secondaryContainer = Color(0xFF6D6D6D)
val md_theme_light_onSecondaryContainer = Color(0xFFFFFFFF)

val Accent = Color(0xFFF59E0B) // Amber-500 (for highlights)
val md_theme_light_onTertiary = Color(0xFF000000)

val md_theme_light_error = Color(0xFFB00020)
val md_theme_light_onError = Color(0xFFFFFFFF)

val md_theme_light_background = Color(0xFFFFFBFE)
val md_theme_light_onBackground = Color(0xFF1C1B1F)

val md_theme_light_surface = Color(0xFFFFFBFE)
val md_theme_light_onSurface = Color(0xFF1C1B1F)
val md_theme_light_surfaceVariant = Color(0xFFE7E0EC)
val md_theme_light_onSurfaceVariant = Color(0xFF49454F)

// Dark Theme Colors
val md_theme_dark_primary = Color(0xFF4C8C4A)
val md_theme_dark_onPrimary = Color(0xFF000000)
val md_theme_dark_primaryContainer = Color(0xFF1B5E20)
val md_theme_dark_onPrimaryContainer = Color(0xFFFFFFFF)

val md_theme_dark_secondary = Color(0xFF6D6D6D)
val md_theme_dark_onSecondary = Color(0xFFFFFFFF)

val md_theme_dark_tertiary = Color(0xFFD4AF37)
val md_theme_dark_onTertiary = Color(0xFF000000)

val md_theme_dark_error = Color(0xFFCF6679)
val md_theme_dark_onError = Color(0xFF000000)

val md_theme_dark_background = Color(0xFF1C1B1F)
val md_theme_dark_onBackground = Color(0xFFE6E1E5)

val md_theme_dark_surface = Color(0xFF1C1B1F)
val md_theme_dark_onSurface = Color(0xFFE6E1E5)
val md_theme_dark_surfaceVariant = Color(0xFF49454F)
val md_theme_dark_onSurfaceVariant = Color(0xFFCAC4D0)
```

### Theme Definition

```kotlin
// Theme.kt
private val LightColorScheme = lightColorScheme(
    primary = md_theme_light_primary,
    onPrimary = md_theme_light_onPrimary,
    primaryContainer = md_theme_light_primaryContainer,
    onPrimaryContainer = md_theme_light_onPrimaryContainer,
    secondary = md_theme_light_secondary,
    onSecondary = md_theme_light_onSecondary,
    tertiary = md_theme_light_tertiary,
    onTertiary = md_theme_light_onTertiary,
    error = md_theme_light_error,
    onError = md_theme_light_onError,
    background = md_theme_light_background,
    onBackground = md_theme_light_onBackground,
    surface = md_theme_light_surface,
    onSurface = md_theme_light_onSurface,
    surfaceVariant = md_theme_light_surfaceVariant,
    onSurfaceVariant = md_theme_light_onSurfaceVariant
)

private val DarkColorScheme = darkColorScheme(
    primary = md_theme_dark_primary,
    onPrimary = md_theme_dark_onPrimary,
    primaryContainer = md_theme_dark_primaryContainer,
    onPrimaryContainer = md_theme_dark_onPrimaryContainer,
    secondary = md_theme_dark_secondary,
    onSecondary = md_theme_dark_onSecondary,
    tertiary = md_theme_dark_tertiary,
    onTertiary = md_theme_dark_onTertiary,
    error = md_theme_dark_error,
    onError = md_theme_dark_onError,
    background = md_theme_dark_background,
    onBackground = md_theme_dark_onBackground,
    surface = md_theme_dark_surface,
    onSurface = md_theme_dark_onSurface,
    surfaceVariant = md_theme_dark_surfaceVariant,
    onSurfaceVariant = md_theme_dark_onSurfaceVariant
)

@Composable
fun ShamelaGPTTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true, // Material You dynamic colors
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = Shapes,
        content = content
    )
}
```

### Message Bubble Colors

```kotlin
// Custom colors for message bubbles
@Composable
fun userMessageColors() = MessageColors(
    backgroundColor = MaterialTheme.colorScheme.primary,
    textColor = MaterialTheme.colorScheme.onPrimary
)

@Composable
fun aiMessageColors() = MessageColors(
    backgroundColor = MaterialTheme.colorScheme.surfaceVariant,
    textColor = MaterialTheme.colorScheme.onSurfaceVariant
)

data class MessageColors(
    val backgroundColor: Color,
    val textColor: Color
)
```

---

## 3. Typography

### Type Scale

```kotlin
// Type.kt
val Typography = Typography(
    // Display
    displayLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 57.sp,
        lineHeight = 64.sp,
        letterSpacing = 0.sp
    ),
    displayMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 45.sp,
        lineHeight = 52.sp,
        letterSpacing = 0.sp
    ),
    displaySmall = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 36.sp,
        lineHeight = 44.sp,
        letterSpacing = 0.sp
    ),

    // Headline
    headlineLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = 0.sp
    ),
    headlineMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 28.sp,
        lineHeight = 36.sp,
        letterSpacing = 0.sp
    ),
    headlineSmall = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 24.sp,
        lineHeight = 32.sp,
        letterSpacing = 0.sp
    ),

    // Title
    titleLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 22.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.sp
    ),
    titleMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp
    ),
    titleSmall = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp
    ),

    // Body
    bodyLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.5.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.25.sp
    ),
    bodySmall = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp
    ),

    // Label
    labelLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp
    ),
    labelMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    ),
    labelSmall = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    )
)
```

### Usage Guidelines

| Element | Type Style |
|---------|-----------|
| Screen Title | Headline Medium |
| Welcome Message Title | Title Large |
| Message Content | Body Large |
| Timestamps | Label Small |
| Input Placeholder | Body Large |
| Button Labels | Label Large |
| Bottom Nav Labels | Label Medium |

---

## 4. Navigation Structure

### Navigation Pattern: Bottom Navigation Bar

```kotlin
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

@Composable
fun BottomNavigationBar(navController: NavHostController) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    NavigationBar {
        NavigationBarItem(
            icon = { Icon(Icons.Filled.Message, contentDescription = null) },
            label = { Text(stringResource(R.string.chat)) },
            selected = currentDestination?.route?.contains("chat") == true,
            onClick = {
                navController.navigate(ChatRoute()) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )

        NavigationBarItem(
            icon = { Icon(Icons.Filled.History, contentDescription = null) },
            label = { Text(stringResource(R.string.history)) },
            selected = currentDestination?.route == HistoryRoute.toString(),
            onClick = {
                navController.navigate(HistoryRoute) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )

        NavigationBarItem(
            icon = { Icon(Icons.Filled.Settings, contentDescription = null) },
            label = { Text(stringResource(R.string.settings)) },
            selected = currentDestination?.route == SettingsRoute.toString(),
            onClick = {
                navController.navigate(SettingsRoute) {
                    popUpTo(navController.graph.findStartDestination().id) {
                        saveState = true
                    }
                    launchSingleTop = true
                    restoreState = true
                }
            }
        )
    }
}
```

---

## 5. Screen Designs

### 5.1 Splash Screen (Android 12+)

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)

        // Keep splash screen visible while loading
        var keepSplashScreen = true
        splashScreen.setKeepOnScreenCondition { keepSplashScreen }

        // Simulate loading
        lifecycleScope.launch {
            delay(1000)
            keepSplashScreen = false
        }

        setContent {
            ShamelaGPTTheme {
                ShamelaGPTApp()
            }
        }
    }
}
```

---

### 5.2 Welcome Screen

```kotlin
@Composable
fun WelcomeScreen(
    onNavigateToChat: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        // Logo
        Image(
            painter = painterResource(id = R.drawable.ic_launcher_foreground),
            contentDescription = "ShamelaGPT Logo",
            modifier = Modifier.size(120.dp)
        )

        // Welcome Message
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "🌿 ${stringResource(R.string.welcome_title)}",
                style = MaterialTheme.typography.titleLarge,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = stringResource(R.string.welcome_message),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Start
            )
        }

        // Buttons
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Button(
                onClick = onNavigateToChat,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text(stringResource(R.string.get_started))
            }

            Spacer(modifier = Modifier.height(16.dp))

            TextButton(onClick = onNavigateToChat) {
                Text(stringResource(R.string.skip_to_chat))
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
    }
}
```

---

### 5.3 Chat Screen

```kotlin
@Composable
fun ChatScreen(
    conversationId: String? = null,
    viewModel: ChatViewModel = koinViewModel(),
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()

    LaunchedEffect(uiState.messages.size) {
        if (uiState.messages.isNotEmpty()) {
            listState.animateScrollToItem(uiState.messages.size - 1)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(uiState.conversationTitle ?: "ShamelaGPT") },
                actions = {
                    IconButton(onClick = { /* Show menu */ }) {
                        Icon(Icons.Filled.MoreVert, "Menu")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Messages List
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(
                    items = uiState.messages,
                    key = { it.id }
                ) { message ->
                    MessageBubble(message = message)
                }

                if (uiState.isLoading) {
                    item {
                        TypingIndicator()
                    }
                }
            }

            // Input Bar
            InputBar(
                text = uiState.inputText,
                onTextChange = viewModel::updateInputText,
                onSend = { viewModel.sendMessage(uiState.inputText) },
                onVoiceInput = { /* TODO */ },
                onImageInput = { /* TODO */ },
                isLoading = uiState.isLoading
            )
        }
    }
}
```

---

### 5.4 Conversation History Screen

```kotlin
@Composable
fun HistoryScreen(
    onNavigateToChat: (String) -> Unit,
    viewModel: HistoryViewModel = koinViewModel(),
    modifier: Modifier = Modifier
) {
    val conversations by viewModel.conversations.collectAsState(initial = emptyList())

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.history)) },
                actions = {
                    IconButton(onClick = { onNavigateToChat("") }) {
                        Icon(Icons.Filled.Add, "New Chat")
                    }
                }
            )
        }
    ) { paddingValues ->
        if (conversations.isEmpty()) {
            EmptyState(
                icon = Icons.Filled.History,
                title = stringResource(R.string.no_conversations),
                message = stringResource(R.string.start_new_chat),
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            )
        } else {
            LazyColumn(
                modifier = modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(
                    items = conversations,
                    key = { it.id }
                ) { conversation ->
                    ConversationCard(
                        conversation = conversation,
                        onClick = { onNavigateToChat(conversation.id) },
                        onDelete = { viewModel.deleteConversation(conversation.id) }
                    )
                }
            }
        }
    }
}
```

---

### 5.5 Settings Screen

```kotlin
@Composable
fun SettingsScreen(
    onNavigateToLanguage: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings)) }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // General Section
            item {
                SettingsSectionHeader(title = stringResource(R.string.general))
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.language),
                    subtitle = "English", // Dynamic
                    icon = Icons.Filled.Language,
                    onClick = onNavigateToLanguage
                )
            }

            // Support Section
            item {
                SettingsSectionHeader(title = stringResource(R.string.support))
            }

            item {
                SettingsItem(
                    title = "❤️ ${stringResource(R.string.support_shamelagpt)}",
                    icon = Icons.Filled.Favorite,
                    onClick = {
                        openDonationLink(context)
                    }
                )
            }

            // About Section
            item {
                SettingsSectionHeader(title = stringResource(R.string.about))
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.about_shamelagpt),
                    icon = Icons.Filled.Info,
                    onClick = { /* Navigate to About */ }
                )
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.privacy_policy),
                    icon = Icons.Filled.PrivacyTip,
                    onClick = { /* Navigate to Privacy */ }
                )
            }

            // Version
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Text(
                    text = "Version 1.0.0",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}
```

---

## 6. Component Library

### 6.1 Message Bubble

```kotlin
@Composable
fun MessageBubble(
    message: Message,
    modifier: Modifier = Modifier
) {
    val colors = if (message.isUserMessage) {
        userMessageColors()
    } else {
        aiMessageColors()
    }

    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = if (message.isUserMessage) {
            Arrangement.End
        } else {
            Arrangement.Start
        }
    ) {
        Column(
            modifier = Modifier.widthIn(max = 300.dp),
            horizontalAlignment = if (message.isUserMessage) {
                Alignment.End
            } else {
                Alignment.Start
            }
        ) {
            // Message Content
            Surface(
                color = colors.backgroundColor,
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier.combinedClickable(
                    onClick = {},
                    onLongClick = {
                        // Show context menu (copy, share)
                    }
                )
            ) {
                Text(
                    text = message.content,
                    style = MaterialTheme.typography.bodyLarge,
                    color = colors.textColor,
                    modifier = Modifier.padding(12.dp)
                )
            }

            // Sources (if AI message)
            if (!message.isUserMessage && message.sources != null) {
                Spacer(modifier = Modifier.height(4.dp))

                message.sources.forEach { source ->
                    ClickableText(
                        text = buildAnnotatedString {
                            append(source.bookName)
                        },
                        style = MaterialTheme.typography.labelSmall.copy(
                            color = MaterialTheme.colorScheme.primary
                        ),
                        onClick = {
                            // Open source URL
                        }
                    )
                }
            }

            // Timestamp
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = formatTimestamp(message.timestamp),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
```

### 6.2 Input Bar

```kotlin
@Composable
fun InputBar(
    text: String,
    onTextChange: (String) -> Unit,
    onSend: () -> Unit,
    onVoiceInput: () -> Unit,
    onImageInput: () -> Unit,
    isLoading: Boolean,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 3.dp
    ) {
        Row(
            modifier = Modifier
                .padding(8.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Image Input
            IconButton(
                onClick = onImageInput,
                enabled = !isLoading
            ) {
                Icon(Icons.Filled.Image, "Image input")
            }

            // Voice Input
            IconButton(
                onClick = onVoiceInput,
                enabled = !isLoading
            ) {
                Icon(Icons.Filled.Mic, "Voice input")
            }

            // Text Field
            OutlinedTextField(
                value = text,
                onValueChange = onTextChange,
                modifier = Modifier.weight(1f),
                placeholder = {
                    Text(stringResource(R.string.chat_placeholder))
                },
                enabled = !isLoading,
                maxLines = 5,
                shape = RoundedCornerShape(24.dp)
            )

            // Send Button
            IconButton(
                onClick = onSend,
                enabled = text.isNotBlank() && !isLoading
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.Send,
                    "Send",
                    tint = if (text.isNotBlank() && !isLoading) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )
            }
        }
    }
}
```

### 6.3 Typing Indicator

```kotlin
@Composable
fun TypingIndicator(modifier: Modifier = Modifier) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        modifier = modifier
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            repeat(3) { index ->
                val infiniteTransition = rememberInfiniteTransition(label = "typing")
                val scale by infiniteTransition.animateFloat(
                    initialValue = 0.5f,
                    targetValue = 1.0f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(600, easing = LinearEasing),
                        repeatMode = RepeatMode.Reverse,
                        initialStartOffset = StartOffset(index * 200)
                    ),
                    label = "dot_scale"
                )

                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .scale(scale)
                        .background(
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            shape = CircleShape
                        )
                )
            }
        }
    }
}
```

### 6.4 Conversation Card

```kotlin
@Composable
fun ConversationCard(
    conversation: Conversation,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = conversation.title,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = conversation.messages.lastOrNull()?.content ?: "",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = formatTimestamp(conversation.updatedAt),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Filled.Delete,
                    "Delete",
                    tint = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}
```

---

## 7. Multi-Language & RTL Support

### RTL Layout Detection

```kotlin
@Composable
fun MessageBubble(message: Message) {
    val layoutDirection = LocalLayoutDirection.current

    CompositionLocalProvider(
        LocalLayoutDirection provides layoutDirection
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = if (message.isUserMessage) {
                Arrangement.End
            } else {
                Arrangement.Start
            }
        ) {
            // Message content
        }
    }
}
```

### Bidirectional Text Support

```kotlin
@Composable
fun BiDirectionalText(
    text: String,
    style: TextStyle = MaterialTheme.typography.bodyLarge
) {
    val layoutDirection = if (text.firstOrNull()?.let { isRTLChar(it) } == true) {
        LayoutDirection.Rtl
    } else {
        LayoutDirection.Ltr
    }

    CompositionLocalProvider(LocalLayoutDirection provides layoutDirection) {
        Text(text = text, style = style)
    }
}

fun isRTLChar(char: Char): Boolean {
    return char.code in 0x0590..0x08FF || // Hebrew, Arabic, Syriac, Thaana
            char.code in 0xFB1D..0xFDFF ||
            char.code in 0xFE70..0xFEFF
}
```

---

## 8. Dark Theme

### Automatic Theme Switching

```kotlin
@Composable
fun ShamelaGPTTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
```

---

## 9. Accessibility

### Content Descriptions

```kotlin
IconButton(
    onClick = onSend,
    modifier = Modifier.semantics {
        contentDescription = "Send message"
        role = Role.Button
    }
) {
    Icon(Icons.Filled.Send, contentDescription = null)
}
```

### Minimum Touch Targets

```kotlin
// Ensure 48dp minimum
IconButton(
    onClick = {},
    modifier = Modifier.size(48.dp)
) {
    Icon(Icons.Filled.Send, null)
}
```

---

## 10. Animations & Transitions

### Message Appearance

```kotlin
items(
    items = messages,
    key = { it.id }
) { message ->
    MessageBubble(
        message = message,
        modifier = Modifier.animateItemPlacement(
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
    )
}
```

---

## 11. Material Design 3 Patterns

### Pull-to-Refresh

```kotlin
val pullRefreshState = rememberPullRefreshState(
    refreshing = isRefreshing,
    onRefresh = { viewModel.refresh() }
)

Box(
    modifier = Modifier.pullRefresh(pullRefreshState)
) {
    LazyColumn { /* content */ }

    PullRefreshIndicator(
        refreshing = isRefreshing,
        state = pullRefreshState,
        modifier = Modifier.align(Alignment.TopCenter)
    )
}
```

---

## Conclusion

This UI/UX design leverages Material Design 3 with Jetpack Compose for a modern, accessible, and performant Android experience. The design incorporates Islamic aesthetics through the color palette while following Google's latest design guidelines.
