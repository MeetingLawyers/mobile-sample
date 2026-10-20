# Theme

Status: implemented

## Purpose

Applies the integrator's brand colors to the SDK screens from one place.

## Requirements

### Requirement: hex colors, all optional

The wrapper MUST accept every color as a `#RRGGBB` or `#RRGGBBAA` string and MUST treat each one as
optional: only the colors given are applied.

#### Scenario: apply a partial palette

- WHEN the integrator sets only the primary color
- THEN the SDK screens use that primary color
- AND every other color keeps the SDK default

#### Scenario: ignore an invalid color

- WHEN a color is not a valid `#RRGGBB` / `#RRGGBBAA` string
- THEN that color is ignored
- AND the call still succeeds

### Requirement: same palette on every platform

The wrapper MUST accept the full palette on every platform and SHOULD apply each color the platform SDK
supports, ignoring the rest.

| Color | iOS | Android |
|---|---|---|
| Primary | yes | yes |
| Secondary | yes | yes |
| Navigation bar | yes | yes |
| Incoming message | yes | yes |
| Outgoing message | yes | yes |
| Divider | yes | ignored |

#### Scenario: platform-only color

- WHEN the integrator sets the divider color on Android
- THEN it is ignored
- AND the call succeeds

## Errors

| Situation | Result |
|---|---|
| Called before configure | Not supported (see [configuration](../configuration/spec.md)) |

## Shown in

| Sample | Where |
|---|---|
| `ios/` | `MeetingLawyersIntegration.configureTheme` (brand color and navigation logo) |
| `android/` | `MeetingLawyersIntegration.configureTheme` (brand color), from `App.onCreate` |
| `capacitor/` | `constants.ts` → `ML_THEME`, applied after configure |
