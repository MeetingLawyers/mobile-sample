# MeetingLawyers iOS SDK Sample

This is a sample project for the iOS Meeting Lawyers SDK. You can use it to test and understand how the SDK works.

Before you begin, please review our documentation:  
[Getting Started with Meeting Lawyers SDK](https://developer.meetinglawyers.com/docs/getting-started)

---

## Configuration

### Install with Swift Package Manager (SPM) Enabled by default

1. Open `SDK Sample.xcodeproj`.
2. If Xcode fails to download dependencies, navigate to the top menu, **Xcode** → **File** → **Packages** → **Resolve Package Versions**.

---

### Install with CocoaPods (deprecated)

The project is configured with spm by default since cocoapods is deprecated.
To remove spm config, open project (`SDK Sample.xcodeproj`) Go to **SDK Sample** → **PROJECT** → **Package Dependencies** → **Remove all Package dependencies**.

1. Add the private repository using CocoaPods. In the terminal, navigate to the SDK Sample directory and execute the following commands:

```bash
pod repo add meetinglawyers https://bitbucket.org/meetinglawyers/ios-cocoapods-specs.git
pod repo update
pod install
```

2. Open `SDK Sample.xcworkspace (the file with the white icon).

---

## Credentials

Ask for demo credentials at [support@meetinglawyers.com](mailto:support@meetinglawyers.com), then fill in
the repo-root `.env` (git-ignored) — see the [root README](../README.md#credentials).

`Config.xcconfig` includes that file, `Info.plist` exposes `ML_API_KEY`, `ML_USER_ID` and `ML_ENVIRONMENT`,
and [`Constants.swift`](SDK%20Sample/Constants.swift) reads them. Rebuild after changing `.env`.
