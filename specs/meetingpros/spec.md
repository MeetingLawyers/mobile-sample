# MeetingPros wrapper

Status: draft

## Purpose

Integrates lawyers (MeetingLawyers SDK) and doctors and vets (MeetingDoctors SDK) behind one small set of
calls, so the app does not juggle two SDKs. Everything the MeetingLawyers wrapper specifies still holds for
the lawyers side ([configuration](../configuration/spec.md), [theme](../theme/spec.md),
[authentication](../authentication/spec.md), [professional list](../professional-list/spec.md),
[chat](../chat/spec.md), [push](../push/spec.md), [session](../session/spec.md)); this spec only adds what
changes with two SDKs.

## Requirements

### Requirement: one file owns both SDKs

The wrapper MUST be the only code that imports the MeetingLawyers and MeetingDoctors SDKs: one file per
platform that the integrator copies. Its calls MUST take and return only platform or wrapper types
(strings, colors, booleans, the list type), never an SDK type, so the rest of the app never imports
either SDK.

#### Scenario: app code stays SDK-free

- WHEN the integrator copies the wrapper into the app
- THEN only the wrapper file imports the MeetingLawyers and MeetingDoctors SDKs
- AND screens, push handling and app startup call the wrapper only

### Requirement: configure both SDKs

The wrapper MUST configure the MeetingLawyers SDK first and the MeetingDoctors SDK second, with one
environment for both. On Android the order is mandatory: MeetingDoctors needs the MeetingLawyers
installation. Configuring again once configured MUST do nothing.

| Environment | MeetingLawyers | MeetingDoctors |
|---|---|---|
| `DEV` | demo | staging |
| `PROD` | production | production |

#### Scenario: configure for the demo environment

- WHEN the integrator configures with a lawyers API key, a doctors API key and environment `DEV`
- THEN the MeetingLawyers SDK targets its demo environment
- AND the MeetingDoctors SDK targets its staging environment

#### Scenario: configure twice

- WHEN the integrator configures again (a web reload, an activity recreated)
- THEN the call succeeds without configuring the SDKs again

#### Scenario: configure without doctors API key

- WHEN the integrator configures with an empty doctors API key
- THEN the call fails with `doctorsApiKey is required`

### Requirement: one theme for both SDKs

The wrapper MUST take one brand color and apply it to both SDKs. Each SDK uses it for the elements it lets
the app style (for example navigation bar, buttons, badges and outgoing messages).

#### Scenario: apply the brand color

- WHEN the integrator sets the primary color
- THEN the lawyers, doctors and vets screens use it

### Requirement: one sign-in, one sign-out

The wrapper MUST authenticate the same user identifier in both SDKs, MeetingLawyers first. Logging out
MUST sign the user out of both. The session MUST report `authenticated: true` only when both SDKs are
signed in.

#### Scenario: authenticate

- WHEN the integrator authenticates a user valid for both companies
- THEN both SDKs are signed in
- AND the session reports `authenticated: true`

#### Scenario: doctors sign-in fails

- WHEN MeetingLawyers accepts the user and MeetingDoctors rejects it
- THEN the call fails with the MeetingDoctors reason
- AND the session reports `authenticated: false`

#### Scenario: log out

- WHEN the integrator logs out
- THEN both SDKs are signed out
- AND the session reports `authenticated: false`

### Requirement: three professional lists

The wrapper MUST open the list of the given type: `lawyers`, `doctors` or `vets`. Doctors and vets are the
same MeetingDoctors list, split by speciality: vets shows only the veterinary specialities and doctors shows
everything else.

#### Scenario: open the vets list

- WHEN the user is authenticated
- AND the integrator opens the `vets` list
- THEN only professionals with a veterinary speciality are listed

#### Scenario: open the doctors list

- WHEN the integrator opens the `doctors` list
- THEN no professional with a veterinary speciality is listed

### Requirement: chat by hash for lawyers

The wrapper MUST open a lawyer's chat by professional hash, as in the MeetingLawyers wrapper. Doctors and
vets chats open from their list.

### Requirement: one push owner

The wrapper MUST be the only handler of FCM and of the system notification callbacks, and MUST route each
push to its SDK: MeetingLawyers first; if it is not a MeetingLawyers push, MeetingDoctors (chat, then video
call on Android); anything else stays with the app. The FCM token MUST go to both SDKs, and only after
authenticating.

On Android the video call SDK cannot tell its pushes apart, so it takes every data push that is not a lawyers
or doctors chat one: only notification-only pushes stay with the app.

#### Scenario: doctors push

- WHEN a MeetingDoctors push arrives
- THEN the MeetingLawyers SDK ignores it
- AND the MeetingDoctors SDK shows it or opens its chat when tapped

#### Scenario: app push on Android

- WHEN a push that is not for the SDKs arrives
- THEN the wrapper reports it as not handled only when it has no data payload

#### Scenario: token refresh

- WHEN FCM issues a new token while a user is signed in
- THEN both SDKs receive it

### Requirement: doctors features

The wrapper MUST report which MeetingDoctors features the company has, and open each one only when
available.

| Feature | What opens |
|---|---|
| `videoCall` | A video call with the duty doctor |
| `medicalHistory` | The user's medical history |
| `myHealth` | The "My health" feed |
| `booking` | The appointment booking flow |
| `appointments` | The user's appointments |

#### Scenario: feature available

- WHEN the company has video call
- AND the integrator starts a video call
- THEN the video call screen opens

#### Scenario: feature not available

- WHEN the company does not have a feature
- THEN the features report it as `false`
- AND opening it fails with `<feature> is not available`

## Errors

| Situation | Result |
|---|---|
| Empty or missing doctors API key | Rejected: `doctorsApiKey is required` |
| Empty or missing lawyers API key (plugin) | Rejected: `lawyersApiKey is required` |
| Empty or missing user id (plugin) | Rejected: `userId is required` |
| Empty or missing professional hash (plugin) | Rejected: `professionalHash is required` |
| Invalid brand color (plugin) | Rejected: `primaryColor must be #RRGGBB or #RRGGBBAA` |
| Unknown list type | Rejected: `type must be lawyers, doctors or vets` |
| Unknown feature (plugin) | Rejected: `Unknown feature` |
| Feature not available for the company | Rejected: `<feature> is not available` |
| Any MeetingLawyers error | As in the MeetingLawyers specs |

## Known differences between platforms

- The vets filter uses each SDK's own speciality identifiers: numeric ids on iOS, `SpecialityInfo` values
  on Android. Both lists cover the same veterinary specialities.
- Video call needs an extra dependency on Android (`videocall-sdk`), and takes every data push that is not a
  chat one (see "One push owner").
- Android has no availability check of its own for appointments: it is available when booking is.
- Each SDK reports "My health" availability its own way, so the same company can show it on one platform
  and not on the other.

## Shown in

| Sample | Where |
|---|---|
| `meetingpros/ios/` | `MeetingProsIntegration.swift`, called from the home screen |
| `meetingpros/android/` | `MeetingProsIntegration.kt`, called from `App` and the home screen |
| `meetingpros/capacitor/` | `src/plugins/meeting-pros/`, bridged to the same `MeetingProsIntegration` files |
