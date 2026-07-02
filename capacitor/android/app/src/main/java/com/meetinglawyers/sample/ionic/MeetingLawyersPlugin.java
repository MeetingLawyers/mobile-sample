package com.meetinglawyers.sample.ionic;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.meetinglawyers.sdk.CustomerSdkBuildMode;
import com.meetinglawyers.sdk.MeetingLawyersSDK;
import com.meetinglawyers.sdk.SDKCallbackWithoutData;
import com.meetinglawyers.sdk.domain.logger.LogMode;

import java.util.Locale;

/**
 * Capacitor bridge to the MeetingLawyers Android SDK.
 * Self-contained: copy this file (plus src/plugins/meeting-lawyers/) into your
 * own Capacitor project and register it in your MainActivity.
 */
@CapacitorPlugin(name = "MeetingLawyers")
public class MeetingLawyersPlugin extends Plugin {

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
