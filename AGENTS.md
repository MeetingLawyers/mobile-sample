# MeetingLawyers mobile samples — Agent Guide

Single source of truth for AI assistants and humans. `CLAUDE.md` is a symlink to this file.

This repo is **public**. It holds the integration samples of the MeetingLawyers SDKs: one
self-contained project per folder (`ios/`, `android/`, `capacitor/`, and later `meetingpros/…`).
Integrators copy the wrapper classes into their own app, so the code must stay small, readable and
free of anything internal.

## Never commit

- Credentials of any kind: API keys / company ids, user ids, tokens. They live only in the git-ignored
  root `.env` (template: `.env.example`).
- Customer or brand names (bundle ids, app names, colours of a client).
- Internal references: Jira keys, Confluence ids, internal hosts, backend details. The Jira key goes in
  the branch name and PR only.

## Structure

| Path | What |
|---|---|
| `ios/` | Native iOS sample (Xcode, SPM) |
| `android/` | Native Android sample (Gradle, Kotlin) |
| `capacitor/` | Ionic + Capacitor sample with the copy-paste MeetingLawyers plugin |
| `specs/<capability>/spec.md` | Contract every sample's wrapper fulfils |
| `.env.example` | Credential keys every sample reads |

Credentials reach each platform without extra dependencies: iOS through `Config.xcconfig` →
`Info.plist`, Android through Gradle → `BuildConfig`, Capacitor through Vite (`ML_*` only). The `.env`
holds plain `KEY=value` lines with no comments, because Xcode parses it as an `.xcconfig`.

## Spec-Driven Development

1. Change the spec first (`specs/<capability>/spec.md`, template in `specs/_template/`).
2. Then the samples that show it, all of them in the same change when the contract is shared.
3. Every scenario lists where each sample shows it (`Shown in`).

Specs are public: describe what the integrator sees, never how the SDK works inside. Gaps or bugs go to
Jira, not to the spec.

## SDK bumps

One change bumps every sample that uses that SDK, updates the versions table in `README.md` and is
published as a GitHub release.

## Build

```bash
# iOS
xcodebuild build -project "ios/SDK Sample.xcodeproj" -scheme "SDK Sample" \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
# Android (JDK 17-21)
(cd android && ./gradlew assembleDebug)
# Capacitor
(cd capacitor && npm ci && npm run lint && npm run build && npx vitest run)
```

## Conventions

- KISS: a sample shows the integration, nothing else. No architecture layers, no extra libraries.
- Comments: one short line when it adds something; integrator-facing explanations go in the README.
- No force unwraps / casts in Swift and Kotlin.
