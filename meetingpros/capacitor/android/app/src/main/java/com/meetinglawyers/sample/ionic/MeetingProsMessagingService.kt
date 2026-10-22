package com.meetinglawyers.sample.ionic

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking

/** Forwards FCM messages and token refreshes; if your app has its own service, add these calls to it. */
class MeetingProsMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        configureIfNeeded()
        if (!MeetingProsIntegration.onMessageReceived(remoteMessage)) {
            // Your own pushes: only notification-only ones get here, data pushes go to the video call SDK.
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        configureIfNeeded()
        MeetingProsIntegration.onNewToken(token)
    }

    /** A push can start the app with no web view: configure the SDKs on the main thread, as `configure` does. */
    private fun configureIfNeeded() = runBlocking(Dispatchers.Main) {
        MeetingProsPlugin.configureFromSavedArguments(application)
    }
}
