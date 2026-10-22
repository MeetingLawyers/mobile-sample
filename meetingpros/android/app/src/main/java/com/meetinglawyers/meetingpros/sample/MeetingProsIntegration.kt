package com.meetinglawyers.meetingpros.sample

import android.app.Activity
import android.app.Application
import androidx.activity.addCallback
import androidx.fragment.app.FragmentActivity
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.RemoteMessage
import com.meetingdoctors.chat.MeetingDoctorsClient
import com.meetingdoctors.chat.data.SpecialityInfo
import com.meetingdoctors.chat.views.professionallist.ProfessionalListFragment
import com.meetingdoctors.videocall.VideoCallClient
import com.meetingdoctors.videocall.api.VideoCallBuildMode
import com.meetingdoctors.videocall.fcm.MDVideoCallFirebaseMessagingService
import com.meetinglawyers.sdk.MeetingLawyersClient
import com.meetinglawyers.sdk.MeetingLawyersSDK
import com.meetinglawyers.sdk.SDKCallbackWithoutData
import com.meetinglawyers.sdk.domain.logger.LogMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.util.Locale
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import com.meetingdoctors.chat.data.webservices.CustomerSdkBuildMode as DoctorsBuildMode
import com.meetinglawyers.sdk.CustomerSdkBuildMode as LawyersBuildMode

/**
 * Lawyers (MeetingLawyers SDK) plus doctors and vets (MeetingDoctors SDK) behind one file you can copy
 * into your app: it is the only place that imports either SDK.
 */
object MeetingProsIntegration {

    enum class ProfessionalType { LAWYERS, DOCTORS, VETS }

    enum class DoctorsFeature { VIDEO_CALL, MEDICAL_HISTORY, MY_HEALTH, BOOKING, APPOINTMENTS }

    /** MeetingDoctors specialities of the vets list; doctors gets every other speciality. */
    private val vetSpecialities = listOf(
        SpecialityInfo.VETERINARY, SpecialityInfo.ETHOLOGY, SpecialityInfo.ANIMAL_NUTRITION,
        SpecialityInfo.ATENCION_CLIENT_VETS, SpecialityInfo.ANESTESIA_ANALGESIA_VET,
        SpecialityInfo.ANTIBIOTERAPIA_VET, SpecialityInfo.DERMATOLOGIA_VET, SpecialityInfo.ENDOCRINO_VET,
        SpecialityInfo.CARDIOLOGIA_VET, SpecialityInfo.ENTRENADOR_CANINO, SpecialityInfo.OFTALMO_VET,
    ).joinToString(",") { it.specialityName }

    private lateinit var application: Application
    private lateinit var pushActivity: Class<out Activity>
    private var userId: String? = null

    private val lawyers: MeetingLawyersClient
        get() = MeetingLawyersSDK.getClientInstance()

    private val doctors: MeetingDoctorsClient?
        get() = MeetingDoctorsClient.instance

    val isConfigured: Boolean
        get() = MeetingLawyersSDK.isInitialized() && doctors != null

    /** True only while the user is signed into both SDKs. */
    val isAuthenticated: Boolean
        get() = isConfigured && lawyers.isAuthenticated() && doctors?.isAuthenticated == true

    /**
     * Configures MeetingLawyers, then MeetingDoctors and its video call: production, or demo (lawyers) and
     * staging (doctors). Call it from `Application.onCreate`; `pushActivity` opens when a doctors push is tapped.
     */
    fun configure(
        application: Application,
        lawyersApiKey: String,
        doctorsApiKey: String,
        isProduction: Boolean,
        pushActivity: Class<out Activity>,
    ) {
        require(doctorsApiKey.isNotEmpty()) { "doctorsApiKey is required" }
        this.application = application
        this.pushActivity = pushActivity
        val logMode = if (isProduction) LogMode.NONE else LogMode.VERBOSE
        val lawyersMode = if (isProduction) LawyersBuildMode.PROD else LawyersBuildMode.DEV
        MeetingLawyersSDK(application, lawyersApiKey, lawyersMode, Locale.getDefault(), logMode).build()

        // MeetingDoctors needs the MeetingLawyers installation, so it always goes second.
        val doctorsMode = if (isProduction) DoctorsBuildMode.PROD else DoctorsBuildMode.STAGING
        MeetingDoctorsClient.newInstance(application, doctorsApiKey, doctorsMode, false, lawyersApiKey, Locale.getDefault())
        VideoCallClient.initialize(
            application, doctorsApiKey, lawyers.getInstallationGuid(), false, lawyersApiKey,
            object : VideoCallClient.InitResponseListener {
                override fun onInitSuccess() = Unit
                override fun onInitFailure(message: String?) = Unit
            },
            if (isProduction) VideoCallBuildMode.PROD else VideoCallBuildMode.STAGING,
            Locale.getDefault(),
        )
    }

    /** Applies the brand color to both SDKs. */
    fun configureTheme(color: Int) {
        lawyers.setPrimaryColor(color)
        lawyers.setSecondaryColor(color)
        lawyers.setNavigationBarColor(color)
        lawyers.setOngoingMessageBgColor(color)
        doctors?.apply {
            setPrimaryColor(color)
            setSecondaryColor(color)
            setSpecialityProfessionalColor(color)
            setUnreadBadgeProfessionalColor(color)
            setOutgoingMessageBgColor(color)
        }
    }

