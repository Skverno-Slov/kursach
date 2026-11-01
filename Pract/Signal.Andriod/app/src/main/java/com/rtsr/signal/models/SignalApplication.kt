package com.rtsr.signal.models

import android.app.Application
import com.rtsr.signal.services.TokenManager

class SignalApplication : Application() {

    companion object {
        lateinit var tokenManager: TokenManager
            private set
    }

    override fun onCreate() {
        super.onCreate()
        tokenManager = TokenManager(this)
    }
}