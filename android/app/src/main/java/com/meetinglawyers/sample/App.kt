package com.meetinglawyers.sample

import android.app.Application
import com.meetinglawyers.sdk.CustomerSdkBuildMode
import com.meetinglawyers.sdk.MeetingLawyersSDK
import java.util.Locale

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        val buildMode = if (Constants.isProduction) CustomerSdkBuildMode.PROD else CustomerSdkBuildMode.DEV
        MeetingLawyersSDK(this, Constants.apiKey, buildMode, Locale.getDefault())
            .build()
    }
}
