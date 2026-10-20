# Session

Status: implemented

## Purpose

Lets the app know whether a user is signed into the SDK and sign them out, for example when the app's own
user logs out.

## Requirements

### Requirement: report the session

The wrapper MUST report whether a user is currently authenticated.

#### Scenario: authenticated user

- WHEN the user has been authenticated
- THEN the session reports `authenticated: true`

#### Scenario: no user

- WHEN no user has been authenticated, or the SDK is not configured
- THEN the session reports `authenticated: false`

### Requirement: log out

The wrapper MUST sign the user out of the SDK.

#### Scenario: log out

- WHEN the integrator logs out
- THEN the session reports `authenticated: false`
- AND the professional list requires a new authentication

## Errors

| Situation | Result |
|---|---|
| The SDK fails to log out | Rejected with the SDK's reason |

## Shown in

| Sample | Where |
|---|---|
| `ios/` | — |
| `android/` | — |
| `capacitor/` | `Home.tsx` → status line and "Log out" |
