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
| [`flutter/`](flutter/) | Flutter (iOS and Android) | A copy-paste method channel over the native integration files |
| [`meetingpros/ios/`](meetingpros/ios/) | iOS (Swift, UIKit) | MeetingPros: lawyers plus doctors and vets behind one copy-paste file |
| [`meetingpros/android/`](meetingpros/android/) | Android (Kotlin) | MeetingPros: lawyers plus doctors and vets behind one copy-paste file |
| [`meetingpros/capacitor/`](meetingpros/capacitor/) | Ionic + Capacitor (iOS and Android) | MeetingPros through a copy-paste Capacitor plugin over the native files |
| [`meetingpros/flutter/`](meetingpros/flutter/) | Flutter (iOS and Android) | MeetingPros through a copy-paste method channel over the native files |

Each folder is a self-contained project. Its README starts with **Add it to your app**: the SDK
dependency, the files to copy and the few lines that call them.

## SDK versions

`main` always builds against the versions below. Every SDK bump updates all the samples in one change
and is published as a [release](../../releases).

| Sample | SDKs | Requirements |
|---|---|---|
| `ios/` | iOS 2.2.1 | Xcode 26+, iOS 15+ |
| `android/` | Android 2.1.16 | Android Studio, JDK 17+, minSdk 23, compileSdk 36 |
| `capacitor/` | iOS 2.2.1 · Android 2.1.16 | Node 22+, Capacitor 8, Xcode 26+, iOS 15+, minSdk 24 |
| `flutter/` | iOS 2.2.1 · Android 2.1.16 | Flutter 3.47+, Xcode 26+, iOS 15+, minSdk 24 |
| `meetingpros/ios/` | iOS 2.2.1 + MeetingDoctors 11.6.3 | Xcode 26+, iOS 15+ |
| `meetingpros/android/` | Android 2.1.16 + MeetingDoctors chat 2.9.0, video call 3.0.22 | Android Studio, JDK 17+, minSdk 24, compileSdk 36 |
| `meetingpros/capacitor/` | Same as `meetingpros/ios/` and `meetingpros/android/` | Node 22+, Capacitor 8, Xcode 26+, iOS 15+, minSdk 24 |
| `meetingpros/flutter/` | Same as `meetingpros/ios/` and `meetingpros/android/` | Flutter 3.47+, Xcode 26+, iOS 15+, minSdk 24 |

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

With MeetingPros credentials (`ML_API_KEY` of a MeetingPros company plus its `MD_API_KEY`) one `.env`
runs every sample. Write plain `KEY=value` lines with no comments: the iOS projects read this file as an Xcode `.xcconfig`.

## License

[MIT](LICENSE). Copy the wrappers into your app and adapt them freely.
