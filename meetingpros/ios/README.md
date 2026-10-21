# MeetingPros iOS Sample

Native iOS (Swift, UIKit) sample that integrates **lawyers** (MeetingLawyers SDK) plus **doctors and vets**
(MeetingDoctors SDK) behind one file: configure both SDKs, sign in once, open the lawyers, doctors or vets
list, a lawyer's chat, the doctors features (video call, medical history, My health, booking,
appointments), log out and receive the push notifications of both.

Check the full documentation at
[developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## How the integration works

Copy [`MeetingProsIntegration.swift`](MeetingPros%20Sample/MeetingProsIntegration.swift) into your app and
call it from your screens. It is the only file that imports `MeetingLawyers` and `MeetingDoctorsSDK`;
everything else talks to it with plain Swift types.

| File | Role |
|------|------|
| [`MeetingProsIntegration.swift`](MeetingPros%20Sample/MeetingProsIntegration.swift) | `configure`, `configureTheme`, `authenticate`, `openProfessionalList(.lawyers / .doctors / .vets)`, `openLawyerChat`, `availableFeatures`, `open(feature)`, `isAuthenticated`, `logout`, and the FCM / `UNUserNotificationCenter` delegates that route each push to its SDK |
| [`AppDelegate.swift`](MeetingPros%20Sample/AppDelegate.swift) | Configures Firebase and hands push delivery to the integration on launch |
| [`SceneDelegate.swift`](MeetingPros%20Sample/SceneDelegate.swift) | Hosts the app in a `UINavigationController`, so the SDK screens are pushed onto it |
| [`ViewController.swift`](MeetingPros%20Sample/ViewController.swift) | The home screen: no SDK knowledge beyond calling the integration |

The contract it fulfils is in [`specs/meetingpros/`](../../specs/meetingpros/spec.md).

## Install

Both SDKs are distributed with Swift Package Manager:
[`ios-sdk-spm-meetinglawyers`](https://github.com/MeetingLawyers/ios-sdk-spm-meetinglawyers) (product
`MeetingLawyers`) and [`meetingdoctors-sdk-spm`](https://github.com/Meeting-Doctors/meetingdoctors-sdk-spm)
(product `MeetingDoctorsSDKWrapper`).

## Credentials

Ask for MeetingPros demo credentials at [support@meetinglawyers.com](mailto:support@meetinglawyers.com), then
fill in the repo-root `.env` (git-ignored) — see the [root README](../../README.md#credentials). Here
`ML_API_KEY` is the MeetingPros company key, `MD_API_KEY` its MeetingDoctors key and `ML_USER_ID` a user of
both. With `ML_ENVIRONMENT=DEV` lawyers use the demo environment and doctors the staging one.

Run it signed (the default): unsigned builds cannot use the keychain and the SDKs lose their session.

## Run it

Select the `MeetingPros Sample` scheme and run it. **Sign in** → open a list → tap a professional to chat.
The doctors features are enabled only when the company has them.
