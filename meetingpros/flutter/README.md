# MeetingPros Flutter Sample

Flutter sample that integrates **lawyers** (MeetingLawyers SDK) plus **doctors and vets** (MeetingDoctors
SDK) on iOS and Android through one small copy-paste bridge: configure both SDKs, sign in once, open the
lawyers, doctors or vets list, a lawyer's chat, the doctors features, log out and receive the push
notifications of both.

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

The native code that imports the SDKs is the same `MeetingProsIntegration` file as in the native samples
([iOS](../ios/), [Android](../android/)); a method channel only translates the calls. No Flutter package is
needed. Ask for your MeetingPros API keys (lawyers and doctors) at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Copy the bridge:**

| File | Role |
|------|------|
| [`lib/meeting_pros/meeting_pros.dart`](lib/meeting_pros/meeting_pros.dart) | Dart API: `configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openLawyerChat`, `availableFeatures`, `openFeature`, `isAuthenticated`, `logout` |
| [`ios/Runner/MeetingProsChannel.swift`](ios/Runner/MeetingProsChannel.swift) + [`MeetingProsIntegration.swift`](ios/Runner/MeetingProsIntegration.swift) | iOS channel and the file that owns both SDKs |
| [`android/.../MeetingProsChannel.kt`](android/app/src/main/kotlin/com/meetinglawyers/meetingpros_sample/MeetingProsChannel.kt) + [`MeetingProsIntegration.kt`](android/app/src/main/kotlin/com/meetinglawyers/meetingpros_sample/MeetingProsIntegration.kt) | Android channel and the file that owns both SDKs (change their `package` line) |
| [`android/.../MeetingProsMessagingService.kt`](android/app/src/main/kotlin/com/meetinglawyers/meetingpros_sample/MeetingProsMessagingService.kt) | Routes FCM messages and tokens to both SDKs |

**2. iOS.** In `ios/Runner.xcworkspace` add with Swift Package Manager `ios-sdk-spm-meetinglawyers` (exact
`2.2.1`, product `MeetingLawyers`), `meetingdoctors-sdk-spm` (exact `11.6.3`, product
`MeetingDoctorsSDKWrapper`) and `firebase-ios-sdk` (exact `12.15.0`, product `FirebaseMessaging`). Then:

- Embed the `FlutterViewController` in a navigation controller with class `FlutterNavigationController`
  (defined in `MeetingProsChannel.swift`), so native screens are pushed: see [`Main.storyboard`](ios/Runner/Base.lproj/Main.storyboard).
- In [`AppDelegate.swift`](ios/Runner/AppDelegate.swift): `FirebaseApp.configure()` and
  `MeetingProsIntegration.shared.startHandlingPushNotifications()` on launch, and
  `MeetingProsChannel.register(with:)` in `didInitializeImplicitFlutterEngine`.
- Add your `GoogleService-Info.plist`, *Push Notifications* and *Background Modes → Remote notifications*
  capabilities, and `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` to `Info.plist`.

**3. Android.** Add the MeetingDoctors and MeetingLawyers repositories (both public, no
credentials) to `android/build.gradle.kts`:

```kotlin
allprojects {
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

The `google-services` (4.4.4) and `firebase-crashlytics` (2.9.9) plugins (declared in `settings.gradle.kts`,
applied in `app/build.gradle.kts`), `minSdk = 24`, and the dependencies in `app/build.gradle.kts`:

```kotlin
implementation("com.meetinglawyers:sdk:2.1.16")
implementation("com.meetingdoctors:customer-chat-sdk:2.9.0")
implementation("com.meetingdoctors:videocall-sdk:3.0.22")
implementation("com.meetingdoctors:meetingdoctors-security-sdk:1.1.0")
implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
implementation("com.google.firebase:firebase-messaging")
```

Then:

- `MainActivity` must extend `FlutterFragmentActivity` (the MeetingDoctors lists are fragments) and call
  `MeetingProsChannel.register(flutterEngine, this)` in `configureFlutterEngine`: see [`MainActivity.kt`](android/app/src/main/kotlin/com/meetinglawyers/meetingpros_sample/MainActivity.kt).
- `LaunchTheme` and `NormalTheme` must descend from `Theme.MaterialComponents` (see [`styles.xml`](android/app/src/main/res/values/styles.xml)).
- Declare `MeetingProsMessagingService` in the manifest and add your `google-services.json`.

**4. Use it** from Dart:

```dart
import 'meeting_pros/meeting_pros.dart';

await MeetingPros.configure(lawyersApiKey: lawyersKey, doctorsApiKey: doctorsKey, isProduction: false); // demo + staging
await MeetingPros.configureTheme('#2E7D6B');
await MeetingPros.authenticate(userId);                 // both SDKs, plus push permission and token
await MeetingPros.openProfessionalList(ProfessionalType.vets); // lawyers, doctors or vets
await MeetingPros.openLawyerChat(professionalHash);
final features = await MeetingPros.availableFeatures(); // e.g. {DoctorsFeature.medicalHistory}
await MeetingPros.openFeature(DoctorsFeature.medicalHistory);
await MeetingPros.logout();                             // both SDKs
```

Errors from the native side arrive as `PlatformException`.

**5. Push.** Share your Firebase credentials with MeetingLawyers as described in the push guides for
[iOS](https://developer.meetinglawyers.com/docs/ios/firebase/) and
[Android](https://developer.meetinglawyers.com/docs/android/push-notifications/).

The contract the bridge fulfils is in [`specs/meetingpros/`](../../specs/meetingpros/spec.md).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../../README.md#credentials).
2. Requirements: Flutter 3.47+, Xcode 26+ and Android Studio.

```bash
flutter run --dart-define-from-file=../../.env
```

3. **Sign in** → open a list → tap a professional to chat. The doctors features are enabled only when the
   company has them. On iOS, run it signed (the default): unsigned builds cannot use the keychain.
