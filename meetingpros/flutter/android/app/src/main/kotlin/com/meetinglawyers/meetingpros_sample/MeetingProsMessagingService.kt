package com.meetinglawyers.meetingpros_sample

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** Forwards FCM messages and token refreshes; if your app has its own service, add these two calls to it. */
class MeetingProsMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        // Lawyers and doctors pushes go to their SDK.
        MeetingProsIntegration.onMessageReceived(remoteMessage)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        MeetingProsIntegration.onNewToken(token)
    }
}
