package com.shamelagpt.android.data.repository

import com.shamelagpt.android.core.preferences.SessionManager
import com.shamelagpt.android.data.remote.datasource.AuthRemoteDataSource
import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.data.remote.dto.UpdateUserRequest
import com.shamelagpt.android.data.remote.dto.UserPreferencesRequest
import com.shamelagpt.android.data.remote.dto.UserResponse
import com.shamelagpt.android.data.remote.dto.ForgotPasswordRequest
import com.shamelagpt.android.data.remote.dto.GoogleSignInRequest
import com.shamelagpt.android.data.remote.dto.RefreshTokenRequest
import com.shamelagpt.android.domain.repository.AuthRepository

class AuthRepositoryImpl(
    private val authRemoteDataSource: AuthRemoteDataSource,
    private val sessionManager: SessionManager
) : AuthRepository {

    override suspend fun signup(request: SignupRequest): Result<AuthResponse> {
        val result = authRemoteDataSource.signup(request)
        result.onSuccess { persistSession(it) }
        return result
    }

    override suspend fun login(request: LoginRequest): Result<AuthResponse> {
        val result = authRemoteDataSource.login(request)
        result.onSuccess { authResponse ->
            persistSession(authResponse)
            sessionManager.saveCredentials(request.email, request.password)
        }
        return result
    }

    override suspend fun forgotPassword(email: String): Result<Unit> {
        return authRemoteDataSource.forgotPassword(ForgotPasswordRequest(email)).map { }
    }

    override suspend fun googleSignIn(idToken: String): Result<AuthResponse> {
        val result = authRemoteDataSource.googleSignIn(GoogleSignInRequest(idToken))
        result.onSuccess { persistSession(it) }
        return result
    }

    override suspend fun refreshToken(refreshToken: String): Result<AuthResponse> {
        val result = authRemoteDataSource.refreshToken(RefreshTokenRequest(refreshToken))
        result.onSuccess { persistSession(it) }
        return result
    }

    override suspend fun getCurrentUser(): Result<UserResponse> {
        return authRemoteDataSource.getCurrentUser()
    }

    override suspend fun updateCurrentUser(request: UpdateUserRequest): Result<UserResponse> {
        return authRemoteDataSource.updateCurrentUser(request)
    }

    override suspend fun deleteCurrentUser(): Result<Unit> {
        val result = authRemoteDataSource.deleteCurrentUser()
        result.onSuccess { logout() }
        return result.map { }
    }

    override suspend fun verifyToken(): Result<Unit> {
        return authRemoteDataSource.verifyToken().map { }
    }

    override suspend fun getPreferences(): Result<com.shamelagpt.android.data.remote.dto.UserPreferencesRequest> {
        return authRemoteDataSource.getPreferences()
    }

    override suspend fun setPreferences(request: UserPreferencesRequest): Result<Unit> {
        return authRemoteDataSource.setPreferences(request).map { }
    }

    override fun logout() {
        sessionManager.clearSession()
        sessionManager.clearCredentials()
    }

    override fun getToken(): String? = sessionManager.getToken()

    override fun isLoggedIn(): Boolean = sessionManager.isLoggedIn()

    private fun persistSession(response: AuthResponse) {
        // expiresIn is string per API; try to parse to Long seconds
        val expiresInSeconds = response.expiresIn.toLongOrNull()
        sessionManager.saveSession(
            token = response.token,
            refreshToken = response.refreshToken,
            expiresInSeconds = expiresInSeconds
        )
    }
}
