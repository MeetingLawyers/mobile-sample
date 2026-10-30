package com.meetinglawyers.sample.ionic

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** Forwards FCM messages and token refreshes, configuring the SDK first if a push woke the app; if your app has its own service, add these calls to it. */
class MeetingLawyersMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        MeetingLawyersPlugin.configureFromSavedArguments(application)
        // MeetingLawyers pushes go to the SDK; handle the rest as your app usually does.
        MeetingLawyersIntegration.onMessageReceived(remoteMessage.data)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        MeetingLawyersPlugin.configureFromSavedArguments(application)
        MeetingLawyersIntegration.onNewToken(token)
    }
}
