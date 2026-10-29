# MeetingPros Ionic + Capacitor Sample

Ionic + Capacitor sample that integrates **lawyers** (MeetingLawyers SDK) plus **doctors and vets**
(MeetingDoctors SDK) on iOS and Android through one small copy-paste plugin: configure both SDKs, sign in
once, open the lawyers, doctors or vets list, a lawyer's chat, the doctors features, log out and receive the
push notifications of both.

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

The native code that imports the SDKs is the same `MeetingProsIntegration` file as in the native samples
([iOS](../ios/), [Android](../android/)); the plugin only translates the calls. Ask for your MeetingPros API
keys (lawyers and doctors) at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Copy the plugin:**

| File | Role |
|------|------|
| [`src/plugins/meeting-pros/`](src/plugins/meeting-pros/definitions.ts) | TypeScript API: `configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openLawyerChat`, `availableFeatures`, `openFeature`, `isAuthenticated`, `logout` |
| [`ios/App/App/MeetingProsPlugin.swift`](ios/App/App/MeetingProsPlugin.swift) + [`MeetingProsIntegration.swift`](ios/App/App/MeetingProsIntegration.swift) | iOS bridge and the file that owns both SDKs |
| [`ios/App/App/MyViewController.swift`](ios/App/App/MyViewController.swift) | `CAPBridgeViewController` subclass that registers the plugin inside a navigation controller, so native screens are pushed |
| [`android/.../MeetingProsPlugin.kt`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingProsPlugin.kt) + [`MeetingProsIntegration.kt`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingProsIntegration.kt) | Android bridge and the file that owns both SDKs |
| [`android/.../MeetingProsMessagingService.kt`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingProsMessagingService.kt) | Routes FCM messages and tokens to both SDKs |

**2. iOS.** Add with Swift Package Manager `ios-sdk-spm-meetinglawyers` (exact `2.2.1`, product
`MeetingLawyers`), `meetingdoctors-sdk-spm` (exact `11.6.3`, product `MeetingDoctorsSDKWrapper`) and
`firebase-ios-sdk` (exact `12.15.0`, product `FirebaseMessaging`). Use `MyViewController` as the bridge
controller, embedded in a navigation controller (see `Main.storyboard`), add your `GoogleService-Info.plist`,
and in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`:

```swift
FirebaseApp.configure()
MeetingProsIntegration.shared.startHandlingPushNotifications()
```

This makes the integration the `UNUserNotificationCenter.delegate`: route your own notifications through it, or
forward the ones it does not own from your delegate. A push tapped before `configure` finishes only opens the app.
Add `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` to `Info.plist` (photos, audio messages and
video calls), and in **Signing & Capabilities** add *Push Notifications* and *Background Modes → Remote
notifications* (see [`App.entitlements`](ios/App/App/App.entitlements)).

**3. Android.** The plugin is Kotlin, so apply `org.jetbrains.kotlin.android`. Add the MeetingDoctors
and MeetingLawyers repositories (both public, no credentials) to `android/build.gradle`:

```groovy
allprojects {
    repositories {
        maven { url "https://storage.googleapis.com/production-mobile-sdks/android/" }
        maven {
            url "https://sdk-download.meetinglawyers.com/android/maven/"
            content { includeGroup "com.meetinglawyers" }
        }
    }
}
```

Then the dependencies to `android/app/build.gradle`, plus the `google-services` and `firebase-crashlytics`
plugins:

```groovy
implementation "com.meetinglawyers:sdk:2.1.16"
implementation "com.meetingdoctors:customer-chat-sdk:2.9.0"
implementation "com.meetingdoctors:videocall-sdk:3.0.22"
implementation "com.meetingdoctors:meetingdoctors-security-sdk:1.1.0"
implementation platform("com.google.firebase:firebase-bom:32.7.1")
implementation "com.google.firebase:firebase-messaging"
```

Register the plugin in [`MainActivity`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MainActivity.java)
(`registerPlugin(MeetingProsPlugin.class)` before `super.onCreate`), declare `MeetingProsMessagingService` in
the manifest and add your `google-services.json`. Two template changes the MeetingDoctors SDK needs:

- The app theme must descend from `Theme.MaterialComponents` (see [`styles.xml`](android/app/src/main/res/values/styles.xml)).
- Remove the template's `androidx.core.content.FileProvider` from the manifest: MeetingDoctors declares its own.

`configure` blocks the main thread for a couple of seconds while both SDKs start; later calls (a web reload)
do nothing. The plugin saves its arguments, so a push that wakes the killed app configures the SDKs before it
is routed. The video call SDK takes every data push that is not a lawyers or doctors chat one: only
notification-only pushes reach your own code (see the [Android README](../android/README.md)). It also merges
extra permissions, listed there.

**4. Use it** from your TypeScript:

```ts
import { MeetingPros } from './plugins/meeting-pros';

await MeetingPros.configure({ lawyersApiKey, doctorsApiKey, environment: 'DEV' }); // DEV = lawyers demo + doctors staging
await MeetingPros.configureTheme({ primaryColor: '#2E7D6B' });
await MeetingPros.authenticate({ userId });             // both SDKs, plus push permission and token
await MeetingPros.openProfessionalList({ type: 'vets' }); // 'lawyers', 'doctors' or 'vets'
await MeetingPros.openLawyerChat({ professionalHash });
const { features } = await MeetingPros.availableFeatures(); // e.g. ['medicalHistory', 'videoCall']
await MeetingPros.openFeature({ feature: 'medicalHistory' });
await MeetingPros.logout();                              // both SDKs
```

**5. Push.** Share your Firebase credentials with MeetingLawyers as described in the push guides for
[iOS](https://developer.meetinglawyers.com/docs/ios/firebase/) and
[Android](https://developer.meetinglawyers.com/docs/android/push-notifications/).

The contract the plugin fulfils is in [`specs/meetingpros/`](../../specs/meetingpros/spec.md).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../../README.md#credentials). Only the
   `ML_*` and `MD_*` values reach the web bundle ([`vite.config.ts`](vite.config.ts)).
2. Requirements: Node 22+, Xcode 26+ and Android Studio.

```bash
npm install
npm run ios       # or: npm run android
```

3. **Sign in** → open a list → tap a professional to chat. The doctors features are enabled only when the
   company has them. On iOS, run it signed (the default): unsigned builds cannot use the keychain.
