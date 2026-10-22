# Configuration

Status: implemented

## Purpose

Initializes the MeetingLawyers SDK with the company API key and the target environment. It is the first
call of the integration; everything else requires it.

## Requirements

### Requirement: configure once at startup

The wrapper MUST initialize the SDK with the given API key and environment, and SHOULD be called once,
when the app starts.

#### Scenario: configure for the demo environment

- WHEN the integrator configures with a valid API key and environment `DEV`
- THEN the SDK is initialized against the MeetingLawyers demo environment
- AND debug logging is enabled

#### Scenario: configure for production by default

- WHEN the integrator configures with a valid API key and no environment
- THEN the SDK is initialized against production
- AND debug logging is disabled

### Requirement: API key is mandatory

The wrapper MUST reject the call when the API key is missing or empty.

#### Scenario: configure without API key

- WHEN the integrator configures with an empty API key
- THEN the call fails with `apiKey is required`
- AND the SDK is not initialized

## Errors

| Situation | Result |
|---|---|
| Empty or missing API key | Rejected: `apiKey is required` |
| The SDK fails to initialize | Rejected: `Configure failed: <reason>` |
| Any other call before configure | Not supported. Capacitor Android rejects it with `SDK not configured. Call configure() first.`; native `android/` throws |

## Shown in

| Sample | Where |
|---|---|
| `ios/` | `MeetingLawyersIntegration.configure`, called when the home screen loads |
| `android/` | `MeetingLawyersIntegration.configure`, from `App.onCreate` |
| `capacitor/` | `Home.tsx` → `MeetingLawyers.configure()` |
