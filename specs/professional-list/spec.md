# Professional list

Status: implemented

## Purpose

Shows the native list of professionals available to the user. Tapping one opens the chat with them.

## Requirements

### Requirement: open the list inside the host navigation

The wrapper MUST show the professional list and SHOULD push it into the app's existing navigation, so the
SDK screens feel part of the app. When there is no navigation to push into, it MUST present the list.

#### Scenario: host app has navigation

- WHEN the user is authenticated
- AND the app shows its screens inside a navigation stack
- AND the integrator opens the professional list
- THEN the list is pushed onto that stack

#### Scenario: host app has no navigation

- WHEN the user is authenticated
- AND there is no navigation stack to push into
- AND the integrator opens the professional list
- THEN the list is presented over the current screen

#### Scenario: open a chat from the list

- WHEN the user taps a professional in the list
- THEN the chat with that professional opens

## Errors

| Situation | Result |
|---|---|
| Called before configure / authenticate | Rejected: `Could not create the professional list. Call configure() and authenticate() first.` |

Native `android/` returns nothing: the SDK reports no errors when opening the list.

## Shown in

| Sample | Where |
|---|---|
| `ios/` | `MeetingLawyersIntegration.openProfessionalList`, pushed onto the app navigation |
| `android/` | `MeetingLawyersIntegration.openProfessionalList`, opened on top of the activity stack |
| `capacitor/` | `Home.tsx` → `MeetingLawyers.openProfessionalList()` |
| `flutter/` | `main.dart` → `MeetingLawyers.openProfessionalList()` |
