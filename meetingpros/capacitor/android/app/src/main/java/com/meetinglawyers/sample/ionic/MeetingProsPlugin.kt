package com.meetinglawyers.sample.ionic

import android.Manifest
import android.graphics.Color
import android.os.Build
import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.PermissionState
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import com.getcapacitor.annotation.PermissionCallback
import com.meetinglawyers.sample.ionic.MeetingProsIntegration.DoctorsFeature
import com.meetinglawyers.sample.ionic.MeetingProsIntegration.ProfessionalType
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Capacitor bridge to [MeetingProsIntegration]. Copy this file plus `MeetingProsIntegration.kt`,
 * `MeetingProsFirebaseService.kt` (and `src/plugins/meeting-pros/`) into your Capacitor app.
 */
@CapacitorPlugin(
    name = "MeetingPros",
    permissions = [Permission(strings = [Manifest.permission.POST_NOTIFICATIONS], alias = "notifications")],
)
class MeetingProsPlugin : Plugin() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val integration = MeetingProsIntegration

    private val listTypes = mapOf(
        "lawyers" to ProfessionalType.LAWYERS, "doctors" to ProfessionalType.DOCTORS, "vets" to ProfessionalType.VETS,
    )
    private val features = mapOf(
        "videoCall" to DoctorsFeature.VIDEO_CALL, "medicalHistory" to DoctorsFeature.MEDICAL_HISTORY,
        "myHealth" to DoctorsFeature.MY_HEALTH, "booking" to DoctorsFeature.BOOKING,
        "appointments" to DoctorsFeature.APPOINTMENTS,
    )

    /** Configures both SDKs. */
    @PluginMethod
    fun configure(call: PluginCall) {
        val lawyersApiKey = call.getString("lawyersApiKey").orEmpty()
        if (lawyersApiKey.isEmpty()) return call.reject("lawyersApiKey is required")
        run(call) {
            integration.configure(
                activity.application, lawyersApiKey, call.getString("doctorsApiKey").orEmpty(),
                isProduction = call.getString("environment") != "DEV", pushActivity = MainActivity::class.java,
            )
        }
    }

    /** Applies the brand color to both SDKs. */
    @PluginMethod
    fun configureTheme(call: PluginCall) {
        val color = parseColor(call.getString("primaryColor")) ?: return call.reject("primaryColor must be #RRGGBB or #RRGGBBAA")
        run(call) { integration.configureTheme(color) }
    }

    /** Signs the user into both SDKs, then asks for the notification permission on Android 13+. */
    @PluginMethod
    fun authenticate(call: PluginCall) {
        val userId = call.getString("userId").orEmpty()
        if (userId.isEmpty()) return call.reject("userId is required")
        scope.launch {
            runCatching { integration.authenticate(userId) }
                .onSuccess { requestNotificationPermission(call) }
                .onFailure { call.reject(it.message ?: it.toString()) }
        }
    }

    /** Opens the lawyers, doctors or vets list. */
    @PluginMethod
    fun openProfessionalList(call: PluginCall) {
        val type = listTypes[call.getString("type")] ?: return call.reject("type must be lawyers, doctors or vets")
        run(call) { integration.openProfessionalList(activity, type) }
    }

    /** Opens the chat with a lawyer. */
    @PluginMethod
    fun openLawyerChat(call: PluginCall) {
        val hash = call.getString("professionalHash").orEmpty()
        if (hash.isEmpty()) return call.reject("professionalHash is required")
        run(call) { integration.openLawyerChat(activity, hash) }
    }

    /** Returns the MeetingDoctors features the company has. */
    @PluginMethod
    fun availableFeatures(call: PluginCall) {
        scope.launch {
            val available = integration.availableFeatures()
            val names = features.filterValues { it in available }.keys.sorted()
            call.resolve(JSObject().put("features", JSArray(names)))
        }
    }

    /** Opens a MeetingDoctors feature. */
    @PluginMethod
    fun openFeature(call: PluginCall) {
        val feature = features[call.getString("feature")] ?: return call.reject("Unknown feature")
        run(call) { integration.open(activity, feature) }
    }

    /** True only while the user is signed into both SDKs. */
    @PluginMethod
    fun isAuthenticated(call: PluginCall) {
        call.resolve(JSObject().put("authenticated", integration.isAuthenticated))
    }

    /** Signs the user out of both SDKs. */
    @PluginMethod
    fun logout(call: PluginCall) {
        run(call) { integration.logout() }
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
    private fun run(call: PluginCall, operation: suspend () -> Unit) {
        scope.launch {
            runCatching { operation() }
                .onSuccess { call.resolve() }
                .onFailure { call.reject(it.message ?: it.toString()) }
        }
    }

    /** Parses a "#RRGGBB" or "#RRGGBBAA" hex string into an ARGB int. */
    private fun parseColor(hex: String?): Int? {
        val value = hex?.removePrefix("#")?.trim() ?: return null
        val argb = when (value.length) {
            6 -> "FF$value"
            8 -> value.takeLast(2) + value.take(6)
            else -> return null
        }
        return runCatching { Color.parseColor("#$argb") }.getOrNull()
    }
}
