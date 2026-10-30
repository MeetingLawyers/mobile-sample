# Theme

Status: implemented

## Purpose

Applies the integrator's brand colors to the SDK screens from one place.

## Requirements

### Requirement: common palette, every color optional

The wrapper MUST accept the colors that the iOS and Android SDKs share, each one optional, as `#RRGGBB` or
`#RRGGBBAA` hex strings on every platform: only the colors given are applied and the rest keep the SDK default.

| Color | Name |
|---|---|
| Primary | `primaryColor` |
| Secondary | `secondaryColor` |
| Navigation bar | `navigationBarColor` |
| Incoming message | `incomingMessageColor` |
| Outgoing message | `outgoingMessageColor` |

#### Scenario: apply a partial palette

- WHEN the integrator sets only the primary color
- THEN the SDK screens use that primary color
- AND every other color keeps the SDK default

#### Scenario: invalid color

- WHEN a color is not a `#RRGGBB` / `#RRGGBBAA` string
- THEN the call fails with `<color> must be #RRGGBB or #RRGGBBAA`
- AND no color is applied

The native `ios/` sample also shows a logo in the navigation bar. For colors only one platform has, call the
SDK directly from the `MeetingLawyersIntegration` file.

## Errors

| Situation | Result |
|---|---|
| Called before configure | Not supported (see [configuration](../configuration/spec.md)) |

## Shown in

| Sample | Where |
|---|---|
| `ios/` | `ViewController` → `configureTheme` (brand color and navigation logo) |
| `android/` | `App.onCreate` → `configureTheme` (brand color) |
| `capacitor/` | `Home.tsx` → `configureTheme` with `BRAND_COLOR`, after configure |
| `flutter/` | `main.dart` → `brandColor`, applied after configure |
