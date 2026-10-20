package com.meetinglawyers.sample

import android.app.Application

class App : Application() {
    /** Configures the SDK at startup, unless the `.env` credentials are missing. */
    override fun onCreate() {
        super.onCreate()
        if (Constants.apiKey.isNotEmpty()) {
            MeetingLawyersIntegration.configure(this, Constants.apiKey, Constants.isProduction)
            MeetingLawyersIntegration.configureTheme(Constants.brandColor)
        }
    }
}
