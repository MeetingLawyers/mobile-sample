package com.meetinglawyers.sample

import android.app.Application
import com.meetinglawyers.sdk.CustomerSdkBuildMode
import com.meetinglawyers.sdk.MeetingLawyersSDK
import java.util.Locale

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        MeetingLawyersSDK(this, Constants.apiKey, CustomerSdkBuildMode.DEV, Locale.getDefault())
            .build()
    }
}
