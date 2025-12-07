package com.shamelagpt.android.core.di

import com.shamelagpt.android.core.preferences.PreferencesManager
import com.shamelagpt.android.core.util.LanguageManager
import com.shamelagpt.android.core.util.OCRManager
import com.shamelagpt.android.core.util.VoiceInputManager
import com.shamelagpt.android.domain.usecase.DeleteConversationUseCase
import com.shamelagpt.android.domain.usecase.GetConversationsUseCase
import com.shamelagpt.android.presentation.chat.ChatViewModel
import com.shamelagpt.android.presentation.history.HistoryViewModel
import com.shamelagpt.android.presentation.settings.SettingsViewModel
import com.shamelagpt.android.presentation.welcome.WelcomeViewModel
import com.shamelagpt.android.presentation.auth.AuthViewModel
import org.koin.android.ext.koin.androidContext
import org.koin.androidx.viewmodel.dsl.viewModel
import org.koin.dsl.module

/**
 * Koin module for presentation layer dependencies (ViewModels and Use Cases).
 *
 * Provides:
 * - ChatViewModel
 * - HistoryViewModel
 * - SettingsViewModel
 * - WelcomeViewModel
 * - VoiceInputManager
 * - OCRManager
 * - PreferencesManager
 * - LanguageManager
 * - Use Cases
 */
val presentationModule = module {

    // Preferences Manager
    single {
        PreferencesManager(androidContext())
    }

    // Language Manager
    single {
        LanguageManager(
            context = androidContext(),
            preferencesManager = get()
        )
    }

    // Voice Input Manager
    single {
        VoiceInputManager(androidContext())
    }

    // OCR Manager
    single {
        OCRManager(androidContext())
    }

    // Use Cases
    factory {
        GetConversationsUseCase(conversationRepository = get())
    }

    factory {
        DeleteConversationUseCase(conversationRepository = get())
    }

    // ChatViewModel
    viewModel {
        ChatViewModel(
            sendMessageUseCase = get(),
            conversationRepository = get(),
            voiceInputManager = get(),
            ocrManager = get(),
            context = androidContext()
        )
    }

    // HistoryViewModel
    viewModel {
        HistoryViewModel(
            getConversationsUseCase = get(),
            deleteConversationUseCase = get()
        )
    }

    // SettingsViewModel
    viewModel {
        SettingsViewModel(
            languageManager = get(),
            authRepository = get(),
            preferencesRepository = get()
        )
    }

    // WelcomeViewModel
    viewModel {
        WelcomeViewModel(
            preferencesManager = get()
        )
    }

    // AuthViewModel
    viewModel {
        AuthViewModel(
            authRepository = get()
        )
    }
}
