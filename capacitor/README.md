# MeetingLawyers Ionic + Capacitor Sample

Sample app showing how to integrate the **MeetingLawyers SDKs** (iOS and Android) in an
[Ionic](https://ionicframework.com/) + [Capacitor](https://capacitorjs.com/) app: initialize the SDK,
authenticate a user, open the native professional list and chat with a professional.

Check the full documentation at
[developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

All the SDK integration lives in a small **copy-paste wrapper** (a local Capacitor plugin), so the rest of
your app never imports the SDKs. Ask for your API key and GitHub Packages access at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Copy the wrapper:**

| File | Role |
|------|------|
| [`src/plugins/meeting-lawyers/`](src/plugins/meeting-lawyers/definitions.ts) | TypeScript API (`configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openChatWithProfessional`, `registerForPushNotifications`, `isAuthenticated`, `logout`) |
| [`ios/App/App/MeetingLawyersPlugin.swift`](ios/App/App/MeetingLawyersPlugin.swift) | iOS bridge to the `MeetingLawyers` SDK, also the FCM / notification delegate |
| [`ios/App/App/MyViewController.swift`](ios/App/App/MyViewController.swift) | `CAPBridgeViewController` subclass that registers the plugin and hosts a navigation controller, so native screens are pushed |
| [`android/.../MeetingLawyersPlugin.java`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersPlugin.java) | Android bridge to the `com.meetinglawyers:sdk` library |
| [`android/.../MeetingLawyersFirebaseService.java`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersFirebaseService.java) | Forwards FCM messages and tokens. If your app has its own `FirebaseMessagingService`, forward `onMessageReceived` / `onNewToken` from it instead |

Change the `package` line of the copied `.java` files to your app's package.

**2. iOS.** Add with Swift Package Manager
[`ios-sdk-spm-meetinglawyers`](https://github.com/MeetingLawyers/ios-sdk-spm-meetinglawyers) (exact `2.2.1`,
product `MeetingLawyers`) and `firebase-ios-sdk` (product `FirebaseMessaging`). Set `MyViewController` as the
bridge controller, embedded in a navigation controller (see `Main.storyboard`), and add your
`GoogleService-Info.plist`. Add `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` to `Info.plist`
(the chat sends photos and audio messages), and in **Signing & Capabilities → Push Notifications + Background
Modes → Remote notifications**. Then hook push on launch, in
[`AppDelegate`](ios/App/App/AppDelegate.swift)'s `application(_:didFinishLaunchingWithOptions:)`:

```swift
FirebaseApp.configure()
MeetingLawyersPlugin.startHandlingPushNotifications()
```

**3. Android.** In `android/build.gradle`, add the Firebase Gradle plugins (the SDK brings Crashlytics, so
its plugin is required) and the GitHub Packages repository (it needs a GitHub user and a token with
`read:packages`):

```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.4'
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'
    }
}

allprojects {
    repositories {
        maven {
            url "https://maven.pkg.github.com/MeetingLawyers/android-sdk-chat/"
            credentials {
                username = findProperty('GPR_USER') ?: System.getenv('GPR_USER')
                password = findProperty('GPR_TOKEN') ?: System.getenv('GPR_TOKEN')
            }
        }
    }
}
```

Then, in `android/app/build.gradle`, the dependencies and the two plugins:

```groovy
implementation "com.meetinglawyers:sdk:2.1.15"
implementation platform("com.google.firebase:firebase-bom:32.7.1")
implementation "com.google.firebase:firebase-messaging"

apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'
```

Register the plugin in [`MainActivity`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MainActivity.java)
(`registerPlugin(MeetingLawyersPlugin.class)` before `super.onCreate`), add your `google-services.json` and
declare the service in `AndroidManifest.xml`:

```xml
<service android:name=".MeetingLawyersFirebaseService" android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

Keep the SDK session on the device: set `android:allowBackup="false"` and point `android:dataExtractionRules`
to rules that exclude everything, like
[`data_extraction_rules.xml`](android/app/src/main/res/xml/data_extraction_rules.xml).

**4. Push.** Share your Firebase credentials with MeetingLawyers as described in the push guides for
[iOS](https://developer.meetinglawyers.com/docs/ios/firebase/) and
[Android](https://developer.meetinglawyers.com/docs/android/push-notifications/).

Everything else in the app (UI, routing) has no dependency on the SDKs: see [`src/pages/Home.tsx`](src/pages/Home.tsx).
The contract the wrapper fulfils is in [`specs/`](../specs/).

## Usage

Call the wrapper from your TypeScript in this order — configure once at startup, then the rest:

```ts
import { MeetingLawyers } from './plugins/meeting-lawyers';

// 1. Initialize the SDK (once, at app startup)
await MeetingLawyers.configure({ apiKey: ML_API_KEY, environment: 'DEV' });

// 2. Apply your brand colors (optional). Colors are '#RRGGBB' or '#RRGGBBAA'
await MeetingLawyers.configureTheme({
  primaryColor: '#2E7D6B',
  secondaryColor: '#2E7D6B',
  navigationBarColor: '#2E7D6B',
  outgoingMessageColor: '#2E7D6B',
});

// 3. Authenticate the user, then register for push so the token is linked to them
await MeetingLawyers.authenticate({ userId: ML_USER_ID });
await MeetingLawyers.registerForPushNotifications();

// 4. Open the native professional list (tapping a professional opens its chat)
await MeetingLawyers.openProfessionalList();

// …or open a chat with a specific professional directly
await MeetingLawyers.openChatWithProfessional({ professionalHash: 'abc123' });

// Helpers
const { authenticated } = await MeetingLawyers.isAuthenticated();
await MeetingLawyers.logout();
```

See [`src/pages/Home.tsx`](src/pages/Home.tsx) for the same flow wired to buttons, and
[`src/plugins/meeting-lawyers/definitions.ts`](src/plugins/meeting-lawyers/definitions.ts) for the full API
and every `ThemeOptions` color.

## Credentials

Ask for demo credentials at [support@meetinglawyers.com](mailto:support@meetinglawyers.com), then fill in
the repo-root `.env` (git-ignored) — see the [root README](../README.md#credentials):

```bash
cp ../.env.example ../.env
```

Only the `ML_*` values reach the web bundle ([`vite.config.ts`](vite.config.ts));
[`src/config/constants.ts`](src/config/constants.ts) reads them. If you copy the wrapper into your own
app, pass your own values to `configure()` / `authenticate()` however your app manages configuration.

The Android build reads `GPR_USER` / `GPR_TOKEN` from the same `.env`, falling back to
`~/.gradle/gradle.properties` or environment variables.

## Run it

Requirements: Node 22+, Xcode 26+ (iOS) and Android Studio (Android).

```bash
npm install

# iOS
npm run ios          # build web + cap sync + run on simulator/device
npm run open:ios     # or open the project in Xcode

# Android (with GPR_USER / GPR_TOKEN available)
npm run android      # build web + cap sync + run on emulator/device
npm run open:android # or open the project in Android Studio
```

### VS Code

Open the folder in VS Code and install the recommended extensions (the
[WebNative](https://marketplace.visualstudio.com/items?itemName=Webnative.webnative) extension —
successor of the deprecated Ionic extension — gives you run/sync/debug buttons for both platforms).
Predefined tasks are also available under **Terminal → Run Task…** (`iOS: run`, `Android: run`,
`Cap: sync`, `iOS: open in Xcode`, …), and `⇧⌘B` runs the web build. `F5` starts the Vite dev server
with the Chrome debugger for the web layer (native plugin calls only work on device/simulator).

Once running (with `.env` filled in): **Sign in** → **Open professional list** → tap a professional to chat with them.
You can also open a chat directly by professional hash from the home screen.

## Push notifications

Push works over FCM on both platforms. `registerForPushNotifications()` asks for permission and sends the
FCM token to the SDK; this sample calls it right after `authenticate()` (see `Home.tsx`). Token refreshes are
forwarded only once a user is signed in.

Message and token forwarding are wired natively:

- **iOS**: `MeetingLawyersPlugin.startHandlingPushNotifications()`, called on launch, sets the
  `MessagingDelegate` + `UNUserNotificationCenterDelegate` that hand MeetingLawyers pushes to the SDK (other
  pushes are shown normally), so taps on a cold start reach the SDK too.
- **Android**: [`MeetingLawyersFirebaseService`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersFirebaseService.java)
  forwards FCM messages and token refreshes to the SDK. If your app already has its own
  `FirebaseMessagingService`, add those two forwards to it instead. `configure()` saves its values, so a push
  that wakes a killed app configures the SDK before it is forwarded.

This sample ships the Firebase client config for `com.meetinglawyers.meetingpreview.dev` on iOS and
`com.meetinglawyers.sdk.sample` on Android (`GoogleService-Info.plist` / `google-services.json`; Firebase client keys are not secrets). Push needs a real
device signed with a team that can use those ids; with your own app, bring the config files of your own
Firebase project.

The MeetingLawyers SDK pulls in Firebase Crashlytics, so on Android the `com.google.firebase.crashlytics`
Gradle plugin is required (already applied here): without it the app crashes on launch with "The
Crashlytics build ID is missing".
