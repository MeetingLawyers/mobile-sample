package com.meetinglawyers.meetingpros.sample

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** Forwards FCM messages and token refreshes; if your app has its own service, add these two calls to it. */
class SampleMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        // Lawyers and doctors pushes go to their SDK; handle the rest as your app usually does.
        MeetingProsIntegration.onMessageReceived(remoteMessage)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        MeetingProsIntegration.onNewToken(token)
    }
}
