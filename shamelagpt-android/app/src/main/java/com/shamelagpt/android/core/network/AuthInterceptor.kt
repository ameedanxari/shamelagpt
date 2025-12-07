package com.shamelagpt.android.core.network

import okhttp3.Interceptor
import okhttp3.Response

/**
 * OkHttp interceptor that injects the bearer token if available.
 */
class AuthInterceptor(
    private val tokenProvider: () -> String?
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()
        val token = tokenProvider()

        if (token.isNullOrBlank()) {
            return chain.proceed(original)
        }

        val requestWithAuth = original.newBuilder()
            .addHeader("Authorization", "Bearer $token")
            .build()
        return chain.proceed(requestWithAuth)
    }
}
