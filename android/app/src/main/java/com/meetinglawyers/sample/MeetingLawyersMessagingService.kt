package com.meetinglawyers.sample

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** Forwards FCM messages and token refreshes; if your app has its own service, add these two calls to it. */
class MeetingLawyersMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        // MeetingLawyers pushes go to the SDK; handle the rest as your app usually does.
        MeetingLawyersIntegration.onMessageReceived(remoteMessage.data)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        MeetingLawyersIntegration.onNewToken(token)
    }
}
