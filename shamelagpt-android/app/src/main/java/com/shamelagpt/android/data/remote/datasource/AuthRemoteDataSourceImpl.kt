package com.shamelagpt.android.data.remote.datasource

import com.shamelagpt.android.core.network.safeApiCall
import com.shamelagpt.android.data.remote.ApiService
import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.data.remote.dto.UpdateUserRequest
import com.shamelagpt.android.data.remote.dto.UserPreferencesRequest
import com.shamelagpt.android.data.remote.dto.UserResponse
import okhttp3.ResponseBody

class AuthRemoteDataSourceImpl(
    private val apiService: ApiService
) : AuthRemoteDataSource {

    override suspend fun signup(request: SignupRequest): Result<AuthResponse> = safeApiCall {
        apiService.signup(request)
    }

    override suspend fun login(request: LoginRequest): Result<AuthResponse> = safeApiCall {
        apiService.login(request)
    }

    override suspend fun getCurrentUser(): Result<UserResponse> = safeApiCall {
        apiService.getCurrentUser()
    }

    override suspend fun updateCurrentUser(request: UpdateUserRequest): Result<UserResponse> = safeApiCall {
        apiService.updateCurrentUser(request)
    }

    override suspend fun deleteCurrentUser(): Result<ResponseBody> = safeApiCall {
        apiService.deleteCurrentUser()
    }

    override suspend fun verifyToken(): Result<ResponseBody> = safeApiCall {
        apiService.verifyToken()
    }

    override suspend fun getPreferences(): Result<ResponseBody> = safeApiCall {
        apiService.getPreferences()
    }

    override suspend fun setPreferences(request: UserPreferencesRequest): Result<ResponseBody> = safeApiCall {
        apiService.setPreferences(request)
    }
}
