# MeetingLawyers iOS SDK Sample

Native iOS (Swift, UIKit) sample that configures the MeetingLawyers SDK, authenticates a user, opens the
professional list or a chat, logs out and receives push notifications over FCM.

Check the full documentation at
[developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## How the integration works

Every SDK call lives in one file you can copy into your app:

| File | Role |
|------|------|
| [`MeetingLawyersIntegration.swift`](SDK%20Sample/MeetingLawyersIntegration.swift) | `configure`, `configureTheme`, `authenticate`, `openProfessionalList`, `openChat`, `isAuthenticated`, `logout`, and the FCM / `UNUserNotificationCenter` delegates |
| [`AppDelegate.swift`](SDK%20Sample/AppDelegate.swift) | Configures Firebase and hands push delivery to the integration on launch |
| [`SceneDelegate.swift`](SDK%20Sample/SceneDelegate.swift) | Hosts the app in a `UINavigationController`, so the SDK screens are pushed onto it |
| [`ViewController.swift`](SDK%20Sample/ViewController.swift) | The home screen: no SDK knowledge beyond calling the integration |

The contract each call fulfils is in [`specs/`](../specs/).

## Install

The SDK is distributed with Swift Package Manager:
[`ios-sdk-spm-meetinglawyers`](https://github.com/MeetingLawyers/ios-sdk-spm-meetinglawyers). Open
`SDK Sample.xcodeproj`; if Xcode does not fetch the packages, use **File → Packages → Resolve Package
Versions**.

## Credentials

Ask for demo credentials at [support@meetinglawyers.com](mailto:support@meetinglawyers.com), then fill in
the repo-root `.env` (git-ignored) — see the [root README](../README.md#credentials).

`Config.xcconfig` includes that file, `Info.plist` exposes `ML_API_KEY`, `ML_USER_ID` and `ML_ENVIRONMENT`,
and [`Constants.swift`](SDK%20Sample/Constants.swift) reads them. Rebuild after changing `.env`.

## Push notifications

The sample ships the Firebase client config of `com.meetinglawyers.sdk.sample` (`GoogleService-Info.plist`)
and the `aps-environment` entitlement. Push needs a real device signed with a team that can use that bundle
id; with your own app, bring your own Firebase config and bundle id.

## Run it

Select the `SDK Sample` scheme and run it. **Sign in** → **Open professional list** → tap a professional to
chat. You can also open a chat directly by professional hash.
