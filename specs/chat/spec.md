# Chat

Status: implemented

## Purpose

Opens the chat with a specific professional directly, without going through the list — for example from a
deep link or a button in the app.

## Requirements

### Requirement: open a chat by professional hash

The wrapper MUST open the chat with the professional identified by the given hash.

#### Scenario: open a chat

- WHEN the user is authenticated
- AND the integrator opens the chat with a valid professional hash
- THEN the chat with that professional is shown

#### Scenario: open a chat without hash

- WHEN the integrator opens a chat with an empty hash
- THEN the call fails with `professionalHash is required`

## Errors

| Situation | Result |
|---|---|
| Empty or missing hash | Rejected: `professionalHash is required` |
| The SDK cannot open it | Rejected: `Could not open the chat: <reason>` |

## Shown in

| Sample | Where |
|---|---|
| `ios/` | `MeetingLawyersIntegration.openChat`, from "Open chat" with a hash |
| `android/` | `MeetingLawyersIntegration.openChat`, from "Open chat" with a hash |
| `capacitor/` | `Home.tsx` → "Open chat" with a professional hash |
