package com.meetinglawyers.sample.ionic;

import android.Manifest;
import android.os.Build;

import com.getcapacitor.JSObject;
import com.getcapacitor.PermissionState;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.meetinglawyers.sdk.CustomerSdkBuildMode;
import com.meetinglawyers.sdk.MeetingLawyersClient;
import com.meetinglawyers.sdk.MeetingLawyersSDK;
import com.meetinglawyers.sdk.SDKCallbackWithoutData;
import com.meetinglawyers.sdk.domain.logger.LogMode;

import java.util.Locale;
import java.util.function.Consumer;

/**
 * Capacitor bridge to the MeetingLawyers Android SDK.
 * Self-contained: copy this file (plus src/plugins/meeting-lawyers/ and
 * MeetingLawyersFirebaseService.java for push) into your own Capacitor project
 * and register it in your MainActivity.
 */
@CapacitorPlugin(name = "MeetingLawyers", permissions = {
        @Permission(strings = {Manifest.permission.POST_NOTIFICATIONS}, alias = MeetingLawyersPlugin.NOTIFICATIONS)
})
public class MeetingLawyersPlugin extends Plugin {

    static final String NOTIFICATIONS = "notifications";

    /** Initializes the SDK with the company API key and target environment. */
    @PluginMethod
    public void configure(PluginCall call) {
        String apiKey = call.getString("apiKey");
        if (apiKey == null || apiKey.isEmpty()) {
            call.reject("apiKey is required");
            return;
        }
        boolean isDevelopment = "DEV".equals(call.getString("environment"));
        CustomerSdkBuildMode buildMode = isDevelopment ? CustomerSdkBuildMode.DEV : CustomerSdkBuildMode.PROD;
        LogMode logMode = isDevelopment ? LogMode.VERBOSE : LogMode.NONE;
        getActivity().runOnUiThread(() -> {
            try {
                new MeetingLawyersSDK(getActivity().getApplication(), apiKey, buildMode, Locale.getDefault(), logMode)
                        .build();
                call.resolve();
            } catch (Exception e) {
                call.reject("Configure failed: " + e.getMessage());
            }
        });
    }

    /** Applies the theme colors supported on Android; unsupported keys are ignored. */
    @PluginMethod
    public void configureTheme(PluginCall call) {
        if (notConfigured(call)) {
            return;
        }
        MeetingLawyersClient client = MeetingLawyersSDK.Companion.getClientInstance();
        applyColor(call, "primaryColor", client::setPrimaryColor);
        applyColor(call, "secondaryColor", client::setSecondaryColor);
        applyColor(call, "navigationBarColor", client::setNavigationBarColor);
        applyColor(call, "incomingMessageColor", client::setIncomingMessageBgColor);
        applyColor(call, "outgoingMessageColor", client::setOngoingMessageBgColor);
        applyColor(call, "professionalSpecialityTextColor", client::setProfessionalSpecialityTextColor);
        applyColor(call, "unreadMessagesBadgeColor", client::setUnreadMessagesBadgeBgColor);
        applyColor(call, "professionalDescriptionColor", client::setProfessionalDescriptionColor);
        applyColor(call, "disabledProfessionalColor", client::setDisabledProfessionalColor);
        call.resolve();
    }

    /** Applies a parsed color to the given setter when the option is present and valid. */
    private void applyColor(PluginCall call, String key, Consumer<Integer> setter) {
        Integer color = color(call.getString(key));
        if (color != null) {
            setter.accept(color);
        }
    }

    /** Parses a "#RRGGBB" or "#RRGGBBAA" hex string into an ARGB int. */
    private static Integer color(String hex) {
        if (hex == null) {
            return null;
        }
        String value = hex.replace("#", "").trim();
        try {
            if (value.length() == 6) {
                return 0xFF000000 | Integer.parseInt(value, 16);
            }
            if (value.length() == 8) {
                long rgba = Long.parseLong(value, 16);
                long red = (rgba >> 24) & 0xFF;
                long green = (rgba >> 16) & 0xFF;
                long blue = (rgba >> 8) & 0xFF;
                long alpha = rgba & 0xFF;
                return (int) ((alpha << 24) | (red << 16) | (green << 8) | blue);
            }
        } catch (NumberFormatException e) {
            return null;
        }
        return null;
    }