    /** Signs the same user into both SDKs, MeetingLawyers first, and links this device's push token. */
    suspend fun authenticate(userId: String) {
        suspendCancellableCoroutine { continuation ->
            lawyers.authenticate(userId, callback { error ->
                if (error == null) continuation.resume(Unit) else continuation.resumeWithException(IllegalStateException(error))
            })
        }
        requireNotNull(doctors) { "Configure first" }.authenticate(userId).getOrThrow()
        this.userId = userId
        registerPushToken()
    }

    /** Signs the user out of both SDKs. */
    suspend fun logout() {
        suspendCancellableCoroutine { continuation ->
            lawyers.deauthenticate(callback { error ->
                if (error == null) continuation.resume(Unit) else continuation.resumeWithException(IllegalStateException(error))
            })
        }
        doctors?.deauthenticate()
        userId = null
    }

    /** Opens the list of the given type on top of `activity`; tapping a professional opens its chat. */
    fun openProfessionalList(activity: FragmentActivity, type: ProfessionalType) {
        if (type == ProfessionalType.LAWYERS) {
            lawyers.openProfessionalList(activity, null)
            return
        }
        val list = ProfessionalListFragment()
        val fragments = activity.supportFragmentManager
        fragments.beginTransaction()
            .add(android.R.id.content, list)
            .addToBackStack(type.name)
            .commit()
        // The filters need the fragment created.
        fragments.executePendingTransactions()
        if (type == ProfessionalType.VETS) list.includeSpecialities(vetSpecialities) else list.excludeSpecialities(vetSpecialities)
        list.hideListHeader()
        list.view?.apply {
            fitsSystemWindows = true
            requestApplyInsets()
        }
        // Back closes the list, even when the host (e.g. a web view) handles back itself.
        activity.onBackPressedDispatcher.addCallback(list) { fragments.popBackStack() }
    }

    /** Opens the chat with the lawyer identified by `professionalHash`. */
    fun openLawyerChat(activity: Activity, professionalHash: String) {
        lawyers.openChatWithProfessional(activity, professionalHash)
    }

    /** The MeetingDoctors features the company has. Call it after authenticating. */
    suspend fun availableFeatures(): Set<DoctorsFeature> = withContext(Dispatchers.IO) {
        val doctors = doctors ?: return@withContext emptySet()
        val hasBooking = doctors.hasBookingVCSync().getOrDefault(false)
        buildSet {
            if (VideoCallClient.hasVideoCall()) add(DoctorsFeature.VIDEO_CALL)
            if (doctors.hasMedicalHistory()) add(DoctorsFeature.MEDICAL_HISTORY)
            if (doctors.hasFeedsSync().getOrDefault(false)) add(DoctorsFeature.MY_HEALTH)
            // Appointments has no check of its own on Android: it comes with booking.
            if (hasBooking) addAll(listOf(DoctorsFeature.BOOKING, DoctorsFeature.APPOINTMENTS))
        }
    }

    /** Opens a MeetingDoctors feature, or fails when the company does not have it. */
    suspend fun open(activity: Activity, feature: DoctorsFeature) {
        check(feature in availableFeatures()) { "$feature is not available" }
        val doctors = requireNotNull(doctors) { "Configure first" }
        when (feature) {
            DoctorsFeature.VIDEO_CALL -> startVideoCall(activity)
            DoctorsFeature.MEDICAL_HISTORY -> doctors.openMedicalHistoryAsync(activity).getOrThrow()
            DoctorsFeature.MY_HEALTH -> doctors.openMyHealthAsync(activity).getOrThrow()
            DoctorsFeature.BOOKING -> doctors.openSchedulingBookingVC(activity).getOrThrow()
            DoctorsFeature.APPOINTMENTS -> doctors.openAppointmentsAsync(activity).getOrThrow()
        }
    }

    /** Routes an FCM message to the SDK that owns it; returns false when it belongs to neither. */
    fun onMessageReceived(message: RemoteMessage): Boolean {
        if (!isConfigured) return false
        val lawyersPayload = message.data["data"]
        if (lawyersPayload != null && lawyers.onPushMessageReceived(lawyersPayload)) return true
        if (doctors?.onFirebaseMessageReceived(message, pushActivity) == true) return true
        if (message.data.isEmpty()) return false
        MDVideoCallFirebaseMessagingService.onMessageReceived(message, application)
        return true
    }

    /** Forwards an FCM token refresh to both SDKs once a user is signed in. */
    fun onNewToken(token: String) {
        if (!isAuthenticated) return
        lawyers.onNewTokenReceived(token)
        doctors?.onNewTokenReceived(token)
        VideoCallClient.onNewTokenReceived(token)
    }

    /** Logs the user into the video call service and opens the call with the duty doctor. */
    private suspend fun startVideoCall(activity: Activity) {
        val user = requireNotNull(userId) { "Authenticate first" }
        suspendCancellableCoroutine { continuation ->
            VideoCallClient.login(user, object : VideoCallClient.LoginResponseListener {
                override fun onLoginSuccess() {
                    VideoCallClient.openCall(activity)
                    continuation.resume(Unit)
                }

                override fun onLoginFailure(message: String?) {
                    continuation.resumeWithException(IllegalStateException(message ?: "Video call login failed"))
                }
            })
        }
    }

    /** Sends the current FCM token to both SDKs. */
    private fun registerPushToken() {
        FirebaseMessaging.getInstance().token.addOnSuccessListener(::onNewToken)
    }

    /** Adapts the MeetingLawyers callback to a single `(error) -> Unit` lambda. */
    private fun callback(onResult: (String?) -> Unit) = object : SDKCallbackWithoutData {
        override fun onSuccess() = onResult(null)
        override fun onError(message: String?) = onResult(message ?: "Unknown error")
    }
}
