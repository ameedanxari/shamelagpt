package com.shamelagpt.android.data.remote.datasource

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

interface AuthRemoteDataSource {
    suspend fun signup(request: SignupRequest): Result<AuthResponse>
    suspend fun login(request: LoginRequest): Result<AuthResponse>
    suspend fun forgotPassword(request: ForgotPasswordRequest): Result<EmptyResponse>
    suspend fun googleSignIn(request: GoogleSignInRequest): Result<AuthResponse>
    suspend fun refreshToken(request: RefreshTokenRequest): Result<AuthResponse>
    suspend fun getCurrentUser(): Result<UserResponse>
    suspend fun updateCurrentUser(request: UpdateUserRequest): Result<UserResponse>
    suspend fun deleteCurrentUser(): Result<EmptyResponse>
    suspend fun verifyToken(): Result<EmptyResponse>
    suspend fun getPreferences(): Result<UserPreferencesRequest>
    suspend fun setPreferences(request: UserPreferencesRequest): Result<EmptyResponse>
}
