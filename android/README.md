# MeetingLawyers Android SDK Sample

Native Android (Kotlin) sample that initializes the MeetingLawyers SDK, authenticates a user, shows the
professional list and receives push notifications over FCM.

Check the full documentation at
[developer.meetinglawyers.com](https://developer.meetinglawyers.com/docs/getting-started).

## Credentials

Ask for demo credentials (API key, user id and GitHub Packages access) at
[support@meetinglawyers.com](mailto:support@meetinglawyers.com), then fill in the repo-root `.env`
(git-ignored) — see the [root README](../README.md#credentials).

- `ML_API_KEY`, `ML_USER_ID`, `ML_ENVIRONMENT` reach the app through `BuildConfig` ([`Constants.kt`](app/src/main/java/com/meetinglawyers/sample/Constants.kt)).
- `GPR_USER` / `GPR_TOKEN` authenticate against GitHub Packages, where the SDK is served. If they are not in
  `.env`, they are read from `~/.gradle/gradle.properties` or environment variables.

## Run it

Open this `android/` folder in Android Studio and run the `app` configuration, or:

```bash
./gradlew installDebug
```
