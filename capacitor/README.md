# MeetingLawyers Ionic + Capacitor Sample

Sample app showing how to integrate the **MeetingLawyers SDKs** (iOS and Android) in an
[Ionic](https://ionicframework.com/) + [Capacitor](https://capacitorjs.com/) app: initialize the SDK,
authenticate a user, open the native professional list and chat with a professional.

Check the full documentation at
[developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## How the integration works

All the SDK integration lives in a small **copy-paste wrapper** (a local Capacitor plugin), so the rest
of the app has no direct dependency on the SDKs:

| File | Role |
|------|------|
| [`src/plugins/meeting-lawyers/`](src/plugins/meeting-lawyers/definitions.ts) | TypeScript API (`configure`, `authenticate`, `openProfessionalList`, `openChatWithProfessional`, `isAuthenticated`, `logout`) |
| [`ios/App/App/MeetingLawyersPlugin.swift`](ios/App/App/MeetingLawyersPlugin.swift) | iOS bridge to the `MeetingLawyers` SDK (Swift Package) |
| [`android/.../MeetingLawyersPlugin.java`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MeetingLawyersPlugin.java) | Android bridge to the `com.meetinglawyers:sdk` library |

To reuse it in your own Capacitor app, copy those three pieces and register the plugin:

- **iOS**: register the plugin in your `CAPBridgeViewController` subclass
  ([`MyViewController.swift`](ios/App/App/MyViewController.swift)) and add the
  [`ios-sdk-spm-meetinglawyers`](https://github.com/MeetingLawyers/ios-sdk-spm-meetinglawyers) Swift Package.
- **Android**: register the plugin in [`MainActivity`](android/app/src/main/java/com/meetinglawyers/sample/ionic/MainActivity.java)
  and add the maven repository + dependency (see below).

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

Ask for demo credentials at [support@meetinglawyers.com](mailto:support@meetinglawyers.com), then set them in
[`src/config/constants.ts`](src/config/constants.ts):

```ts
export const ML_API_KEY = '';               // your company API key
export const ML_USER_ID = '';               // a user identifier valid for that API key
export const ML_ENVIRONMENT: 'DEV' | 'PROD' = 'DEV';
```

### Android maven credentials

The Android SDK is served from GitHub Packages, which requires credentials even for public consumers.
Provide them as gradle properties or environment variables (`GPR_USER` / `GPR_TOKEN`) — never commit them:

```bash
# ~/.gradle/gradle.properties
GPR_USER=your_github_user
GPR_TOKEN=your_token_with_read_packages
```

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

Once running: **Sign in** → **Open professional list** → tap a professional to chat with them.
You can also open a chat directly by professional hash from the home screen.

## Push notifications

Not wired in this sample yet. Push works over FCM on both platforms — see the platform guides at
[developer.meetinglawyers.com](https://developer.meetinglawyers.com/). Firebase config files
(`GoogleService-Info.plist`, `google-services.json`) are gitignored on purpose: supply your own.
