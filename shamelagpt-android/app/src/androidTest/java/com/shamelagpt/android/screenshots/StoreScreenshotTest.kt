package com.shamelagpt.android.screenshots

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.os.Build
import android.text.TextUtils
import android.view.ContextThemeWrapper
import androidx.activity.ComponentActivity
import androidx.compose.material3.Surface
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.core.view.drawToBitmap
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.model.Source
import com.shamelagpt.android.presentation.auth.AuthScreen
import com.shamelagpt.android.presentation.auth.AuthUiState
import com.shamelagpt.android.presentation.auth.AuthViewModel
import com.shamelagpt.android.presentation.chat.ChatEvent
import com.shamelagpt.android.presentation.chat.ChatScreen
import com.shamelagpt.android.presentation.chat.ChatUiState
import com.shamelagpt.android.presentation.settings.SettingsScreen
import com.shamelagpt.android.presentation.history.HistoryScreen
import com.shamelagpt.android.presentation.welcome.WelcomeScreen
import com.shamelagpt.android.presentation.theme.ShamelaGPTTheme
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.io.FileOutputStream
import java.util.Locale

@LargeTest
@RunWith(AndroidJUnit4::class)
class StoreScreenshotTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()
    private var localeContext: Context? = null

    private data class Scenario(
        val id: String,
        val locale: String,
        val screen: Screen,
        val uiState: ChatUiState? = null,
        val authUiState: AuthUiState? = null,
        val isDark: Boolean = false
    )

    private enum class Screen { Chat, Settings, History, Welcome, Auth }

    private val baseScenarios = listOf(
        Scenario(id = "chat_happy", locale = "en", screen = Screen.Chat, uiState = happyChatState("en")),
        Scenario(id = "chat_happy", locale = "ar", screen = Screen.Chat, uiState = happyChatState("ar")),
        Scenario(id = "chat_happy", locale = "ur", screen = Screen.Chat, uiState = happyChatState("ur")),
        Scenario(id = "chat_error", locale = "en", screen = Screen.Chat, uiState = errorChatState("en")),
        Scenario(id = "chat_error", locale = "ar", screen = Screen.Chat, uiState = errorChatState("ar")),
        Scenario(id = "chat_error", locale = "ur", screen = Screen.Chat, uiState = errorChatState("ur")),
        Scenario(id = "settings_main", locale = "en", screen = Screen.Settings),
        Scenario(id = "settings_main", locale = "ar", screen = Screen.Settings),
        Scenario(id = "settings_main", locale = "ur", screen = Screen.Settings),
        Scenario(id = "history_list", locale = "en", screen = Screen.History),
        Scenario(id = "history_list", locale = "ar", screen = Screen.History),
        Scenario(id = "history_list", locale = "ur", screen = Screen.History),
        Scenario(id = "welcome_main", locale = "en", screen = Screen.Welcome),
        Scenario(id = "welcome_main", locale = "ar", screen = Screen.Welcome),
        Scenario(id = "welcome_main", locale = "ur", screen = Screen.Welcome),
        Scenario(id = "auth_login", locale = "en", screen = Screen.Auth, authUiState = loginAuthState("en")),
        Scenario(id = "auth_login", locale = "ar", screen = Screen.Auth, authUiState = loginAuthState("ar")),
        Scenario(id = "auth_login", locale = "ur", screen = Screen.Auth, authUiState = loginAuthState("ur")),
        Scenario(id = "auth_signup", locale = "en", screen = Screen.Auth, authUiState = signupAuthState("en")),
        Scenario(id = "auth_signup", locale = "ar", screen = Screen.Auth, authUiState = signupAuthState("ar")),
        Scenario(id = "auth_signup", locale = "ur", screen = Screen.Auth, authUiState = signupAuthState("ur")),
        Scenario(id = "auth_error", locale = "en", screen = Screen.Auth, authUiState = authErrorState("en")),
        Scenario(id = "auth_error", locale = "ar", screen = Screen.Auth, authUiState = authErrorState("ar")),
        Scenario(id = "auth_error", locale = "ur", screen = Screen.Auth, authUiState = authErrorState("ur"))
    )

    private val scenarios = baseScenarios.flatMap { scenario ->
        listOf(
            scenario,
            scenario.copy(isDark = true)
        )
    }

    private val mockEvents = MutableSharedFlow<ChatEvent>(extraBufferCapacity = 1)

    @Test
    fun captureStoreScreenshots() {
        val device = (System.getenv("SCREENSHOT_DEVICE") ?: Build.MODEL ?: "android").replace(" ", "_")
        val instrumentationArgs = InstrumentationRegistry.getArguments()
        val localeFilter = instrumentationArgs.getString("locale") ?: System.getProperty("locale")
        val baseDir = instrumentationArgs.getString("additionalTestOutputDir")
            ?.let { File(it).resolve("screenshots").absolutePath }
            ?: System.getenv("SCREENSHOT_OUTPUT_DIR")
            ?: composeRule.activity.getExternalFilesDir("screenshots")?.absolutePath
            ?: composeRule.activity.filesDir.resolve("screenshots").absolutePath
        val activeScenarios = scenarios.filter { localeFilter == null || it.locale == localeFilter }
        val scenarioState = mutableStateOf(activeScenarios.first())
        setLocale(scenarioState.value.locale, scenarioState.value.isDark)

        composeRule.setContent {
            val scenario = scenarioState.value
            val isRtl = scenario.locale.lowercase() in listOf("ar", "ur", "fa")
            val scenarioContext = localeContext ?: composeRule.activity
            ShamelaGPTTheme(darkTheme = scenario.isDark) {
                val direction = if (isRtl) LayoutDirection.Rtl else LayoutDirection.Ltr
                CompositionLocalProvider(
                    LocalLayoutDirection provides direction,
                    LocalContext provides scenarioContext
                ) {
                    Surface {
                        when (scenario.screen) {
                            Screen.Chat -> scenario.uiState?.let { ui ->
                                ChatScreen(viewModel = mockChatViewModel(ui))
                            }
                            Screen.Settings -> SettingsScreen(
                                isAuthenticated = true,
                                onNavigateToLanguage = {},
                                onNavigateToAbout = {},
                                onNavigateToAuth = {},
                                onLogout = {},
                                viewModel = mockSettingsViewModel(scenario.locale)
                            )
                            Screen.History -> HistoryScreen(
                                isAuthenticated = true,
                                onNavigateToChat = {},
                                onNavigateToAuth = {},
                                viewModel = mockHistoryViewModel(scenario.locale)
                            )
                            Screen.Welcome -> WelcomeScreen(
                                onGetStarted = {},
                                onSkipToChat = {}
                            )
                            Screen.Auth -> scenario.authUiState?.let { authState ->
                                AuthScreen(
                                    onAuthenticated = {},
                                    onContinueAsGuest = {},
                                    viewModel = mockAuthViewModel(authState)
                                )
                            }
                        }
                    }
                }
            }
        }

        activeScenarios.forEach { scenario ->
            setLocale(scenario.locale, scenario.isDark)
            scenarioState.value = scenario

            composeRule.waitForIdle()
            val image = captureScenarioBitmap()
            val dir = File(baseDir, "$device/${scenario.locale}/${scenario.screen.name.lowercase()}")
            dir.mkdirs()
            val suffix = if (scenario.isDark) "_dark" else ""
            val file = File(dir, "${scenario.id}$suffix.png")
            saveImage(image, file)
        }
    }

    private fun mockChatViewModel(state: ChatUiState): com.shamelagpt.android.presentation.chat.ChatViewModel {
        val vm = mockk<com.shamelagpt.android.presentation.chat.ChatViewModel>(relaxed = true)
        val stateFlow = MutableStateFlow(state)
        every { vm.uiState } returns stateFlow
        every { vm.events } returns mockEvents
        return vm
    }

    private fun mockSettingsViewModel(locale: String): com.shamelagpt.android.presentation.settings.SettingsViewModel {
        val vm = mockk<com.shamelagpt.android.presentation.settings.SettingsViewModel>(relaxed = true)
        val langFlow = MutableStateFlow(locale)
        val authFlow = MutableStateFlow(true)
        val promptFlow = MutableStateFlow(
            when (locale) {
                "ar" -> "قدّم خلاصة عملية أولاً، ثم اذكر الدليل من كتب التراث مع التنبيه على صحة الحديث عند الحاجة."
                "ur" -> "پہلے عملی خلاصہ دیں، پھر معتبر کتب کے حوالہ جات کے ساتھ مختصر توضیح پیش کریں۔"
                else -> "Start with a practical summary, then cite classical sources and note hadith grading when relevant."
            }
        )
        val prefsFlow = MutableStateFlow(
            com.shamelagpt.android.domain.model.ResponsePreferences(
                length = "detailed",
                style = "academic",
                focus = "evidence_first"
            )
        )
        every { vm.selectedLanguage } returns langFlow
        every { vm.isAuthenticated } returns authFlow
        every { vm.customPrompt } returns promptFlow
        every { vm.responsePreferences } returns prefsFlow
        return vm
    }

    private fun mockHistoryViewModel(locale: String): com.shamelagpt.android.presentation.history.HistoryViewModel {
        val vm = mockk<com.shamelagpt.android.presentation.history.HistoryViewModel>(relaxed = true)
        val mockConversations = listOf(
            com.shamelagpt.android.domain.model.Conversation(
                id = "1",
                title = when (locale) {
                    "ar" -> "أشراط الساعة: الفرق بين العلامات الصغرى والكبرى"
                    "ur" -> "قیامت کی نشانیاں: صغریٰ اور کبریٰ میں فرق"
                    else -> "Signs of the Hour: Difference Between Minor and Major"
                },
                createdAt = System.currentTimeMillis() - 7200000,
                updatedAt = System.currentTimeMillis() - 3600000,
                messages = emptyList()
            ),
            com.shamelagpt.android.domain.model.Conversation(
                id = "2",
                title = when (locale) {
                    "ar" -> "صفة الوضوء مع السنن والأخطاء الشائعة"
                    "ur" -> "وضو کا مسنون طریقہ اور عام غلطیاں"
                    else -> "Wudu Guide: Sunnah Steps and Common Mistakes"
                },
                createdAt = System.currentTimeMillis() - 172800000,
                updatedAt = System.currentTimeMillis() - 86400000,
                messages = emptyList()
            ),
            com.shamelagpt.android.domain.model.Conversation(
                id = "3",
                title = when (locale) {
                    "ar" -> "زكاة المال: النصاب، الحول، وطريقة الحساب"
                    "ur" -> "زکوٰۃ المال: نصاب، سال کی شرط اور حساب"
                    else -> "Zakat al-Mal: Nisab, Hawl, and Step-by-Step Calculation"
                },
                createdAt = System.currentTimeMillis() - 604800000,
                updatedAt = System.currentTimeMillis() - 345600000,
                messages = emptyList()
            )
        )
        val uiState = com.shamelagpt.android.presentation.history.HistoryUiState(
            conversations = mockConversations,
            isLoading = false
        )
        val stateFlow = MutableStateFlow(uiState)
        every { vm.uiState } returns stateFlow
        return vm
    }

    private fun mockWelcomeViewModel(): com.shamelagpt.android.presentation.welcome.WelcomeViewModel {
        val vm = mockk<com.shamelagpt.android.presentation.welcome.WelcomeViewModel>(relaxed = true)
        return vm
    }

    private fun happyChatState(locale: String): ChatUiState {
        val now = System.currentTimeMillis()
        val question = when (locale) {
            "ar" -> "لدي مدخرات واستثمارات متفرقة، كيف أحسب زكاة المال بدقة بطريقة عملية؟"
            "ur" -> "میرے پاس بچت اور مختلف سرمایہ کاری ہے، زکوٰۃ المال صحیح طور پر کیسے نکالوں؟"
            else -> "I have savings and mixed investments. What is a practical way to calculate Zakat al-Mal accurately?"
        }
        val answer = when (locale) {
            "ar" -> "اجمع جميع الأموال الزكوية أولاً (النقد، الذهب/الفضة، عروض التجارة، الأسهم المعدّة للتداول). ثم اطرح الديون المستحقة خلال الفترة القريبة. إذا بلغ الصافي نصاب الذهب ومرّ عليه الحول القمري فأخرج 2.5٪. في المحافظ المختلطة: زكِّ الجزء النقدي والتجاري كاملاً، وأما الاستثمار الطويل فبحسب العائد أو التقييم السنوي المعتمد عندك."
            "ur" -> "پہلے تمام قابلِ زکوٰۃ اموال جمع کریں (نقدی، سونا/چاندی، تجارتی مال، ٹریڈنگ شیئرز)۔ پھر قریب الادا واجب قرض منہا کریں۔ اگر خالص مال نصاب تک پہنچ جائے اور قمری سال گزر جائے تو 2.5٪ زکوٰۃ ادا کریں۔ مکس پورٹ فولیو میں نقدی اور تجارتی حصے کی مکمل زکوٰۃ نکالیں، جبکہ طویل مدتی سرمایہ کاری میں اپنے مسلک کے مطابق سالانہ اندازہ یا منافع کے اصول پر عمل کریں۔"
            else -> "Start by summing all zakatable assets (cash, gold/silver, trading inventory, and trade-intent stocks). Subtract short-term payable debts. If the net value is at or above nisab for one lunar year, pay 2.5%. For mixed portfolios, treat cash and trading positions as fully zakatable; long-term holdings can be handled using your adopted fiqh method (annual valuation or yield-based approach)."
        }
        val inputHint = when (locale) {
            "ar" -> "هل تعطيني مثالًا رقمية بمبلغ 120,000 ريال؟"
            "ur" -> "کیا 120,000 کی مثال کے ساتھ حساب دکھا سکتے ہیں؟"
            else -> "Can you show a worked example for a portfolio worth 120,000?"
        }
        return ChatUiState(
            messages = listOf(
                Message(id = "u1", content = question, isUserMessage = true, timestamp = now - 14_000),
                Message(
                    id = "a1",
                    content = answer,
                    isUserMessage = false,
                    timestamp = now - 4_000,
                    sources = listOf(
                        Source(
                            bookName = when (locale) {
                                "ar" -> "ابن قدامة - المغني (كتاب الزكاة)"
                                "ur" -> "ابن قدامہ - المغنی (کتاب الزکوٰۃ)"
                                else -> "Ibn Qudamah - Al-Mughni (Book of Zakat)"
                            },
                            sourceURL = "https://shamela.ws/book/8463"
                        ),
                        Source(
                            bookName = when (locale) {
                                "ar" -> "القرضاوي - فقه الزكاة"
                                "ur" -> "یوسف القرضاوی - فقہ الزکوٰۃ"
                                else -> "Yusuf al-Qaradawi - Fiqh al-Zakat"
                            },
                            sourceURL = "https://shamela.ws/book/12785"
                        )
                    )
                )
            ),
            inputText = inputHint,
            isLoading = false,
            conversationId = "store-shot",
            threadId = "thread-store"
        )
    }

    private fun loginAuthState(locale: String): AuthUiState {
        val email = when (locale) {
            "ar" -> "support.ar@shamela.app"
            "ur" -> "support.ur@shamela.app"
            else -> "support@shamela.app"
        }
        return AuthUiState(
            email = email,
            password = "••••••••",
            displayName = "",
            isLoginMode = true,
            isLoading = false,
            error = null
        )
    }

    private fun signupAuthState(locale: String): AuthUiState {
        val displayName = when (locale) {
            "ar" -> "عبدالله السلمي"
            "ur" -> "عبداللہ خان"
            else -> "Abdullah Khan"
        }
        return AuthUiState(
            email = "abdullah.khan@shamela.app",
            password = "••••••••",
            displayName = displayName,
            isLoginMode = false,
            isLoading = false,
            error = null
        )
    }

    private fun mockAuthViewModel(state: AuthUiState): AuthViewModel {
        val vm = mockk<AuthViewModel>(relaxed = true)
        val stateFlow = MutableStateFlow(state)
        every { vm.uiState } returns stateFlow
        return vm
    }

    private fun authErrorState(locale: String): AuthUiState {
        val email = when (locale) {
            "ar" -> "support.ar@shamela.app"
            "ur" -> "support.ur@shamela.app"
            else -> "support@shamela.app"
        }
        val error = formattedError(
            locale = locale,
            message = localizedNoConnectionMessage(locale),
            code = "E-NET-003"
        )
        return AuthUiState(
            email = email,
            password = "••••••••",
            displayName = "",
            isLoginMode = true,
            isLoading = false,
            error = error
        )
    }

    private fun errorChatState(locale: String): ChatUiState {
        val now = System.currentTimeMillis()
        val prompt = when (locale) {
            "ar" -> "أعد المحاولة من فضلك، هناك مشكلة في الاتصال"
            "ur" -> "براہ کرم دوبارہ کوشش کریں، کنکشن میں مسئلہ ہے"
            else -> "Please check connection"
        }
        val error = formattedError(
            locale = locale,
            message = localizedServerErrorMessage(locale),
            code = "E-SRV-500"
        )
        return ChatUiState(
            messages = listOf(
                Message(
                    id = "u1",
                    content = prompt,
                    isUserMessage = true,
                    timestamp = now - 2_000
                )
            ),
            inputText = "",
            isLoading = false,
            error = error
        )
    }

    private fun formattedError(locale: String, message: String, code: String): String {
        val codeLabel = when (locale) {
            "ar" -> "رمز الخطأ: $code"
            "ur" -> "خرابی کا کوڈ: $code"
            else -> "Error code: $code"
        }
        val supportSuffix = when (locale) {
            "ar" -> "إذا بدا هذا غير متوقع، يرجى هز جهازك أو الذهاب إلى الإعدادات للإبلاغ لفريق الدعم الخاص بنا."
            "ur" -> "اگر یہ غیر متوقع لگتا ہے، تو اپنے ڈیوائس کو ہلائیں یا ہماری سپورٹ ٹیم کو رپورٹ کرنے کے لیے سیٹنگز پر جائیں۔"
            else -> "If this seems unexpected, please shake your device or go to Settings to report to our support team."
        }
        return "$message $codeLabel. $supportSuffix"
    }

    private fun localizedNoConnectionMessage(locale: String): String {
        return when (locale) {
            "ar" -> "لا يوجد اتصال بالإنترنت. يرجى التحقق من إعدادات الشبكة."
            "ur" -> "انٹرنیٹ کنکشن نہیں۔ براہ کرم نیٹ ورک سیٹنگز چیک کریں۔"
            else -> "No internet connection. Please check your network settings."
        }
    }

    private fun localizedServerErrorMessage(locale: String): String {
        return when (locale) {
            "ar" -> "خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً."
            "ur" -> "سرور میں خرابی ہے۔ براہ کرم بعد میں کوشش کریں۔"
            else -> "Server error. Please try again later."
        }
    }

    private fun saveImage(bitmap: Bitmap, file: File) {
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
    }

    private fun captureScenarioBitmap(): Bitmap {
        repeat(2) { attempt ->
            try {
                return composeRule.onRoot().captureToImage().asAndroidBitmap()
            } catch (_: Throwable) {
                composeRule.waitForIdle()
                if (attempt == 1) {
                    // fall through to fallback
                }
            }
        }
        return composeRule.runOnIdle {
            val rootView = composeRule.activity.findViewById<android.view.View>(android.R.id.content)
            rootView.drawToBitmap()
        }
    }

    private fun setLocale(tag: String, isDark: Boolean = false) {
        val locale = Locale.forLanguageTag(tag)
        Locale.setDefault(locale)
        composeRule.activityRule.scenario.onActivity { activity ->
            val config = Configuration(activity.resources.configuration)
            config.setLocale(locale)
            config.setLayoutDirection(locale)
            config.uiMode = (config.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                if (isDark) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
            localeContext = ContextThemeWrapper(activity, activity.theme).apply {
                applyOverrideConfiguration(config)
            }
            activity.window?.decorView?.layoutDirection = if (
                TextUtils.getLayoutDirectionFromLocale(locale) == android.view.View.LAYOUT_DIRECTION_RTL
            ) android.view.View.LAYOUT_DIRECTION_RTL else android.view.View.LAYOUT_DIRECTION_LTR
        }
    }
}
