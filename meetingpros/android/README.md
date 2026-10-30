# MeetingPros Android Sample

Native Android (Kotlin) sample that integrates **lawyers** (MeetingLawyers SDK) plus **doctors and vets**
(MeetingDoctors SDK) behind one file: configure both SDKs, sign in once, open the lawyers, doctors or vets
list, a lawyer's chat, the doctors features (video call, medical history, My health, booking,
appointments), log out and receive the push notifications of both.

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

Both SDKs live behind one file you copy: the rest of your app never imports them. Ask for your MeetingPros
API keys (lawyers and doctors) at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Add the SDKs.** In `settings.gradle.kts`, the MeetingDoctors and MeetingLawyers repositories
(both public, no credentials):

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/production-mobile-sdks/android/") }
        maven {
            url = uri("https://sdk-download.meetinglawyers.com/android/maven/")
            content { includeGroup("com.meetinglawyers") }
        }
    }
}
```

In `app/build.gradle.kts` (the SDKs bring Firebase Crashlytics, so its plugin is required):

```kotlin
plugins {
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

dependencies {
    implementation("com.meetinglawyers:sdk:2.1.16")
    implementation("com.meetingdoctors:customer-chat-sdk:2.9.0")
    implementation("com.meetingdoctors:videocall-sdk:3.0.22")
    implementation("com.meetingdoctors:meetingdoctors-security-sdk:1.1.0")
    implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
}
```

**2. Copy two files** into your app and change their `package` line:

| File | What it does |
|------|------|
| [`MeetingProsIntegration.kt`](app/src/main/java/com/meetinglawyers/meetingpros/sample/MeetingProsIntegration.kt) | Every SDK call: `configure`, `configureTheme`, `authenticate`, `openProfessionalList(LAWYERS / DOCTORS / VETS)`, `openLawyerChat`, `availableFeatures`, `open(feature)`, `isAuthenticated`, `logout`, and the push routing |
| [`MeetingProsMessagingService.kt`](app/src/main/java/com/meetinglawyers/meetingpros/sample/MeetingProsMessagingService.kt) | Forwards FCM messages and tokens. If your app already has a `FirebaseMessagingService`, add its two calls to yours instead |

Register the service in `AndroidManifest.xml`:

```xml
<service android:name=".MeetingProsMessagingService" android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

Two template changes the MeetingDoctors SDK needs:

- The app theme must descend from `Theme.MaterialComponents` (the `Theme.Material3` ones do).
- MeetingDoctors declares `androidx.core.content.FileProvider`: remove your app's provider with the same class
  from the manifest, or the manifest merge fails.

The video call SDK merges extra permissions into your manifest, among them `READ_PHONE_STATE` and
`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, and a required `android.hardware.camera` feature (Google Play hides
the app from devices without a camera unless you override it with `android:required="false"` and
`tools:replace="android:required"`).

**3. Configure it on startup**, in your `Application.onCreate`. `MainActivity` is what opens when a doctors
push is tapped:

```kotlin
MeetingProsIntegration.configure(
    this, lawyersApiKey = "<lawyers key>", doctorsApiKey = "<doctors key>",
    isProduction = false, pushActivity = MainActivity::class.java,
)
MeetingProsIntegration.configureTheme("#2E7D6B")
```

With `isProduction = false` lawyers use the demo environment and doctors the staging one. `configure` blocks
the main thread for a couple of seconds while both SDKs start; calling it again does nothing.

**4. Use it** from a coroutine (for example `lifecycleScope.launch { … }`):

```kotlin
MeetingProsIntegration.authenticate("<user id>")                       // both SDKs
MeetingProsIntegration.openProfessionalList(activity, ProfessionalType.VETS)   // LAWYERS, DOCTORS or VETS
MeetingProsIntegration.openLawyerChat(activity, professionalHash)
val features = MeetingProsIntegration.availableFeatures()              // e.g. [VIDEO_CALL, MEDICAL_HISTORY]
MeetingProsIntegration.open(activity, DoctorsFeature.MEDICAL_HISTORY)
MeetingProsIntegration.logout()                                         // both SDKs
```

**5. Push notifications.** Add your `google-services.json` to `app/`, ask for the `POST_NOTIFICATIONS`
permission on Android 13+ after signing in (see [`MainActivity.kt`](app/src/main/java/com/meetinglawyers/meetingpros/sample/MainActivity.kt)),
and share your Firebase credentials with MeetingLawyers as described in the
[push notifications guide](https://developer.meetinglawyers.com/docs/android/push-notifications/).

`onMessageReceived` returns `false` for the pushes that are not for the SDKs, so you can handle yours. The video
call SDK cannot tell its pushes apart, though: it takes every data push that is not a lawyers or doctors chat
one, so only notification-only pushes reach your code.

The contract it fulfils is in [`specs/meetingpros/`](../../specs/meetingpros/spec.md).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../../README.md#credentials):
   `ML_API_KEY` is the MeetingPros company key, `MD_API_KEY` its MeetingDoctors key and `ML_USER_ID` a user of
   both.
2. Open this `meetingpros/android/` folder in Android Studio and run `app`, or `./gradlew installDebug`.
3. **Sign in** → open a list → tap a professional to chat. The doctors features are enabled only when the
   company has them.
