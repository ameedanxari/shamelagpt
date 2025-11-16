package com.shamelagpt.android

import android.app.Application
import android.content.Context
import android.util.Log
import com.shamelagpt.android.core.di.databaseModule
import com.shamelagpt.android.core.di.networkModule
import com.shamelagpt.android.core.di.presentationModule
import com.shamelagpt.android.core.preferences.PreferencesManager
import com.shamelagpt.android.core.util.LocaleContextWrapper
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.context.startKoin
import org.koin.core.logger.Level

private const val TAG = "ShamelaGPTApplication"

class ShamelaGPTApplication : Application() {
    override fun attachBaseContext(base: Context) {
        Log.d(TAG, "attachBaseContext() called")
        // Apply saved language to base context as a fallback for older Android versions
        val prefs = PreferencesManager(base)
        val language = prefs.getSelectedLanguage()
        Log.d(TAG, "attachBaseContext: retrieved language from preferences: $language")
        val wrapped = LocaleContextWrapper.wrap(base, language)
        Log.d(TAG, "attachBaseContext: wrapped context with locale: $language")
        super.attachBaseContext(wrapped)
        Log.d(TAG, "attachBaseContext() completed")
    }

    override fun onCreate() {
        Log.d(TAG, "onCreate() called")
        super.onCreate()

        // Initialize Koin
        Log.d(TAG, "Initializing Koin...")
        startKoin {
            androidLogger(Level.ERROR)
            androidContext(this@ShamelaGPTApplication)
            modules(
                databaseModule,
                networkModule,
                presentationModule
            )
        }
        Log.d(TAG, "Koin initialized")

        // Apply saved app language (if any) after Koin starts so LanguageManager is available
        try {
            Log.d(TAG, "Retrieving LanguageManager from Koin...")
            val languageManager = org.koin.java.KoinJavaComponent.get(com.shamelagpt.android.core.util.LanguageManager::class.java) as com.shamelagpt.android.core.util.LanguageManager
            Log.d(TAG, "LanguageManager retrieved, calling applySavedLanguage()...")
            languageManager.applySavedLanguage()
            Log.d(TAG, "applySavedLanguage() completed")
        } catch (t: Throwable) {
            Log.e(TAG, "Error applying saved language: ${t.message}", t)
            // If language manager isn't available for some reason, ignore and continue
        }
        Log.d(TAG, "onCreate() completed")
    }
}
