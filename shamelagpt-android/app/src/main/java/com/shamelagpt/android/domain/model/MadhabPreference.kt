package com.shamelagpt.android.domain.model

object MadhabPreference {
    const val ALL = "all"
    const val HANAFI = "hanafi"
    const val MALIKI = "maliki"
    const val SHAFII = "shafii"
    const val HANBALI = "hanbali"

    val VALUES = listOf(ALL, HANAFI, MALIKI, SHAFII, HANBALI)

    fun normalize(raw: String?): String {
        val value = raw?.trim()?.lowercase().orEmpty()
        return if (value in VALUES) value else ALL
    }
}
