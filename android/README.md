# MeetingLawyers Android SDK Sample

Native Android (Kotlin) sample that configures the MeetingLawyers SDK, authenticates a user, opens the
professional list or a chat, logs out and receives push notifications over FCM.

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

Every SDK call lives in one file you copy. Ask for your API key and GitHub Packages access at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Add the SDK.** It is served from GitHub Packages, which needs a GitHub user and a token with
`read:packages`. In `settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/MeetingLawyers/android-sdk-chat/")
            credentials {
                username = providers.gradleProperty("GPR_USER").orNull ?: System.getenv("GPR_USER")
                password = providers.gradleProperty("GPR_TOKEN").orNull ?: System.getenv("GPR_TOKEN")
            }
        }
    }
}
```

In `app/build.gradle.kts` (the SDK brings Firebase Crashlytics, so its plugin is required):

```kotlin
plugins {
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

dependencies {
    implementation("com.meetinglawyers:sdk:2.1.15")
    implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
    implementation("com.google.firebase:firebase-messaging")
}
```

**2. Copy two files** into your app and change their `package` line:

| File | What it does |
|------|------|
| [`MeetingLawyersIntegration.kt`](app/src/main/java/com/meetinglawyers/sample/MeetingLawyersIntegration.kt) | Every SDK call: `configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openChat`, `isAuthenticated`, `logout`, push forwarding |
| [`SampleMessagingService.kt`](app/src/main/java/com/meetinglawyers/sample/SampleMessagingService.kt) | Forwards FCM messages and tokens. If your app already has a `FirebaseMessagingService`, add its two calls to yours instead |

Register the service in `AndroidManifest.xml`:

```xml
<service android:name=".SampleMessagingService" android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

**3. Configure it on startup**, in your `Application.onCreate`:

```kotlin
MeetingLawyersIntegration.configure(this, apiKey = "<your API key>", isProduction = false)
MeetingLawyersIntegration.configureTheme(Color.parseColor("#2E7D6B"))
```

**4. Use it** from your screens:

```kotlin
MeetingLawyersIntegration.authenticate("<user id>") { error -> /* null on success */ }
MeetingLawyersIntegration.openProfessionalList(activity)
MeetingLawyersIntegration.openChat(activity, professionalHash)
MeetingLawyersIntegration.logout { error -> }
```

**5. Push notifications.** Add your `google-services.json` to `app/`, ask for the `POST_NOTIFICATIONS`
permission on Android 13+ after signing in (see [`MainActivity.kt`](app/src/main/java/com/meetinglawyers/sample/MainActivity.kt)),
and share your Firebase credentials with MeetingLawyers as described in the
[push notifications guide](https://developer.meetinglawyers.com/docs/android/push-notifications/).

The contract each call fulfils is in [`specs/`](../specs/).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../README.md#credentials).
   `ML_API_KEY`, `ML_USER_ID` and `ML_ENVIRONMENT` reach the app through `BuildConfig`
   ([`Constants.kt`](app/src/main/java/com/meetinglawyers/sample/Constants.kt)); `GPR_USER` / `GPR_TOKEN`
   can also come from `~/.gradle/gradle.properties` or environment variables.
2. Open this `android/` folder in Android Studio and run `app`, or `./gradlew installDebug`.
3. **Sign in** → **Open professional list** → tap a professional to chat. You can also open a chat by
   professional hash.

The sample ships the Firebase client config of `com.meetinglawyers.sdk.sample` (MeetingLawyers demo
project); with your own app, bring your own.
