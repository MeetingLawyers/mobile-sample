package com.meetinglawyers.sample

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.meetinglawyers.sdk.MeetingLawyersSDK

class SampleMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        /* Your code to process remoteMessage */

        /* Redirect MeetingLawyers pushes to the SDK */
        val data = remoteMessage.data["data"] ?: return
        if (MeetingLawyersSDK.isInitialized()) {
            MeetingLawyersSDK.getClientInstance().onPushMessageReceived(data)
        }
    }

    override fun onNewToken(newToken: String) {
        super.onNewToken(newToken)

        /* Register new push token */
        if (MeetingLawyersSDK.isInitialized()) {
            MeetingLawyersSDK.getClientInstance().onNewTokenReceived(newToken)
        }
    }
}
