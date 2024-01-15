package com.meetinglawyers.sample

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.meetinglawyers.sdk.MeetingLawyersClient

class SampleMessagingService: FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        /* Your code to process remoteMessage */

        /* Redirect remoteMessage to SDK */
        MeetingLawyersClient.instance?.onFirebaseMessageReceived(remoteMessage)
    }

    override fun onNewToken(newToken: String) {
        super.onNewToken(newToken)

        /* Register new push token */
        MeetingLawyersClient.instance?.onNewTokenReceived(newToken)
    }
}