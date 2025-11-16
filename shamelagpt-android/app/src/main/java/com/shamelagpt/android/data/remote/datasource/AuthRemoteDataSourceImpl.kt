package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.core.network.safeApiCall
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.data.remote.dto.UpdateUserRequest
import com.shamelagpt.android.data.remote.dto.UserPreferencesRequest
import com.shamelagpt.android.data.remote.dto.UserResponse
import com.shamelagpt.android.data.remote.dto.EmptyResponse
import com.shamelagpt.android.data.remote.dto.ForgotPasswordRequest
import com.shamelagpt.android.data.remote.dto.GoogleSignInRequest
import com.shamelagpt.android.data.remote.dto.RefreshTokenRequest

class AuthRemoteDataSourceImpl(
    private val apiService: ApiService,
    private val authRetryManager: com.shamelagpt.android.core.network.AuthRetryManager? = null
) : AuthRemoteDataSource {

    private suspend fun <T> callWithAuth(block: suspend () -> T): Result<T> {
        return safeApiCall(authRetry = { authRetryManager?.trySilentLogin() ?: false }) { block() }
    }

    override suspend fun signup(request: SignupRequest): Result<AuthResponse> = safeApiCall {
        apiService.signup(request)
    }

    override suspend fun login(request: LoginRequest): Result<AuthResponse> = safeApiCall {
        apiService.login(request)
    }

    override suspend fun forgotPassword(request: ForgotPasswordRequest): Result<EmptyResponse> = safeApiCall {
        apiService.forgotPassword(request)
    }

    override suspend fun googleSignIn(request: GoogleSignInRequest): Result<AuthResponse> = safeApiCall {
        apiService.googleSignIn(request)
    }

    override suspend fun refreshToken(request: RefreshTokenRequest): Result<AuthResponse> = safeApiCall {
        apiService.refreshToken(request)
    }

    override suspend fun getCurrentUser(): Result<UserResponse> = callWithAuth {
        apiService.getCurrentUser()
    }

    override suspend fun updateCurrentUser(request: UpdateUserRequest): Result<UserResponse> = callWithAuth {
        apiService.updateCurrentUser(request)
    }

    override suspend fun deleteCurrentUser(): Result<EmptyResponse> = callWithAuth {
        apiService.deleteCurrentUser()
    }

    override suspend fun verifyToken(): Result<EmptyResponse> = callWithAuth {
        apiService.verifyToken()
    }

    override suspend fun getPreferences(): Result<UserPreferencesRequest> = callWithAuth {
        apiService.getPreferences()
    }

    override suspend fun setPreferences(request: UserPreferencesRequest): Result<EmptyResponse> = callWithAuth {
        apiService.setPreferences(request)
    }
}
