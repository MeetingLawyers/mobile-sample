# MeetingLawyers Flutter Sample

Flutter sample that integrates the **MeetingLawyers SDK** on iOS and Android through one small copy-paste
bridge: configure the SDK, sign in, open the professional list or a chat, log out and receive push
notifications. For lawyers plus doctors and vets, see the [MeetingPros Flutter sample](../meetingpros/flutter/).

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

The native code that imports the SDK is the same `MeetingLawyersIntegration` file as in the native samples
([iOS](../ios/), [Android](../android/)); a method channel only translates the calls. No Flutter package is
needed. Ask for your API key at [support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Copy the bridge:**

| File | Role |
|------|------|
| [`lib/meeting_lawyers/meeting_lawyers.dart`](lib/meeting_lawyers/meeting_lawyers.dart) | Dart API: `configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openChat`, `isAuthenticated`, `logout` |
| [`ios/Runner/MeetingLawyersChannel.swift`](ios/Runner/MeetingLawyersChannel.swift) + [`MeetingLawyersIntegration.swift`](ios/Runner/MeetingLawyersIntegration.swift) | iOS channel and the file that owns the SDK |
| [`android/.../MeetingLawyersChannel.kt`](android/app/src/main/kotlin/com/meetinglawyers/sample/flutter/MeetingLawyersChannel.kt) + [`MeetingLawyersIntegration.kt`](android/app/src/main/kotlin/com/meetinglawyers/sample/flutter/MeetingLawyersIntegration.kt) | Android channel and the file that owns the SDK (change their `package` line) |
| [`android/.../MeetingLawyersMessagingService.kt`](android/app/src/main/kotlin/com/meetinglawyers/sample/flutter/MeetingLawyersMessagingService.kt) | Forwards FCM messages and tokens to the SDK, configuring it from the saved values when a push wakes the app |

**2. iOS.** In `ios/Runner.xcworkspace` add with Swift Package Manager `ios-sdk-spm-meetinglawyers` (exact
`2.2.1`, product `MeetingLawyers`) and `firebase-ios-sdk` (exact `12.15.0`, product `FirebaseMessaging`). Then:

- Embed the `FlutterViewController` in a navigation controller with class `FlutterNavigationController`
  (defined in `MeetingLawyersChannel.swift`), so native screens are pushed: see [`Main.storyboard`](ios/Runner/Base.lproj/Main.storyboard).
- In [`AppDelegate.swift`](ios/Runner/AppDelegate.swift): `FirebaseApp.configure()` and
  `MeetingLawyersIntegration.shared.startHandlingPushNotifications()` on launch, and
  `MeetingLawyersChannel.register(with:)` in `didInitializeImplicitFlutterEngine`.
- Add your `GoogleService-Info.plist`, *Push Notifications* and *Background Modes → Remote notifications*
  capabilities, and `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` to `Info.plist`.

**3. Android.** Add the MeetingLawyers repository (public, no credentials) to `android/build.gradle.kts`:

```kotlin
allprojects {
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

The `google-services` (4.4.4) and `firebase-crashlytics` (2.9.9) plugins (declared in `settings.gradle.kts`,
applied in `app/build.gradle.kts`), `minSdk = 24`, and the dependencies in `app/build.gradle.kts`:

```kotlin
implementation("com.meetinglawyers:sdk:2.1.15")
implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
implementation("com.google.firebase:firebase-messaging")
```

Then:

- Call `MeetingLawyersChannel.register(flutterEngine, this)` in `MainActivity.configureFlutterEngine`: see
  [`MainActivity.kt`](android/app/src/main/kotlin/com/meetinglawyers/sample/flutter/MainActivity.kt).
- `LaunchTheme` and `NormalTheme` must be AppCompat-based, e.g. `Theme.MaterialComponents` (see [`styles.xml`](android/app/src/main/res/values/styles.xml)).
- Declare `MeetingLawyersMessagingService` in the manifest and add your `google-services.json`.

**4. Use it** from Dart:

```dart
import 'meeting_lawyers/meeting_lawyers.dart';

await MeetingLawyers.configure(apiKey: apiKey, isProduction: false); // demo environment
await MeetingLawyers.configureTheme(0xFF1E5AA8);
await MeetingLawyers.authenticate(userId);   // plus push permission and token
await MeetingLawyers.openProfessionalList(); // tap a professional to chat
await MeetingLawyers.openChat(professionalHash);
await MeetingLawyers.logout();
```

Errors from the native side arrive as `PlatformException`.

**5. Push.** Share your Firebase credentials with MeetingLawyers as described in the push guides for
[iOS](https://developer.meetinglawyers.com/docs/ios/firebase/) and
[Android](https://developer.meetinglawyers.com/docs/android/push-notifications/).

The contract each call fulfils is in [`specs/`](../specs/).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../README.md#credentials).
2. Requirements: Flutter 3.47+, Xcode 26+ and Android Studio.

```bash
flutter run --dart-define-from-file=../.env
```

3. **Sign in** → **Open professional list** → tap a professional to chat. On iOS, run it signed (the
   default): unsigned builds cannot use the keychain.
