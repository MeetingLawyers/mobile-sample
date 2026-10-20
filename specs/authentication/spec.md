# Authentication

Status: implemented

## Purpose

Signs the app's user into the SDK, so the professional list and chats belong to that user.

## Requirements

### Requirement: authenticate with the user identifier

The wrapper MUST authenticate the given user identifier, which the integrator's backend links to the
company. It MUST be called after configure.

#### Scenario: authenticate a valid user

- WHEN the integrator authenticates a user identifier valid for the API key
- THEN the call succeeds
- AND the session reports the user as authenticated

#### Scenario: authenticate without user identifier

- WHEN the integrator authenticates with an empty user identifier
- THEN the call fails with `userId is required`

## Errors

| Situation | Result |
|---|---|
| Empty or missing user identifier | Rejected: `userId is required` |
| The SDK rejects the user | Rejected with the SDK's reason |
| Called before configure | Not supported (see [configuration](../configuration/spec.md)) |

## Shown in

| Sample | Where |
|---|---|
| `ios/` | `ViewController.swift` → `launchSdk()` |
| `android/` | `MainActivity.kt` |
| `capacitor/` | `Home.tsx` → `MeetingLawyers.authenticate()` |
