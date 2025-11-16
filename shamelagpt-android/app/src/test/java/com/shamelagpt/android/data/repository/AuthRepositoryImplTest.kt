package com.shamelagpt.android.data.repository

import com.shamelagpt.android.core.preferences.SessionManager
import com.shamelagpt.android.data.remote.datasource.AuthRemoteDataSource
import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.data.remote.dto.SignupRequest
import com.shamelagpt.android.data.remote.dto.EmptyResponse
import com.shamelagpt.android.util.MainCoroutineRule
import io.mockk.coEvery
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test

@ExperimentalCoroutinesApi
class AuthRepositoryImplTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var repository: AuthRepositoryImpl
    private lateinit var authRemoteDataSource: AuthRemoteDataSource
    private lateinit var sessionManager: SessionManager

    @Before
    fun setup() {
        authRemoteDataSource = mockk()
        sessionManager = mockk(relaxed = true)
        repository = AuthRepositoryImpl(authRemoteDataSource, sessionManager)
    }

    @Test
    fun `login success persists session and credentials`() = runTest {
        // Given
        val request = LoginRequest("test@example.com", "password")
        val response = AuthResponse("token", "refresh", "3600", mockk())
        coEvery { authRemoteDataSource.login(request) } returns Result.success(response)

        // When
        val result = repository.login(request)

        // Then
        assertTrue(result.isSuccess)
        assertEquals(response, result.getOrNull())
        verify { sessionManager.saveSession("token", "refresh", 3600L) }
        verify { sessionManager.saveCredentials("test@example.com", "password") }
    }

    @Test
    fun `signup success persists session`() = runTest {
        // Given
        val request = SignupRequest("test@example.com", "password", "Test User")
        val response = AuthResponse("token", "refresh", "3600", mockk())
        coEvery { authRemoteDataSource.signup(request) } returns Result.success(response)

        // When
        val result = repository.signup(request)

        // Then
        assertTrue(result.isSuccess)
        verify { sessionManager.saveSession("token", "refresh", 3600L) }
    }

    @Test
    fun `logout clears session and credentials`() {
        // When
        repository.logout()

        // Then
        verify { sessionManager.clearSession() }
        verify { sessionManager.clearCredentials() }
    }

    @Test
    fun `deleteCurrentUser calls datasource and logouts on success`() = runTest {
        // Given
        coEvery { authRemoteDataSource.deleteCurrentUser() } returns Result.success(EmptyResponse())

        // When
        val result = repository.deleteCurrentUser()

        // Then
        assertTrue(result.isSuccess)
        verify { sessionManager.clearSession() }
        verify { sessionManager.clearCredentials() }
    }
}
