# MeetingLawyers Android SDK Sample

Native Android (Kotlin) sample that configures the MeetingLawyers SDK, authenticates a user, opens the
professional list or a chat, logs out and receives push notifications over FCM.

Check the full documentation at
[developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## How the integration works

Every SDK call lives in one file you can copy into your app:

| File | Role |
|------|------|
| [`MeetingLawyersIntegration.kt`](app/src/main/java/com/meetinglawyers/sample/MeetingLawyersIntegration.kt) | `configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openChat`, `isAuthenticated`, `logout`, and push forwarding |
| [`App.kt`](app/src/main/java/com/meetinglawyers/sample/App.kt) | Configures the SDK in `Application.onCreate` |
| [`SampleMessagingService.kt`](app/src/main/java/com/meetinglawyers/sample/SampleMessagingService.kt) | Forwards FCM messages and token refreshes. If your app already has a `FirebaseMessagingService`, add these two calls to it |
| [`MainActivity.kt`](app/src/main/java/com/meetinglawyers/sample/MainActivity.kt) | The home screen, and the Android 13+ notification permission |

The MeetingLawyers SDK pulls in Firebase Crashlytics, so the `com.google.firebase.crashlytics` Gradle plugin
is required once `google-services.json` is present. The contract each call fulfils is in [`specs/`](../specs/).

## Credentials

Ask for demo credentials (API key, user id and GitHub Packages access) at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com), then fill in the repo-root `.env`
(git-ignored) — see the [root README](../README.md#credentials).

- `ML_API_KEY`, `ML_USER_ID`, `ML_ENVIRONMENT` reach the app through `BuildConfig` ([`Constants.kt`](app/src/main/java/com/meetinglawyers/sample/Constants.kt)).
- `GPR_USER` / `GPR_TOKEN` authenticate against GitHub Packages, where the SDK is served. If they are not in
  `.env`, they are read from `~/.gradle/gradle.properties` or environment variables.

## Run it

Open this `android/` folder in Android Studio and run the `app` configuration, or:

```bash
./gradlew installDebug
```

**Sign in** → **Open professional list** → tap a professional to chat. You can also open a chat directly by
professional hash.
