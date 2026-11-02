package com.meetinglawyers.sample.ionic

import android.app.Activity
import android.app.Application
import android.os.Handler
import android.os.Looper
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

    private val mainHandler = Handler(Looper.getMainLooper())

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

    /** Colors of the SDK screens shared by iOS and Android, as "#RRGGBB" or "#RRGGBBAA"; a null color keeps the SDK default. */
    data class Theme(
        val primaryColor: String? = null,
        val secondaryColor: String? = null,
        val navigationBarColor: String? = null,
        val incomingMessageColor: String? = null,
        val outgoingMessageColor: String? = null,
    )

    /** Applies the theme colors; throws `IllegalArgumentException` on an invalid color. */
    fun configureTheme(theme: Theme) {
        val primary = color("primaryColor", theme.primaryColor)
        val secondary = color("secondaryColor", theme.secondaryColor)
        val navigationBar = color("navigationBarColor", theme.navigationBarColor)
        val incomingMessage = color("incomingMessageColor", theme.incomingMessageColor)
        val outgoingMessage = color("outgoingMessageColor", theme.outgoingMessageColor)
        primary?.let { client.setPrimaryColor(it) }
        secondary?.let { client.setSecondaryColor(it) }
        navigationBar?.let { client.setNavigationBarColor(it) }
        incomingMessage?.let { client.setIncomingMessageBgColor(it) }
        outgoingMessage?.let { client.setOngoingMessageBgColor(it) }
    }

    /** Parses a "#RRGGBB" or "#RRGGBBAA" color into an ARGB int; null when not given. */
    private fun color(name: String, hex: String?): Int? {
        hex ?: return null
        val value = hex.removePrefix("#")
        val argb = when (value.length) {
            6 -> "FF$value"
            8 -> value.takeLast(2) + value.take(6)
            else -> null
        }
        return requireNotNull(argb?.toLongOrNull(16)?.toInt()) { "$name must be #RRGGBB or #RRGGBBAA" }
    }

    /** Signs the user in and links this device's push token to them; `onResult` gets the error, or null, on the main thread. */
    fun authenticate(userId: String, onResult: (String?) -> Unit) {
        client.authenticate(userId, callback { error ->
            if (error == null) registerPushToken()
            onResult(error)
        })
    }

    /** Signs the user out of the SDK; `onResult` gets the error, or null, on the main thread. */
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

    /** Adapts the SDK callback to a single `(error) -> Unit` lambda, delivered on the main thread. */
    private fun callback(onResult: (String?) -> Unit) = object : SDKCallbackWithoutData {
        override fun onSuccess() {
            mainHandler.post { onResult(null) }
        }

        override fun onError(message: String?) {
            mainHandler.post { onResult(message ?: "Unknown error") }
        }
    }
}
