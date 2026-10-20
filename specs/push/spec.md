# Push notifications

Status: implemented

## Purpose

Delivers MeetingLawyers chat notifications over Firebase Cloud Messaging (FCM) without taking over the
app's own notifications.

## Requirements

### Requirement: register after authentication

The wrapper MUST ask for notification permission and register the device FCM token with the SDK. It SHOULD
be called after authenticate, so the token is linked to the user.

#### Scenario: register for push

- WHEN the user is authenticated
- AND the integrator registers for push notifications
- THEN the user is asked for notification permission
- AND the FCM token is sent to the SDK

#### Scenario: token refresh

- WHEN FCM issues a new token
- THEN it is forwarded to the SDK

### Requirement: only MeetingLawyers pushes go to the SDK

The wrapper MUST hand MeetingLawyers pushes to the SDK and MUST leave every other push to the app.

#### Scenario: MeetingLawyers push in foreground

- WHEN a MeetingLawyers push arrives while the app is open
- THEN the SDK decides how to show it

#### Scenario: tap on a MeetingLawyers push

- WHEN the user taps a MeetingLawyers push
- THEN the SDK opens the related chat

#### Scenario: another push

- WHEN a push that is not from MeetingLawyers arrives
- THEN the SDK ignores it
- AND the app shows it as usual

## Errors

| Situation | Result |
|---|---|
| Firebase config file missing | Rejected: `Firebase is not configured. …` |
| Firebase not linked (iOS) | Rejected: `FirebaseMessaging is not linked. …` |
| Token cannot be fetched (Android) | Rejected: `Could not fetch the FCM token` |

## Shown in

| Sample | Where |
|---|---|
| `ios/` | `PushNotificationSample.swift`, registered on app launch |
| `android/` | `SampleMessagingService.kt` |
| `capacitor/` | `Home.tsx`, right before opening the list |
