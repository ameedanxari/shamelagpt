package com.shamelagpt.android.core.network

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import okhttp3.OkHttpClient
import okhttp3.Interceptor
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Factory object for creating Retrofit instances.
 */
object RetrofitClient {

    private const val BASE_URL = "https://shamelagpt.com/"
    private const val TIMEOUT_SECONDS = 30L

    /**
     * Creates a configured OkHttpClient.
     *
     * @param isDebug Whether to enable logging (debug builds)
     * @return Configured OkHttpClient
     */
    fun createOkHttpClient(
        isDebug: Boolean = false,
        extraInterceptors: List<Interceptor> = emptyList()
    ): OkHttpClient {
        val builder = OkHttpClient.Builder()
            .connectTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .writeTimeout(TIMEOUT_SECONDS, TimeUnit.SECONDS)

        extraInterceptors.forEach { builder.addInterceptor(it) }

        // Add logging interceptor for debug builds
        if (isDebug) {
            val loggingInterceptor = HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            }
            builder.addInterceptor(loggingInterceptor)
        }

        return builder.build()
    }

    /**
     * Creates a Gson instance with custom configuration.
     *
     * @return Configured Gson instance
     */
    fun createGson(): Gson {
        return GsonBuilder()
            .setLenient()
            .create()
    }

    /**
     * Creates a Retrofit instance.
     *
     * @param okHttpClient OkHttpClient to use
     * @param gson Gson instance for serialization
     * @return Configured Retrofit instance
     */
    fun createRetrofit(
        okHttpClient: OkHttpClient,
        gson: Gson
    ): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }
}
