package com.meetinglawyers.sample.ionic;

import androidx.annotation.NonNull;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.meetinglawyers.sdk.MeetingLawyersSDK;

/**
 * Forwards FCM messages and token refreshes to the MeetingLawyers SDK.
 * If your app already has its own FirebaseMessagingService, add these two
 * forwards to it instead of registering this one.
 */
public class MeetingLawyersFirebaseService extends FirebaseMessagingService {

    /** Hands MeetingLawyers pushes to the SDK; other pushes stay untouched. */
    @Override
    public void onMessageReceived(@NonNull RemoteMessage message) {
        super.onMessageReceived(message);
        String data = message.getData().get("data");
        if (data != null && MeetingLawyersSDK.Companion.isInitialized()) {
            MeetingLawyersSDK.Companion.getClientInstance().onPushMessageReceived(data);
        }
    }

    /** Keeps the SDK token registration up to date. */
    @Override
    public void onNewToken(@NonNull String token) {
        super.onNewToken(token);
        if (MeetingLawyersSDK.Companion.isInitialized()) {
            MeetingLawyersSDK.Companion.getClientInstance().onNewTokenReceived(token);
        }
    }
}
