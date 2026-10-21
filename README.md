# MeetingLawyers mobile samples

Sample apps showing how to integrate the **MeetingLawyers SDKs** in your mobile app: initialize the SDK,
authenticate a user, open the professional list, chat with a professional and receive push notifications.

Check the full documentation at
[developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Samples

| Folder | Platform | What it shows |
|---|---|---|
| [`ios/`](ios/) | iOS (Swift, UIKit) | Native integration of the MeetingLawyers iOS SDK (Swift Package) |
| [`android/`](android/) | Android (Kotlin) | Native integration of the MeetingLawyers Android SDK |
| [`capacitor/`](capacitor/) | Ionic + Capacitor (iOS and Android) | A copy-paste wrapper (local Capacitor plugin) over both native SDKs |

Each folder is a self-contained project with its own README.

## SDK versions

`main` always builds against the versions below. Every SDK bump updates all the samples in one change
and is published as a [release](../../releases).

| Sample | MeetingLawyers SDK | Requirements |
|---|---|---|
| `ios/` | iOS 2.2.1 | Xcode 26+, iOS 15+ |
| `android/` | Android 2.1.15 | Android Studio, JDK 17+, minSdk 23, compileSdk 36 |
| `capacitor/` | iOS 2.2.1 · Android 2.1.15 | Node 22+, Capacitor 8, Xcode 26+, iOS 15+, minSdk 24 |

## Credentials

Ask for demo credentials at [support@meetinglawyers.com](mailto:support@meetinglawyers.com). Then create
your local `.env` at the root of this repo — it is git-ignored, never commit it:

```bash
cp .env.example .env
```

| Key | Used by | Value |
|---|---|---|
| `ML_API_KEY` | all | Your company API key |
| `ML_USER_ID` | all | A user identifier valid for that API key |
| `ML_ENVIRONMENT` | all | `DEV` (demo environment) or `PROD` |
| `MD_API_KEY` | MeetingPros samples | Your MeetingDoctors API key |
| `GPR_USER` / `GPR_TOKEN` | Android builds | GitHub user and a token with `read:packages`: the Android SDK is served from GitHub Packages |

Write plain `KEY=value` lines with no comments: the iOS projects read this file as an Xcode `.xcconfig`.

## License

[MIT](LICENSE). Copy the wrappers into your app and adapt them freely.
