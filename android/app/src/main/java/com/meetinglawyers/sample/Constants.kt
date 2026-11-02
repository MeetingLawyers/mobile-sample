package com.meetinglawyers.sample

/** Demo credentials, read from the repo-root `.env` through `BuildConfig`. */
object Constants {
    const val apiKey = BuildConfig.ML_API_KEY
    const val userId = BuildConfig.ML_USER_ID

    /** `PROD` points to production; anything else to the MeetingLawyers demo environment. */
    val isProduction = BuildConfig.ML_ENVIRONMENT == "PROD"

    const val brandColor = "#2E7D6B"
}
