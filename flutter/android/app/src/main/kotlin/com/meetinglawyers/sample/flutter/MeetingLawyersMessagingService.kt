package com.meetinglawyers.sample.flutter

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** Forwards FCM messages and token refreshes, configuring the SDK first if a push woke the app; if your app has its own service, add these calls to it. */
class MeetingLawyersMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        MeetingLawyersChannel.restoreConfiguration(application)
        // MeetingLawyers pushes go to the SDK; handle the rest as your app usually does.
        MeetingLawyersIntegration.onMessageReceived(remoteMessage.data)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        MeetingLawyersChannel.restoreConfiguration(application)
        MeetingLawyersIntegration.onNewToken(token)
    }
}
