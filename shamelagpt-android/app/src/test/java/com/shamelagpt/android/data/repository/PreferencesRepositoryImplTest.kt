package com.shamelagpt.android.data.repository

import com.google.gson.Gson
import com.shamelagpt.android.core.preferences.PreferencesCache
import com.shamelagpt.android.data.remote.datasource.AuthRemoteDataSource
import com.shamelagpt.android.data.remote.dto.ResponsePreferencesRequest
import com.shamelagpt.android.data.remote.dto.UserPreferencesRequest
import com.shamelagpt.android.data.remote.dto.EmptyResponse
import com.shamelagpt.android.domain.model.UserPreferences
import com.shamelagpt.android.util.MainCoroutineRule
import io.mockk.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test

@ExperimentalCoroutinesApi
class PreferencesRepositoryImplTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var repository: PreferencesRepositoryImpl
    private lateinit var authRemoteDataSource: AuthRemoteDataSource
    private lateinit var preferencesCache: PreferencesCache
    private val gson = Gson()

    @Before
    fun setup() {
        authRemoteDataSource = mockk()
        preferencesCache = mockk(relaxed = true)
        repository = PreferencesRepositoryImpl(authRemoteDataSource, gson, preferencesCache)
    }

    @Test
    fun `fetchPreferences from API when no cache`() = runTest {
        // Given
        val expectedRequest = UserPreferencesRequest(
            languagePreference = "en",
            customSystemPrompt = "Test Prompt",
            responsePreferences = ResponsePreferencesRequest("short", "academic", "practical")
        )
        every { preferencesCache.getCachedJson() } returns null
        coEvery { authRemoteDataSource.getPreferences() } returns Result.success(expectedRequest)

        // When
        val result = repository.fetchPreferences()

        // Then
        assertTrue(result.isSuccess)
        assertEquals("Test Prompt", result.getOrNull()?.customSystemPrompt)
        verify { preferencesCache.saveCachedJson(any()) }
    }

    @Test
    fun `fetchPreferences returns cached value immediately`() = runTest {
        // Given
        val cachedRequest = UserPreferencesRequest(
            languagePreference = "ar",
            customSystemPrompt = "Cached Prompt",
            responsePreferences = null
        )
        val cachedJson = gson.toJson(cachedRequest)
        every { preferencesCache.getCachedJson() } returns cachedJson

        // When
        val result = repository.fetchPreferences()

        // Then
        assertTrue(result.isSuccess)
        assertEquals("Cached Prompt", result.getOrNull()?.customSystemPrompt)
    }

    @Test
    fun `updatePreferences updates API and cache`() = runTest {
        // Given
        val domain = UserPreferences(
            languagePreference = "en",
            customSystemPrompt = "New Prompt"
        )
        coEvery { authRemoteDataSource.setPreferences(any()) } returns Result.success(EmptyResponse())

        // When
        val result = repository.updatePreferences(domain)

        // Then
        assertTrue(result.isSuccess)
        coVerify { authRemoteDataSource.setPreferences(match { it.customSystemPrompt == "New Prompt" }) }
        verify { preferencesCache.saveCachedJson(any()) }
    }
}
