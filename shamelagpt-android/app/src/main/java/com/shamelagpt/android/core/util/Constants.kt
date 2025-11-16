package com.shamelagpt.android.core.util

object Constants {
    // API Constants
    const val BASE_URL = "https://api.shamelagpt.com/"
    const val API_TIMEOUT = 30L // seconds

    // Database Constants
    const val DATABASE_NAME = "shamela_gpt_database"
    const val DATABASE_VERSION = 1

    // SharedPreferences Keys
    const val PREFS_NAME = "shamela_gpt_prefs"
    const val KEY_IS_FIRST_LAUNCH = "is_first_launch"
    const val KEY_USER_TOKEN = "user_token"
    const val KEY_THEME_MODE = "theme_mode"

    // App Constants
    const val APP_NAME = "ShamelaGPT"
    const val MAX_MESSAGE_LENGTH = 2000
    const val MAX_HISTORY_ITEMS = 100

    // Error Messages
    const val ERROR_NETWORK = "Network error occurred. Please check your connection."
    const val ERROR_UNKNOWN = "An unknown error occurred. Please try again."
    const val ERROR_TIMEOUT = "Request timed out. Please try again."
    const val ERROR_SERVER = "Server error. Please try again later."
}
