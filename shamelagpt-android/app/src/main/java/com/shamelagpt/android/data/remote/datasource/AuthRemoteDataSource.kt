package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.data.remote.dto.UpdateUserRequest
import com.shamelagpt.android.data.remote.dto.UserPreferencesRequest
import com.shamelagpt.android.data.remote.dto.UserResponse
import okhttp3.ResponseBody

interface AuthRemoteDataSource {
    suspend fun signup(request: SignupRequest): Result<AuthResponse>
    suspend fun login(request: LoginRequest): Result<AuthResponse>
    suspend fun getCurrentUser(): Result<UserResponse>
    suspend fun updateCurrentUser(request: UpdateUserRequest): Result<UserResponse>
    suspend fun deleteCurrentUser(): Result<ResponseBody>
    suspend fun verifyToken(): Result<ResponseBody>
    suspend fun getPreferences(): Result<ResponseBody>
    suspend fun setPreferences(request: UserPreferencesRequest): Result<ResponseBody>
}
