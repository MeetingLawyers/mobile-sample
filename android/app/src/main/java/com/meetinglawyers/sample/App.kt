package com.meetinglawyers.sample

import android.app.Application
import com.meetinglawyers.sdk.MeetingLawyersClient
import com.meetinglawyers.sdk.data.CustomerSdkBuildMode

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        MeetingLawyersClient.newInstance(this, Constants.apiKey, CustomerSdkBuildMode.DEV)
    }
}