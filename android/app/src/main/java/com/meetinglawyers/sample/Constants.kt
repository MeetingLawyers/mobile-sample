package com.meetinglawyers.sample

import android.graphics.Color

/** Demo credentials, read from the repo-root `.env` through `BuildConfig`. */
object Constants {
    const val apiKey = BuildConfig.ML_API_KEY
    const val userId = BuildConfig.ML_USER_ID

    /** `PROD` points to production; anything else to the MeetingLawyers demo environment. */
    val isProduction = BuildConfig.ML_ENVIRONMENT == "PROD"

    val brandColor = Color.parseColor("#2E7D6B")
}
