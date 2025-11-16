package com.shamelagpt.android

import android.app.Application
import com.shamelagpt.android.core.di.databaseModule
import com.shamelagpt.android.core.di.networkModule
import com.shamelagpt.android.core.di.presentationModule
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.context.startKoin
import org.koin.core.logger.Level

class ShamelaGPTApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize Koin
        startKoin {
            androidLogger(Level.ERROR)
            androidContext(this@ShamelaGPTApplication)
            modules(
                databaseModule,
                networkModule,
                presentationModule
            )
        }
    }
}
