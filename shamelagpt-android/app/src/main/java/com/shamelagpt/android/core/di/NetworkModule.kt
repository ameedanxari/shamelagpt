package com.shamelagpt.android.core.di

import com.google.gson.Gson
import com.shamelagpt.android.core.network.NetworkMonitor
import com.shamelagpt.android.core.network.RetrofitClient
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.datasource.ChatRemoteDataSource
import com.shamelagpt.android.data.remote.datasource.ChatRemoteDataSourceImpl
import com.shamelagpt.android.data.repository.ChatRepositoryImpl
import com.shamelagpt.android.domain.repository.ChatRepository
import com.shamelagpt.android.domain.usecase.SendMessageUseCase
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

    // Provide Gson
    single<Gson> {
        RetrofitClient.createGson()
    }

    // Provide OkHttpClient
    single<OkHttpClient> {
        // Enable logging in debug builds
        val isDebug = androidContext().applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0
        RetrofitClient.createOkHttpClient(isDebug = isDebug)
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

    // Provide ChatRemoteDataSource
    single<ChatRemoteDataSource> {
        ChatRemoteDataSourceImpl(apiService = get())
    }

    // Provide ChatRepository
    single<ChatRepository> {
        ChatRepositoryImpl(
            chatRemoteDataSource = get(),
            conversationRepository = get()
        )
    }

    // Provide SendMessageUseCase
    factory {
        SendMessageUseCase(
            chatRepository = get(),
            conversationRepository = get()
        )
    }
}
