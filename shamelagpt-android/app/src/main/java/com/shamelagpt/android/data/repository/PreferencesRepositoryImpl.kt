package com.shamelagpt.android.data.repository

import android.util.Log
import com.google.gson.Gson
import com.shamelagpt.android.data.remote.datasource.AuthRemoteDataSource
import com.shamelagpt.android.data.remote.dto.ResponsePreferencesRequest
import com.shamelagpt.android.data.remote.dto.UserPreferencesRequest
import com.shamelagpt.android.domain.model.ResponsePreferences
import com.shamelagpt.android.domain.model.UserPreferences
import com.shamelagpt.android.domain.repository.PreferencesRepository
import com.shamelagpt.android.core.preferences.PreferencesCache
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private const val TAG = "PreferencesRepositoryImpl"

class PreferencesRepositoryImpl(
    private val authRemoteDataSource: AuthRemoteDataSource,
    private val gson: Gson,
    private val preferencesCache: PreferencesCache
) : PreferencesRepository {

    override suspend fun fetchPreferences(): Result<UserPreferences> {
        Log.d(TAG, "fetchPreferences() called")
        // If we have cached preferences, return them immediately and refresh in background
        val cachedJson = preferencesCache.getCachedJson()
        if (!cachedJson.isNullOrBlank()) {
            Log.d(TAG, "Found cached preferences, returning cached value")
            return try {
                val cached = gson.fromJson(cachedJson, UserPreferencesRequest::class.java).toDomain()
                Log.d(TAG, "Cached preferences parsed: language=${cached.languagePreference}")
                // Fire-and-forget refresh to update cache in background
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        Log.d(TAG, "Refreshing preferences in background...")
                        val fresh = authRemoteDataSource.getPreferences().getOrThrow()
                        val freshJson = gson.toJson(fresh)
                        preferencesCache.saveCachedJson(freshJson)
                        Log.d(TAG, "Background refresh completed")
                    } catch (e: Exception) {
                        Log.e(TAG, "Background refresh failed: ${e.message}")
                        // ignore background refresh failures
                    }
                }
                Result.success(cached)
            } catch (e: Exception) {
                Log.e(TAG, "Cache parse failed, falling back to network: ${e.message}")
                // If cache parse fails, fall back to network
                authRemoteDataSource.getPreferences().mapCatching { prefs ->
                    val json = gson.toJson(prefs)
                    preferencesCache.saveCachedJson(json)
                    prefs.toDomain()
                }
            }
        }

        Log.d(TAG, "No cache, fetching from API...")
        val raw = authRemoteDataSource.getPreferences()
        return raw.mapCatching { prefs ->
            val json = gson.toJson(prefs)
            preferencesCache.saveCachedJson(json)
            val domain = prefs.toDomain()
            Log.d(TAG, "Preferences fetched: language=${domain.languagePreference}")
            domain
        }
    }

    override suspend fun updatePreferences(preferences: UserPreferences): Result<Unit> {
        Log.d(TAG, "updatePreferences() called: language=${preferences.languagePreference}")
        val request = preferences.toRequest()
        return authRemoteDataSource.setPreferences(request).map {
            // Received typed empty response — treat as success and update cache
            Log.d(TAG, "Preferences updated on server")
            // Update cache with latest value
            try {
                val json = gson.toJson(request)
                preferencesCache.saveCachedJson(json)
                Log.d(TAG, "Preferences cache updated")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update cache: ${e.message}")
                // ignore cache save failure
            }
            Unit
        }.onFailure {
            Log.e(TAG, "Failed to update preferences: ${it.message}", it)
        }
    }

    private fun UserPreferencesRequest.toDomain(): UserPreferences {
        return UserPreferences(
            languagePreference = languagePreference,
            customSystemPrompt = customSystemPrompt,
            responsePreferences = responsePreferences?.let {
                ResponsePreferences(
                    length = it.length,
                    style = it.style,
                    focus = it.focus
                )
            }
        )
    }

    private fun UserPreferences.toRequest(): UserPreferencesRequest {
        return UserPreferencesRequest(
            languagePreference = languagePreference,
            customSystemPrompt = customSystemPrompt,
            responsePreferences = responsePreferences?.let {
                ResponsePreferencesRequest(
                    length = it.length,
                    style = it.style,
                    focus = it.focus
                )
            }
        )
    }
}
