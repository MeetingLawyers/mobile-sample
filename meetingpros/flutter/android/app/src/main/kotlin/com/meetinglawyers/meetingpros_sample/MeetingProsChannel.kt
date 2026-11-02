package com.meetinglawyers.meetingpros_sample

import android.Manifest
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.meetinglawyers.meetingpros_sample.MeetingProsIntegration.DoctorsFeature
import com.meetinglawyers.meetingpros_sample.MeetingProsIntegration.ProfessionalType
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch

/**
 * Flutter bridge to [MeetingProsIntegration]: the `meeting_pros` method channel used by
 * `lib/meeting_pros/meeting_pros.dart`. Copy it with `MeetingProsIntegration.kt`.
 */
class MeetingProsChannel private constructor(private val activity: FragmentActivity) : MethodChannel.MethodCallHandler {

    private val integration = MeetingProsIntegration
    private val listTypes = mapOf(
        "lawyers" to ProfessionalType.LAWYERS, "doctors" to ProfessionalType.DOCTORS, "vets" to ProfessionalType.VETS,
    )
    private val features = mapOf(
        "videoCall" to DoctorsFeature.VIDEO_CALL, "medicalHistory" to DoctorsFeature.MEDICAL_HISTORY,
        "myHealth" to DoctorsFeature.MY_HEALTH, "booking" to DoctorsFeature.BOOKING,
        "appointments" to DoctorsFeature.APPOINTMENTS,
    )

    /** Routes each Dart call to the integration on the main thread. */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        activity.lifecycleScope.launch {
            runCatching { perform(call) }
                .onSuccess { result.success(it) }
                .onFailure { result.error(call.method, it.message ?: it.toString(), null) }
        }
    }

    private suspend fun perform(call: MethodCall): Any? {
        when (call.method) {
            "configure" -> integration.configure(
                activity.application, call.argument<String>("lawyersApiKey").orEmpty(),
                call.argument<String>("doctorsApiKey").orEmpty(), call.argument<Boolean>("isProduction") ?: true,
                pushActivity = activity.javaClass,
            )
            "configureTheme" -> integration.configureTheme(call.argument<String>("primaryColor").orEmpty())
            "authenticate" -> {
                integration.authenticate(requireNotNull(call.argument<String>("userId")) { "userId is required" })
                requestNotificationPermission()
            }
            "openProfessionalList" -> integration.openProfessionalList(
                activity, requireNotNull(listTypes[call.argument<String>("type")]) { "type must be lawyers, doctors or vets" },
            )
            "openLawyerChat" -> integration.openLawyerChat(
                activity, call.argument<String>("professionalHash").orEmpty().ifEmpty { error("professionalHash is required") },
            )
            "availableFeatures" -> {
                val available = integration.availableFeatures()
                return features.filterValues { it in available }.keys.sorted()
            }
            "openFeature" -> integration.open(
                activity, requireNotNull(features[call.argument<String>("feature")]) { "Unknown feature" },
            )
            "isAuthenticated" -> return integration.isAuthenticated
            "logout" -> integration.logout()
            else -> error("Not implemented: ${call.method}")
        }
        return null
    }

    /** Android 13+ needs the runtime permission before showing any push. */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 0)
        }
    }

    companion object {
        /** Registers the channel; call it from `configureFlutterEngine`. */
        fun register(engine: FlutterEngine, activity: FragmentActivity) {
            MethodChannel(engine.dartExecutor.binaryMessenger, "meeting_pros").setMethodCallHandler(MeetingProsChannel(activity))
        }
    }
}
