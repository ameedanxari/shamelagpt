package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Request model for Google Sign-In.
 *
 * @property idToken Google ID token obtained from Google Sign-In SDK
 */
data class GoogleSignInRequest(
    @SerializedName("id_token")
    val idToken: String
)
