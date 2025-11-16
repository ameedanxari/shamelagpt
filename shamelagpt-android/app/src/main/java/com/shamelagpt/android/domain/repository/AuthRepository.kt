package com.shamelagpt.android.domain.repository

import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.data.remote.dto.UpdateUserRequest
import com.shamelagpt.android.data.remote.dto.UserPreferencesRequest
import com.shamelagpt.android.data.remote.dto.UserResponse

interface AuthRepository {
    suspend fun signup(request: SignupRequest): Result<AuthResponse>
    suspend fun login(request: LoginRequest): Result<AuthResponse>
    suspend fun forgotPassword(email: String): Result<Unit>
    suspend fun googleSignIn(idToken: String): Result<AuthResponse>
    suspend fun refreshToken(refreshToken: String): Result<AuthResponse>
    suspend fun getCurrentUser(): Result<UserResponse>
    suspend fun updateCurrentUser(request: UpdateUserRequest): Result<UserResponse>
    suspend fun deleteCurrentUser(): Result<Unit>
    suspend fun verifyToken(): Result<Unit>
    suspend fun getPreferences(): Result<com.shamelagpt.android.data.remote.dto.UserPreferencesRequest>
    suspend fun setPreferences(request: UserPreferencesRequest): Result<Unit>
    fun logout()
    fun getToken(): String?
    fun isLoggedIn(): Boolean
}
