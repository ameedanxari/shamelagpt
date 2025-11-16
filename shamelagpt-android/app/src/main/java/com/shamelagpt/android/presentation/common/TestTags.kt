package com.shamelagpt.android.presentation.common

/**
 * Canonical selector registry for Compose UI tests.
 * Keep names stable and update tests in the same change when modified.
 */
object TestTags {
    object Welcome {
        const val Screen = "welcomeScreen"
        const val Logo = "welcomeLogo"
        const val GetStartedButton = "getStartedButton"
        const val SkipButton = "skipButton"
    }

    object Auth {
        const val Screen = "authScreen"
        const val Title = "authTitle"
        const val EmailField = "emailTextField"
        const val PasswordField = "passwordTextField"
        const val DisplayNameField = "displayNameTextField"
        const val ErrorLabel = "errorLabel"
        const val SignInButton = "signInButton"
        const val SignUpButton = "signUpButton"
        const val ContinueAsGuestButton = "continueAsGuestButton"
        const val ToggleModeButton = "toggleModeButton"
    }

    object Chat {
        const val Screen = "chatScreen"
        const val EmptyState = "emptyState"
        const val MessagesList = "messagesList"
        const val MessageBubble = "messageBubble"
        const val ThinkingBubble = "thinkingBubble"
        const val TypingIndicator = "typingIndicator"
        const val HydrationOverlay = "chatHydrationOverlay"
        const val MessageInputField = "messageInputField"
        const val SendButton = "sendButton"
        const val CameraButton = "cameraButton"
        const val MicButton = "micButton"
        const val ErrorBanner = "chatErrorBanner"
        const val ErrorBannerDismissButton = "chatErrorBannerDismissButton"
    }

    object History {
        const val List = "historyList"
        fun conversationCard(conversationId: String): String = "conversationCard_$conversationId"
    }

    object Settings {
        const val List = "settingsList"
        const val LanguageItem = "settingsLanguageItem"
        const val CustomPromptItem = "settingsCustomPromptItem"
        const val CustomPromptTextField = "customPromptTextField"
        const val LengthItem = "settingLengthItem"
        const val StyleItem = "settingStyleItem"
        const val FocusItem = "settingFocusItem"
        const val SavePreferencesButton = "savePreferencesButton"
        const val SignInButton = "settingsSignInButton"
        const val SupportItem = "settingsSupportItem"
        const val AboutItem = "settingsAboutItem"
        const val LogoutItem = "settingsLogoutItem"
        fun languageOption(code: String): String = "LanguageOption_$code"
        fun languageSelectedCheckmark(code: String): String = "LanguageSelectedCheckmark_$code"
    }
}
