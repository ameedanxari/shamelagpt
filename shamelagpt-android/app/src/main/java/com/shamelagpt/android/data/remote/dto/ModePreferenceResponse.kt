package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

data class ModePreferenceResponse(
    @SerializedName("mode_preference") val modePreference: Int,
    @SerializedName("mode_name") val modeName: String
)
