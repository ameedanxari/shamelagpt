package com.shamelagpt.android.data.remote.dto

import com.google.gson.annotations.SerializedName

data class ModePreferenceRequest(
    @SerializedName("mode_preference") val modePreference: Int
)
