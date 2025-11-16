package com.shamelagpt.android.data.remote.dto

/**
 * Data transfer object for health check API responses.
 *
 * @property status Health status (e.g., "healthy", "ok")
 * @property service Service name
 */
data class HealthResponse(
    val status: String,
    val service: String
)
