package com.meetinglawyers.meetingpros_sample

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** Forwards FCM messages and token refreshes; if your app has its own service, add these two calls to it. */
class MeetingProsMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        if (!MeetingProsIntegration.onMessageReceived(remoteMessage)) {
            // Your own pushes: only notification-only ones get here, data pushes go to the video call SDK.
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        MeetingProsIntegration.onNewToken(token)
    }
}