    /** Authenticates the user in the SDK. */
    @PluginMethod
    public void authenticate(PluginCall call) {
        String userId = call.getString("userId");
        if (userId == null || userId.isEmpty()) {
            call.reject("userId is required");
            return;
        }
        if (notConfigured(call)) {
            return;
        }
        MeetingLawyersSDK.Companion.getClientInstance().authenticate(userId, new SDKCallbackWithoutData() {
            @Override
            public void onSuccess() {
                call.resolve();
            }

            @Override
            public void onError(String message) {
                call.reject(message != null ? message : "Authentication failed");
            }
        });
    }

    /** Opens the SDK professional list; tapping a professional opens its chat. */
    @PluginMethod
    public void openProfessionalList(PluginCall call) {
        if (notConfigured(call)) {
            return;
        }
        getActivity().runOnUiThread(() -> {
            MeetingLawyersSDK.Companion.getClientInstance().openProfessionalList(getActivity(), null);
            call.resolve();
        });
    }

    /** Opens the chat with a specific professional by hash. */
    @PluginMethod
    public void openChatWithProfessional(PluginCall call) {
        String professionalHash = call.getString("professionalHash");
        if (professionalHash == null || professionalHash.isEmpty()) {
            call.reject("professionalHash is required");
            return;
        }
        if (notConfigured(call)) {
            return;
        }
        getActivity().runOnUiThread(() -> {
            MeetingLawyersSDK.Companion.getClientInstance().openChatWithProfessional(getActivity(), professionalHash);
            call.resolve();
        });
    }

    /** Asks for notification permission and registers the FCM token with the SDK. */
    @PluginMethod
    public void registerForPushNotifications(PluginCall call) {
        if (notConfigured(call)) {
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
                && getPermissionState(NOTIFICATIONS) != PermissionState.GRANTED) {
            requestPermissionForAlias(NOTIFICATIONS, call, "notificationsPermissionCallback");
            return;
        }
        registerPushToken(call);
    }

    /** Continues push registration after the permission prompt (token works even if denied). */
    @PermissionCallback
    private void notificationsPermissionCallback(PluginCall call) {
        registerPushToken(call);
    }

    /** Fetches the current FCM token and hands it to the SDK. */
    private void registerPushToken(PluginCall call) {
        if (FirebaseApp.getApps(getContext()).isEmpty()) {
            call.reject("Firebase is not configured. Add google-services.json to android/app.");
            return;
        }
        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(task -> {
            if (!task.isSuccessful() || task.getResult() == null) {
                call.reject("Could not fetch the FCM token", (Exception) task.getException());
                return;
            }
            MeetingLawyersSDK.Companion.getClientInstance().onNewTokenReceived(task.getResult());
            call.resolve();
        });
    }

    /** Returns whether a user is currently authenticated in the SDK. */
    @PluginMethod
    public void isAuthenticated(PluginCall call) {
        boolean authenticated = MeetingLawyersSDK.Companion.isInitialized()
                && MeetingLawyersSDK.Companion.getClientInstance().isAuthenticated();
        JSObject result = new JSObject();
        result.put("authenticated", authenticated);
        call.resolve(result);
    }

    /** Logs the user out of the SDK. */
    @PluginMethod
    public void logout(PluginCall call) {
        if (notConfigured(call)) {
            return;
        }
        MeetingLawyersSDK.Companion.getClientInstance().deauthenticate(new SDKCallbackWithoutData() {
            @Override
            public void onSuccess() {
                call.resolve();
            }

            @Override
            public void onError(String message) {
                call.reject(message != null ? message : "Logout failed");
            }
        });
    }

    /** Rejects the call when the SDK has not been configured yet. */
    private boolean notConfigured(PluginCall call) {
        if (MeetingLawyersSDK.Companion.isInitialized()) {
            return false;
        }
        call.reject("SDK not configured. Call configure() first.");
        return true;
    }
}
