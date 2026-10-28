package com.meetinglawyers.sample.flutter

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter bridge to [MeetingLawyersIntegration]: the `meeting_lawyers` method channel used by
 * `lib/meeting_lawyers/meeting_lawyers.dart`. Copy it with `MeetingLawyersIntegration.kt`.
 */
class MeetingLawyersChannel private constructor(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val integration = MeetingLawyersIntegration

    /** Routes each Dart call to the integration; Flutter calls it on the main thread. */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        runCatching { perform(call, result) }
            .onFailure { result.error(call.method, it.message ?: it.toString(), null) }
    }

    private fun perform(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> {
                val apiKey = call.argument<String>("apiKey").orEmpty().ifEmpty { error("apiKey is required") }
                val isProduction = call.argument<Boolean>("isProduction") ?: true
                integration.configure(activity.application, apiKey, isProduction)
                preferences(activity).edit().putString(API_KEY, apiKey).putBoolean(IS_PRODUCTION, isProduction).apply()
                result.success(null)
            }
            "configureTheme" -> {
                integration.configureTheme(call.argument<Number>("color")?.toInt() ?: 0)
                result.success(null)
            }
            "authenticate" -> integration.authenticate(
                call.argument<String>("userId").orEmpty().ifEmpty { error("userId is required") },
            ) { error ->
                if (error == null) requestNotificationPermission()
                result.reply(call.method, error)
            }
            "openProfessionalList" -> {
                integration.openProfessionalList(activity)
                result.success(null)
            }
            "openChat" -> {
                integration.openChat(
                    activity, call.argument<String>("professionalHash").orEmpty().ifEmpty { error("professionalHash is required") },
                )
                result.success(null)
            }
            "isAuthenticated" -> result.success(integration.isAuthenticated)
            "logout" -> integration.logout { error -> result.reply(call.method, error) }
            else -> result.notImplemented()
        }
    }

    /** Completes the call with the SDK error, or success when there is none. */
    private fun MethodChannel.Result.reply(method: String, error: String?) {
        if (error == null) success(null) else error(method, error, null)
    }

    /** Android 13+ needs the runtime permission before showing any push. */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 0)
        }
    }

    companion object {
        private const val API_KEY = "apiKey"
        private const val IS_PRODUCTION = "isProduction"

        /** Where `configure` keeps its values. */
        private fun preferences(context: Context) = context.getSharedPreferences("meeting_lawyers", Context.MODE_PRIVATE)

        /** Configures the SDK with the last values from Dart when a push wakes the app before Flutter runs. */
        @Synchronized
        fun restoreConfiguration(application: Application) {
            val apiKey = preferences(application).getString(API_KEY, null) ?: return
            if (!MeetingLawyersIntegration.isConfigured) {
                MeetingLawyersIntegration.configure(application, apiKey, preferences(application).getBoolean(IS_PRODUCTION, true))
            }
        }

        /** Registers the channel; call it from `configureFlutterEngine`. */
        fun register(engine: FlutterEngine, activity: Activity) {
            MethodChannel(engine.dartExecutor.binaryMessenger, "meeting_lawyers").setMethodCallHandler(MeetingLawyersChannel(activity))
        }
    }
}
