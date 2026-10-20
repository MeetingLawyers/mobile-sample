package com.meetinglawyers.sample

import android.app.Activity
import android.app.Application
import com.google.firebase.messaging.FirebaseMessaging
import com.meetinglawyers.sdk.CustomerSdkBuildMode
import com.meetinglawyers.sdk.MeetingLawyersClient
import com.meetinglawyers.sdk.MeetingLawyersSDK
import com.meetinglawyers.sdk.SDKCallbackWithoutData
import com.meetinglawyers.sdk.domain.logger.LogMode
import java.util.Locale

/** Every MeetingLawyers SDK call the sample makes, in one file you can copy into your app. */
object MeetingLawyersIntegration {

    private val client: MeetingLawyersClient
        get() = MeetingLawyersSDK.getClientInstance()

    val isConfigured: Boolean
        get() = MeetingLawyersSDK.isInitialized()

    val isAuthenticated: Boolean
        get() = isConfigured && client.isAuthenticated()

    /** Initializes the SDK: production, or the demo environment with verbose logs. Call it from `Application.onCreate`. */
    fun configure(application: Application, apiKey: String, isProduction: Boolean) {
        val buildMode = if (isProduction) CustomerSdkBuildMode.PROD else CustomerSdkBuildMode.DEV
        val logMode = if (isProduction) LogMode.NONE else LogMode.VERBOSE
        MeetingLawyersSDK(application, apiKey, buildMode, Locale.getDefault(), logMode).build()
    }

    /** Applies the brand color to every themable element. */
    fun configureTheme(color: Int) {
        client.setPrimaryColor(color)
        client.setSecondaryColor(color)
        client.setNavigationBarColor(color)
        client.setOngoingMessageBgColor(color)
    }

    /** Signs the user in and links this device's push token to them; `onResult` gets the error, or null. */
    fun authenticate(userId: String, onResult: (String?) -> Unit) {
        client.authenticate(userId, callback { error ->
            if (error == null) registerPushToken()
            onResult(error)
        })
    }

    /** Signs the user out of the SDK; `onResult` gets the error, or null. */
    fun logout(onResult: (String?) -> Unit) {
        client.deauthenticate(callback(onResult))
    }

    /** Opens the professional list on top of `activity`; tapping a professional opens its chat. */
    fun openProfessionalList(activity: Activity) {
        client.openProfessionalList(activity, null)
    }

    /** Opens the chat with the professional identified by `professionalHash`. */
    fun openChat(activity: Activity, professionalHash: String) {
        client.openChatWithProfessional(activity, professionalHash)
    }

    /** Hands a MeetingLawyers push to the SDK; returns false for any other push. */
    fun onMessageReceived(data: Map<String, String>): Boolean {
        val payload = data["data"] ?: return false
        return isConfigured && client.onPushMessageReceived(payload)
    }

    /** Forwards an FCM token refresh once a user is signed in. */
    fun onNewToken(token: String) {
        if (isAuthenticated) client.onNewTokenReceived(token)
    }

    /** Sends the current FCM token to the SDK. */
    private fun registerPushToken() {
        FirebaseMessaging.getInstance().token.addOnSuccessListener { token -> client.onNewTokenReceived(token) }
    }

    /** Adapts the SDK callback to a single `(error) -> Unit` lambda. */
    private fun callback(onResult: (String?) -> Unit) = object : SDKCallbackWithoutData {
        override fun onSuccess() = onResult(null)
        override fun onError(message: String?) = onResult(message ?: "Unknown error")
    }
}
