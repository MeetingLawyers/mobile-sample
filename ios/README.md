# iOS Meeting Lawyers SDK Sample

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

1. Open the project and locate the `Constants` file.

2. Update the file with your credentials.


Note: If you do not have your credentials yet, please contact our support team at support@meetinglawyers.com.

