# MeetingLawyers iOS SDK Sample

Native iOS (Swift, UIKit) sample that configures the MeetingLawyers SDK, authenticates a user, opens the
professional list or a chat, logs out and receives push notifications over FCM.

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

Every SDK call lives in one file you copy. Ask for your API key at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Add the SDK** with Swift Package Manager (**File → Add Package Dependencies…**):

| Package | Version | Product |
|---|---|---|
| `https://github.com/MeetingLawyers/ios-sdk-spm-meetinglawyers` | Exact `2.2.1` | `MeetingLawyers` |
| `https://github.com/firebase/firebase-ios-sdk` (push) | Up to next major | `FirebaseMessaging` |

**2. Copy one file** into your app:
[`MeetingLawyersIntegration.swift`](SDK%20Sample/MeetingLawyersIntegration.swift). It is the only file that
imports `MeetingLawyers`: `configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openChat`,
`isAuthenticated`, `logout`, and the push delegates.

**3. Hook it on launch**, in `application(_:didFinishLaunchingWithOptions:)`:

```swift
FirebaseApp.configure()
MeetingLawyersIntegration.shared.startHandlingPushNotifications()
Task { try await MeetingLawyersIntegration.shared.configure(apiKey: "<your API key>", isProduction: false) }
```

Configure as early as possible, so a push tapped on a cold start finds the SDK ready (this sample does it
when its home screen loads, to show the status).

**4. Use it** from your screens. The list is pushed onto your navigation controller:

```swift
let integration = MeetingLawyersIntegration.shared
try integration.configureTheme(.init(primaryColor: "#2E7D6B"), logo: UIImage(named: "logo")) // hex, every color optional
try await integration.authenticate(userId: "<user id>")   // also asks for push permission
try integration.openProfessionalList(in: navigationController)
try await integration.openChat(professionalHash: hash, from: viewController)
try await integration.logout()
```

**5. Permissions and push.** Add `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` to your
`Info.plist` (the chat sends photos and audio messages). In **Signing & Capabilities** add *Push
Notifications* and *Background Modes → Remote notifications*, add your `GoogleService-Info.plist`, and share
your Firebase credentials with MeetingLawyers as described in the
[push notifications guide](https://developer.meetinglawyers.com/docs/ios/firebase/).

The contract each call fulfils is in [`specs/`](../specs/).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../README.md#credentials).
   `Config.xcconfig` includes it and [`Constants.swift`](SDK%20Sample/Constants.swift) reads the values from
   `Info.plist`; rebuild after changing it.
2. Open `SDK Sample.xcodeproj` and run the `SDK Sample` scheme. Run it signed (the default): unsigned builds
   cannot use the keychain and the SDK loses its configuration and session.
3. **Sign in** → **Open professional list** → tap a professional to chat. You can also open a chat by
   professional hash.

Push needs a real device signed with a team that can use `com.meetinglawyers.meetingpreview.dev`; with your own app,
use your own bundle id and Firebase config.
