package com.meetinglawyers.sample.ionic;

import androidx.annotation.NonNull;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.meetinglawyers.sdk.MeetingLawyersSDK;

/**
 * Forwards FCM messages and token refreshes to the MeetingLawyers SDK, configuring it first when a push
 * wakes the app. If your app already has its own FirebaseMessagingService, add these two forwards to it.
 */
public class MeetingLawyersFirebaseService extends FirebaseMessagingService {

    /** Hands MeetingLawyers pushes to the SDK; other pushes stay untouched. */
    @Override
    public void onMessageReceived(@NonNull RemoteMessage message) {
        super.onMessageReceived(message);
        String data = message.getData().get("data");
        if (data != null && MeetingLawyersPlugin.restoreConfiguration(getApplication())) {
            MeetingLawyersSDK.Companion.getClientInstance().onPushMessageReceived(data);
        }
    }

    /** Forwards token refreshes once a user is signed in. */
    @Override
    public void onNewToken(@NonNull String token) {
        super.onNewToken(token);
        if (MeetingLawyersPlugin.restoreConfiguration(getApplication())
                && MeetingLawyersSDK.Companion.getClientInstance().isAuthenticated()) {
            MeetingLawyersSDK.Companion.getClientInstance().onNewTokenReceived(token);
        }
    }
}
