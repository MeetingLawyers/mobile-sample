# MeetingPros iOS Sample

Native iOS (Swift, UIKit) sample that integrates **lawyers** (MeetingLawyers SDK) plus **doctors and vets**
(MeetingDoctors SDK) behind one file: configure both SDKs, sign in once, open the lawyers, doctors or vets
list, a lawyer's chat, the doctors features (video call, medical history, My health, booking,
appointments), log out and receive the push notifications of both.

Full documentation: [developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Add it to your app

Both SDKs live behind one file you copy: the rest of your app never imports `MeetingLawyers` or
`MeetingDoctorsSDK`. Ask for your MeetingPros API keys (lawyers and doctors) at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com).

**1. Add the SDKs** with Swift Package Manager (**File → Add Package Dependencies…**):

| Package | Version | Product |
|---|---|---|
| `https://github.com/MeetingLawyers/ios-sdk-spm-meetinglawyers` | Exact `2.2.1` | `MeetingLawyers` |
| `https://github.com/Meeting-Doctors/meetingdoctors-sdk-spm` | Exact `11.6.3` | `MeetingDoctorsSDKWrapper` |
| `https://github.com/firebase/firebase-ios-sdk` (push) | Exact `12.15.0` | `FirebaseMessaging` |

**2. Copy one file** into your app:
[`MeetingProsIntegration.swift`](MeetingPros%20Sample/MeetingProsIntegration.swift).

**3. Hook it on launch**, in `application(_:didFinishLaunchingWithOptions:)`:

```swift
FirebaseApp.configure()
MeetingProsIntegration.shared.startHandlingPushNotifications()
```

This makes the integration the `UNUserNotificationCenter.delegate`: route your own notifications through it, or
forward the ones it does not own from your delegate.

**4. Use it** from your screens. Every screen is pushed onto your navigation controller:

```swift
let integration = MeetingProsIntegration.shared
try await integration.configure(lawyersApiKey: "<lawyers key>", doctorsApiKey: "<doctors key>", isProduction: false)
integration.configureTheme(color: .systemTeal, logo: UIImage(named: "logo"))
try await integration.authenticate(userId: "<user id>")       // both SDKs; also asks for push permission
try integration.openProfessionalList(.doctors, in: navigationController)   // .lawyers, .doctors or .vets
try await integration.openLawyerChat(professionalHash: hash, from: viewController)
let features = await integration.availableFeatures()           // e.g. [.videoCall, .medicalHistory]
try await integration.open(.medicalHistory, in: navigationController)
try await integration.logout()                                  // both SDKs
```

With `isProduction: false` lawyers use the demo environment and doctors the staging one. Call `configure` as
early as possible (calling it again does nothing): a push tapped before it finishes only opens the app.

**5. Permissions and push.** Add `NSCameraUsageDescription` (photos in the chat) and
`NSMicrophoneUsageDescription` (audio messages and video calls) to your `Info.plist`. In **Signing &
Capabilities** add *Push Notifications* and *Background Modes → Remote notifications*, and add your
`GoogleService-Info.plist`. The integration routes each push to its SDK; share your Firebase credentials with
MeetingLawyers as described in the [push notifications guide](https://developer.meetinglawyers.com/docs/ios/firebase/).

The contract it fulfils is in [`specs/meetingpros/`](../../specs/meetingpros/spec.md).

## Run this sample

1. Fill in the repo-root `.env` (git-ignored), see the [root README](../../README.md#credentials):
   `ML_API_KEY` is the MeetingPros company key, `MD_API_KEY` its MeetingDoctors key and `ML_USER_ID` a user of
   both.
2. Open `MeetingPros Sample.xcodeproj` and run the `MeetingPros Sample` scheme. Run it signed (the default):
   unsigned builds cannot use the keychain and the SDKs lose their session.
3. **Sign in** → open a list → tap a professional to chat. The doctors features are enabled only when the
   company has them.
