# MeetingLawyers Ionic + Capacitor Sample

[Ionic](https://ionicframework.com/) + [Capacitor](https://capacitorjs.com/) sample that integrates the
**MeetingLawyers SDK** on iOS and Android through one small copy-paste plugin: configure the SDK, sign in,
open the professional list or a chat, log out and receive push notifications. For lawyers plus doctors and
vets, see the [MeetingPros Capacitor sample](../meetingpros/capacitor/).

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

The native code that imports the SDK is the same `MeetingLawyersIntegration` file as in the native samples
([iOS](../ios/), [Android](../android/)); a local Capacitor plugin only translates the calls. No npm package
is needed. Ask for your API key at [support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Copy the plugin:**

| File | Role |
|------|------|
| [`src/plugins/meeting-lawyers/`](src/plugins/meeting-lawyers/definitions.ts) | TypeScript API: `configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openChat`, `isAuthenticated`, `logout` |
| [`ios/App/App/MeetingLawyersPlugin.swift`](ios/App/App/MeetingLawyersPlugin.swift) + [`MeetingLawyersIntegration.swift`](ios/App/App/MeetingLawyersIntegration.swift) | iOS plugin and the file that owns the SDK |
| [`ios/App/App/MyViewController.swift`](ios/App/App/MyViewController.swift) | Bridge view controller: registers the plugin and hides the navigation bar over the web view |
| [`android/.../MeetingLawyersPlugin.kt`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersPlugin.kt) + [`MeetingLawyersIntegration.kt`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersIntegration.kt) | Android plugin and the file that owns the SDK (change their `package` line) |
| [`android/.../MeetingLawyersMessagingService.kt`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersMessagingService.kt) | Forwards FCM messages and tokens to the SDK, configuring it from the saved values when a push wakes the app |

**2. iOS.** In `ios/App/App.xcodeproj` add with Swift Package Manager `ios-sdk-spm-meetinglawyers` (exact
`2.2.1`, product `MeetingLawyers`) and `firebase-ios-sdk` (exact `12.15.0`, product `FirebaseMessaging`). Then:

- Embed the bridge view controller (`MyViewController`) in a navigation controller, so native screens are
  pushed: see [`Main.storyboard`](ios/App/App/Base.lproj/Main.storyboard).
- In [`AppDelegate.swift`](ios/App/App/AppDelegate.swift): `FirebaseApp.configure()` and
  `MeetingLawyersIntegration.shared.startHandlingPushNotifications()` on launch.
- Add your `GoogleService-Info.plist`, *Push Notifications* and *Background Modes → Remote notifications*
  capabilities, and `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` to `Info.plist`.

**3. Android.** In `android/build.gradle` add the Kotlin, `google-services` (4.4.4) and
`firebase-crashlytics` (2.9.9) Gradle plugins (the SDK brings Crashlytics, so its plugin is required) and the
MeetingLawyers repository (public, no credentials):

```groovy
allprojects {
    repositories {
        maven {
            url "https://sdk-download.meetinglawyers.com/android/maven/"
            content { includeGroup "com.meetinglawyers" }
        }
    }
}
```

Apply the three plugins in `android/app/build.gradle` and add the dependencies:

```groovy
implementation "com.meetinglawyers:sdk:2.1.16"
implementation platform("com.google.firebase:firebase-bom:32.7.1")
implementation "com.google.firebase:firebase-messaging"
```

Then:

- Call `registerPlugin(MeetingLawyersPlugin.class)` before `super.onCreate` in
  [`MainActivity`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MainActivity.java).
- Declare `MeetingLawyersMessagingService` in the manifest and add your `google-services.json`.

**4. Use it** from TypeScript:

```ts
import { MeetingLawyers } from './plugins/meeting-lawyers';

await MeetingLawyers.configure({ apiKey, environment: 'DEV' }); // demo environment; defaults to 'PROD'
await MeetingLawyers.configureTheme({ primaryColor: '#2E7D6B' }); // every color optional
await MeetingLawyers.authenticate({ userId });  // plus push permission and token
await MeetingLawyers.openProfessionalList();     // tap a professional to chat
await MeetingLawyers.openChat({ professionalHash });
await MeetingLawyers.logout();
```

Errors from the native side reject the promise with a readable message.

**5. Push.** Share your Firebase credentials with MeetingLawyers as described in the push guides for
[iOS](https://developer.meetinglawyers.com/docs/ios/firebase/) and
[Android](https://developer.meetinglawyers.com/docs/android/push-notifications/).

The contract each call fulfils is in [`specs/`](../specs/).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../README.md#credentials). Only the
   `ML_*` values reach the web bundle ([`vite.config.ts`](vite.config.ts)).
2. Requirements: Node 22+, Xcode 26+ and Android Studio.

```bash
npm install
npm run ios       # or: npm run android
```

3. **Sign in** → **Open professional list** → tap a professional to chat. On iOS, run it signed (the
   default): unsigned builds cannot use the keychain.
