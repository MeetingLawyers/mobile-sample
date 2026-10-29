# MeetingLawyers Android SDK Sample

Native Android (Kotlin) sample that configures the MeetingLawyers SDK, authenticates a user, opens the
professional list or a chat, logs out and receives push notifications over FCM.

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

Every SDK call lives in one file you copy. Ask for your API key at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Add the SDK.** It is served from a public Maven repository, no credentials needed. In
`settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://sdk-download.meetinglawyers.com/android/maven/")
            content { includeGroup("com.meetinglawyers") }
        }
    }
}
```

Declare the Firebase plugins in the root `build.gradle.kts` (the SDK brings Firebase Crashlytics, so its
plugin is required):

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
    id("com.google.firebase.crashlytics") version "2.9.9" apply false
}
```

And apply them in `app/build.gradle.kts`:

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
| [`MeetingLawyersMessagingService.kt`](app/src/main/java/com/meetinglawyers/sample/MeetingLawyersMessagingService.kt) | Forwards FCM messages and tokens. If your app already has a `FirebaseMessagingService`, add its two calls to yours instead |

Register the service in `AndroidManifest.xml`:

```xml
<service android:name=".MeetingLawyersMessagingService" android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

**3. Configure it on startup**, in your `Application.onCreate`:

```kotlin
MeetingLawyersIntegration.configure(this, apiKey = "<your API key>", isProduction = false)
// Every color is optional; the ones left out keep the SDK default
MeetingLawyersIntegration.configureTheme(MeetingLawyersIntegration.Theme(primaryColor = Color.parseColor("#2E7D6B")))
```

**4. Use it** from your screens:

```kotlin
MeetingLawyersIntegration.authenticate("<user id>") { error -> /* null on success, on the main thread */ }
MeetingLawyersIntegration.openProfessionalList(activity)
MeetingLawyersIntegration.openChat(activity, professionalHash)
MeetingLawyersIntegration.logout { error -> }
```

**5. Push notifications.** Add your `google-services.json` to `app/`, ask for the `POST_NOTIFICATIONS`
permission on Android 13+ after signing in (see [`MainActivity.kt`](app/src/main/java/com/meetinglawyers/sample/MainActivity.kt)),
and share your Firebase credentials with MeetingLawyers as described in the
[push notifications guide](https://developer.meetinglawyers.com/docs/android/push-notifications/).

**6. Backups.** Keep the SDK session on the device: set `android:allowBackup="false"` and point
`android:dataExtractionRules` to rules that exclude everything, like
[`data_extraction_rules.xml`](app/src/main/res/xml/data_extraction_rules.xml) (see `AndroidManifest.xml`).

The contract each call fulfils is in [`specs/`](../specs/).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../README.md#credentials).
   `ML_API_KEY`, `ML_USER_ID` and `ML_ENVIRONMENT` reach the app through `BuildConfig`
   ([`Constants.kt`](app/src/main/java/com/meetinglawyers/sample/Constants.kt)).
2. Open this `android/` folder in Android Studio and run `app`, or `./gradlew installDebug`.
3. **Sign in** → **Open professional list** → tap a professional to chat. You can also open a chat by
   professional hash.

The sample ships the Firebase client config of `com.meetinglawyers.meetingpreview.dev` (MeetingPreview
demo app); with your own app, bring your own.
