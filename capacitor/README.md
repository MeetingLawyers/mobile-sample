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

**2. iOS.** Add with Swift Package Manager
[`ios-sdk-spm-meetinglawyers`](https://github.com/MeetingLawyers/ios-sdk-spm-meetinglawyers) (exact `2.2.1`,
product `MeetingLawyers`) and, for push, `firebase-ios-sdk` (product `FirebaseMessaging`). Set
`MyViewController` as the bridge controller, embedded in a navigation controller (see `Main.storyboard`),
and add your `GoogleService-Info.plist`.

**3. Android.** Add the GitHub Packages repository (it needs a GitHub user and a token with
`read:packages`) to `android/build.gradle`:

```groovy
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

Then the dependencies to `android/app/build.gradle`, plus the `google-services` and
`firebase-crashlytics` plugins (the SDK brings Crashlytics, so its plugin is required):

```groovy
implementation "com.meetinglawyers:sdk:2.1.15"
implementation platform("com.google.firebase:firebase-bom:32.7.1")
implementation "com.google.firebase:firebase-messaging"
```

Register the plugin in [`MainActivity`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MainActivity.java)
(`registerPlugin(MeetingLawyersPlugin.class)` before `super.onCreate`), declare
`MeetingLawyersFirebaseService` in the manifest and add your `google-services.json`.

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

// 3. Authenticate the user
await MeetingLawyers.authenticate({ userId: ML_USER_ID });

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

Push works over FCM on both platforms. The wrapper exposes one method:

```ts
// After authenticate(): asks for permission and registers the FCM token with the SDK
await MeetingLawyers.registerForPushNotifications();
```

In this sample it is called right before `openProfessionalList()` (see `Home.tsx`), so the user
gets the permission prompt when entering the SDK flow instead of via a dedicated button.

Message and token forwarding are already wired natively:

- **iOS**: the plugin acts as `MessagingDelegate` + `UNUserNotificationCenterDelegate` and hands
  MeetingLawyers pushes to the SDK (other pushes are shown normally).
- **Android**: [`MeetingLawyersFirebaseService`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersFirebaseService.java)
  forwards FCM messages and token refreshes to the SDK. If your app already has its own
  `FirebaseMessagingService`, add those two forwards to it instead.

This sample ships the Firebase client config for `com.meetinglawyers.sdk.sample`
(`GoogleService-Info.plist` / `google-services.json`), so push works out of the box — Firebase client
keys are not secrets. If you copy the wrapper into your own app, bring the config files of your own
Firebase project instead.

Two integration notes:

- **Android**: the MeetingLawyers SDK pulls in Firebase Crashlytics, so once `google-services.json`
  is present the `com.google.firebase.crashlytics` gradle plugin is required (already applied here) —
  without it the app crashes on launch with "The Crashlytics build ID is missing".
- If the Firebase config file is removed, the app still works; `registerForPushNotifications()`
  just rejects with a clear message.
