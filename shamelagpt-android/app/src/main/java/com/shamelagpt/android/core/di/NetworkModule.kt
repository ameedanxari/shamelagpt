package com.shamelagpt.android.core.di

import com.google.gson.Gson
import com.shamelagpt.android.core.network.NetworkMonitor
import com.shamelagpt.android.core.network.RetrofitClient
import com.shamelagpt.android.core.network.AuthInterceptor
import com.shamelagpt.android.core.preferences.SessionManager
import com.shamelagpt.android.core.preferences.PreferencesCache
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.datasource.AuthRemoteDataSource
import com.shamelagpt.android.data.remote.datasource.AuthRemoteDataSourceImpl
import com.shamelagpt.android.data.remote.datasource.ChatRemoteDataSource
import com.shamelagpt.android.data.remote.datasource.ChatRemoteDataSourceImpl
import com.shamelagpt.android.data.remote.datasource.ConversationRemoteDataSource
import com.shamelagpt.android.data.remote.datasource.ConversationRemoteDataSourceImpl
import com.shamelagpt.android.data.repository.AuthRepositoryImpl
import com.shamelagpt.android.data.repository.ChatRepositoryImpl
import com.shamelagpt.android.data.repository.PreferencesRepositoryImpl
import com.shamelagpt.android.domain.repository.AuthRepository
import com.shamelagpt.android.domain.repository.ChatRepository
import com.shamelagpt.android.domain.usecase.OCRUseCase
import com.shamelagpt.android.domain.usecase.ConfirmFactCheckUseCase
import com.shamelagpt.android.domain.repository.PreferencesRepository
import com.shamelagpt.android.domain.usecase.SendMessageUseCase
import com.shamelagpt.android.domain.usecase.StreamMessageUseCase
import com.shamelagpt.android.core.network.AuthRetryManager
import okhttp3.OkHttpClient
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module
import retrofit2.Retrofit

/**
 * Koin module for networking-related dependencies.
 *
 * Provides:
 * - NetworkMonitor (singleton)
 * - Gson (singleton)
 * - OkHttpClient (singleton)
 * - Retrofit (singleton)
 * - ApiService (singleton)
 * - ChatRemoteDataSource (singleton)
 * - ChatRepository (singleton)
 * - SendMessageUseCase (factory)
 */
val networkModule = module {

    // Provide NetworkMonitor
    single {
        NetworkMonitor(androidContext())
    }

    // Provide SessionManager
    single {
        SessionManager(androidContext())
    }

    // Provide Gson
    single<Gson> {
        RetrofitClient.createGson()
    }

    // Provide OkHttpClient
    single<OkHttpClient> {
        // Enable logging in debug builds
        val isDebug = androidContext().applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0
        val authInterceptor = AuthInterceptor { get<SessionManager>().getToken() }
        RetrofitClient.createOkHttpClient(
            isDebug = isDebug,
            extraInterceptors = listOf(authInterceptor)
        )
    }

    // Provide Retrofit
    single<Retrofit> {
        RetrofitClient.createRetrofit(
            okHttpClient = get(),
            gson = get()
        )
    }

    // Provide ApiService
    single<ApiService> {
        get<Retrofit>().create(ApiService::class.java)
    }

    // Provide AuthRemoteDataSource
    single<AuthRemoteDataSource> {
        AuthRemoteDataSourceImpl(
            apiService = get(),
            authRetryManager = get()
        )
    }

    // Provide AuthRetryManager
    single {
        AuthRetryManager(
            sessionManager = get(),
            apiService = get()
        )
    }

    // Provide ChatRemoteDataSource
    single<ChatRemoteDataSource> {
        ChatRemoteDataSourceImpl(
            apiService = get(),
            authRetryManager = get()
        )
    }

    // Provide ConversationRemoteDataSource
    single<ConversationRemoteDataSource> {
        ConversationRemoteDataSourceImpl(
            apiService = get(),
            authRetryManager = get()
        )
    }

    // Provide ChatRepository
    single<ChatRepository> {
        ChatRepositoryImpl(
            chatRemoteDataSource = get(),
            conversationRepository = get()
        )
    }

    // Provide AuthRepository
    single<AuthRepository> {
        AuthRepositoryImpl(
            authRemoteDataSource = get(),
            sessionManager = get()
        )
    }

    // Provide PreferencesRepository
    single<PreferencesRepository> {
        PreferencesRepositoryImpl(
            authRemoteDataSource = get(),
            gson = get(),
            preferencesCache = PreferencesCache(androidContext())
        )
    }

    // Provide SendMessageUseCase
    factory {
        SendMessageUseCase(
            chatRepository = get(),
            conversationRepository = get()
        )
    }

    // Provide StreamMessageUseCase
    factory {
        StreamMessageUseCase(
            chatRepository = get(),
            conversationRepository = get()
        )
    }

    // Provide OCRUseCase
    factory {
        OCRUseCase(chatRepository = get())
    }

    // Provide ConfirmFactCheckUseCase
    factory {
        ConfirmFactCheckUseCase(chatRepository = get())
    }
}
