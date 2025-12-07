package com.shamelagpt.android.data.repository

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

class PreferencesRepositoryImpl(
    private val authRemoteDataSource: AuthRemoteDataSource,
    private val gson: Gson,
    private val preferencesCache: PreferencesCache
) : PreferencesRepository {

    override suspend fun fetchPreferences(): Result<UserPreferences> {
        // If we have cached preferences, return them immediately and refresh in background
        val cachedJson = preferencesCache.getCachedJson()
        if (!cachedJson.isNullOrBlank()) {
            return try {
                val cached = gson.fromJson(cachedJson, UserPreferencesRequest::class.java).toDomain()
                // Fire-and-forget refresh to update cache in background
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val raw = authRemoteDataSource.getPreferences()
                        val freshJson = raw.string()
                        preferencesCache.saveCachedJson(freshJson)
                    } catch (_: Exception) {
                        // ignore background refresh failures
                    }
                }
                Result.success(cached)
            } catch (e: Exception) {
                // If cache parse fails, fall back to network
                authRemoteDataSource.getPreferences().mapCatching { body ->
                    val json = body.string()
                    preferencesCache.saveCachedJson(json)
                    gson.fromJson(json, UserPreferencesRequest::class.java).toDomain()
                }
            }
        }

        val raw = authRemoteDataSource.getPreferences()
        return raw.mapCatching { body ->
            val json = body.string()
            preferencesCache.saveCachedJson(json)
            gson.fromJson(json, UserPreferencesRequest::class.java).toDomain()
        }
    }

    override suspend fun updatePreferences(preferences: UserPreferences): Result<Unit> {
        val request = preferences.toRequest()
        return authRemoteDataSource.setPreferences(request).map {
            // Update cache with latest value
            try {
                val json = gson.toJson(request)
                preferencesCache.saveCachedJson(json)
            } catch (_: Exception) {
                // ignore cache save failure
            }
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
