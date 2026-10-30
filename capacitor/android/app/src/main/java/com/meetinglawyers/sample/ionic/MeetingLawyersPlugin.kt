package com.meetinglawyers.sample.ionic

import android.Manifest
import android.app.Application
import android.content.Context
import android.os.Build
import androidx.core.content.edit
import com.getcapacitor.JSObject
import com.getcapacitor.PermissionState
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import com.getcapacitor.annotation.PermissionCallback

/**
 * Capacitor bridge to [MeetingLawyersIntegration]. Copy this file plus `MeetingLawyersIntegration.kt`,
 * `MeetingLawyersMessagingService.kt` (and `src/plugins/meeting-lawyers/`) into your Capacitor app.
 */
@CapacitorPlugin(
    name = "MeetingLawyers",
    permissions = [Permission(strings = [Manifest.permission.POST_NOTIFICATIONS], alias = "notifications")],
)
class MeetingLawyersPlugin : Plugin() {

    private val integration = MeetingLawyersIntegration

    /** Configures the SDK and saves its arguments for a push that wakes the killed app. */
    @PluginMethod
    fun configure(call: PluginCall) {
        val apiKey = call.getString("apiKey").orEmpty()
        if (apiKey.isEmpty()) return call.reject("apiKey is required")
        val isProduction = call.getString("environment") != "DEV"
        run(call) {
            integration.configure(activity.application, apiKey, isProduction)
            savedArguments(activity.application).edit {
                putString(API_KEY, apiKey)
                putBoolean(IS_PRODUCTION, isProduction)
            }
        }
    }

    /** Applies the theme colors; every color is optional. */
    @PluginMethod
    fun configureTheme(call: PluginCall) {
        run(call) {
            integration.configureTheme(
                MeetingLawyersIntegration.Theme(
                    call.getString("primaryColor"), call.getString("secondaryColor"), call.getString("navigationBarColor"),
                    call.getString("incomingMessageColor"), call.getString("outgoingMessageColor"),
                ),
            )
        }
    }

    /** Signs the user in and registers the push token, then asks for the notification permission on Android 13+. */
    @PluginMethod
    fun authenticate(call: PluginCall) {
        val userId = call.getString("userId").orEmpty()
        if (userId.isEmpty()) return call.reject("userId is required")
        activity.runOnUiThread {
            integration.authenticate(userId) { error ->
                if (error == null) requestNotificationPermission(call) else call.reject(error)
            }
        }
    }

    /** Opens the professional list; tapping a professional opens its chat. */
    @PluginMethod
    fun openProfessionalList(call: PluginCall) {
        run(call) { integration.openProfessionalList(activity) }
    }

    /** Opens the chat with a professional. */
    @PluginMethod
    fun openChat(call: PluginCall) {
        val hash = call.getString("professionalHash").orEmpty()
        if (hash.isEmpty()) return call.reject("professionalHash is required")
        run(call) { integration.openChat(activity, hash) }
    }

    /** True while a user is signed in. */
    @PluginMethod
    fun isAuthenticated(call: PluginCall) {
        call.resolve(JSObject().put("authenticated", integration.isAuthenticated))
    }

    /** Signs the user out. */
    @PluginMethod
    fun logout(call: PluginCall) {
        activity.runOnUiThread {
            integration.logout { error -> if (error == null) call.resolve() else call.reject(error) }
        }
    }

    @PermissionCallback
    private fun notificationsPermissionCallback(call: PluginCall) {
        call.resolve()
    }

    /** Resolves `call` right away when the permission is not needed or already decided. */
    private fun requestNotificationPermission(call: PluginCall) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || getPermissionState("notifications") != PermissionState.PROMPT) {
            call.resolve()
        } else {
            requestPermissionForAlias("notifications", call, "notificationsPermissionCallback")
        }
    }

    /** Runs an integration call on the main thread and resolves or rejects `call`. */
    private fun run(call: PluginCall, operation: () -> Unit) {
        activity.runOnUiThread {
            runCatching(operation)
                .onSuccess { call.resolve() }
                .onFailure { call.reject(it.message ?: it.toString()) }
        }
    }

    companion object {
        private const val API_KEY = "apiKey"
        private const val IS_PRODUCTION = "isProduction"

        /** Configures the SDK with the arguments of the last `configure`, e.g. when a push wakes the killed app. */
        @Synchronized
        fun configureFromSavedArguments(application: Application) {
            if (MeetingLawyersIntegration.isConfigured) return
            val saved = savedArguments(application)
            val apiKey = saved.getString(API_KEY, null) ?: return
            MeetingLawyersIntegration.configure(application, apiKey, saved.getBoolean(IS_PRODUCTION, true))
        }

        private fun savedArguments(context: Context) =
            context.getSharedPreferences("meeting_lawyers_plugin", Context.MODE_PRIVATE)
    }
}
