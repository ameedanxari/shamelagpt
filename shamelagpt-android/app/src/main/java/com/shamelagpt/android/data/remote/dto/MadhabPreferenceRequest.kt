package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

data class MadhabPreferenceRequest(
    @SerializedName("madhab_preference")
    val madhabPreference: String
)
