package com.meetinglawyers.meetingpros.sample

import android.app.Application

class App : Application() {
    /** Configures both SDKs at startup, unless the `.env` credentials are missing. */
    override fun onCreate() {
        super.onCreate()
        if (Constants.lawyersApiKey.isNotEmpty() && Constants.doctorsApiKey.isNotEmpty()) {
            MeetingProsIntegration.configure(
                this, Constants.lawyersApiKey, Constants.doctorsApiKey, Constants.isProduction, MainActivity::class.java,
            )
            MeetingProsIntegration.configureTheme(Constants.brandColor)
        }
    }
}
