package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

data class MadhabPreferenceResponse(
    @SerializedName("madhab_preference")
    val madhabPreference: String,
    @SerializedName("madhab_name")
    val madhabName: String? = null,
    val status: String? = null,
    val message: String? = null
)
