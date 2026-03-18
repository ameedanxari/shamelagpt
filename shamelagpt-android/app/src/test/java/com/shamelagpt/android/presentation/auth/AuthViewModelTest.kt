package com.shamelagpt.android.presentation.auth

import android.content.Context
import com.shamelagpt.android.R
import com.shamelagpt.android.core.network.NetworkError
import com.shamelagpt.android.data.remote.dto.AuthResponse
import com.shamelagpt.android.data.remote.dto.LoginRequest
import com.shamelagpt.android.domain.repository.AuthRepository
import io.mockk.every
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AuthViewModelTest {

    private lateinit var viewModel: AuthViewModel
    private val authRepository = mockk<AuthRepository>()
    private val appContext = mockk<Context>(relaxed = true)
    private val testDispatcher = UnconfinedTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        every { appContext.getString(R.string.auth_invalid_credentials) } returns
            "Unable to sign in. Check your email and password and try again."
        every { appContext.getString(R.string.auth_email_exists_use_login) } returns
            "This email is already registered. Please sign in."
        viewModel = AuthViewModel(authRepository, appContext)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `when authenticate initiated with valid inputs (login), calls repository and succeeds`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "password"
        val response = AuthResponse("token", "refresh", "3600", com.google.gson.JsonObject())
        
        coEvery { authRepository.login(any()) } returns Result.success(response)

        // When
        viewModel.updateEmail(email)
        viewModel.updatePassword(password)
        
        var successCalled = false
        viewModel.authenticate { successCalled = true }

        // Then
        coVerify { authRepository.login(LoginRequest(email, password)) }
        assertTrue(successCalled)
        assertFalse(viewModel.uiState.value.isLoading)
        assertNull(viewModel.uiState.value.error)
    }
    
    @Test
    fun `when authenticate fails, updates state with error`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "wrong"
        val errorMsg = "Login failed"
        
        coEvery { authRepository.login(any()) } returns Result.failure(Exception(errorMsg))

        // When
        viewModel.updateEmail(email)
        viewModel.updatePassword(password)
        
        var successCalled = false
        viewModel.authenticate { successCalled = true }

        // Then
        assertFalse(successCalled)
        assertFalse(viewModel.uiState.value.isLoading)
        assertNotNull(viewModel.uiState.value.error)
    }

    @Test
    fun `when login fails with invalid credentials, shows human readable error`() = runTest {
        coEvery {
            authRepository.login(any())
        } returns Result.failure(NetworkError.HttpError(401, """{"detail":"Invalid email or password"}"""))

        viewModel.updateEmail("test@example.com")
        viewModel.updatePassword("wrong-password")

        viewModel.authenticate { fail("success callback should not be called") }

        assertEquals(
            "Unable to sign in. Check your email and password and try again.",
            viewModel.uiState.value.error
        )
    }
}
