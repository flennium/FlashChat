# FlashChat

FlashChat is a Flutter chat application backed mainly by Firebase, with Supabase used for storage and a custom notification edge function. The app supports email and Google sign-in, room creation, private rooms with access codes, real-time chat, replies, reactions, mentions, unread counts, profiles, settings, presence, and push notifications.

## Stack

- Flutter for the client UI
- Riverpod for dependency injection and state management
- Firebase Authentication for sign-in and sessions
- Cloud Firestore for users, rooms, messages, usernames, and room membership
- Firebase Realtime Database for online presence and typing indicators
- Firebase Cloud Messaging for device notification tokens
- Firebase Remote Config for the global pinned announcement
- Firebase Crashlytics for runtime error reporting
- Firebase Cloud Functions for unread counters, moderation, and mention notifications
- Supabase Storage for avatars, room avatars, and chat images

## Project Layout

- `lib/`: Flutter application source
- `functions/`: Firebase Cloud Functions source
- `assets/branding/`: project logos and app icon source files
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`: platform runners
- `firestore.rules`: Firestore security rules
- `storage.rules`: Firebase Storage rules
- `test/`: unit and widget tests
- `docs/`: detailed technical documentation

## Start Here

If you want to understand the project deeply, read these in order:

1. [Architecture](docs/ARCHITECTURE_README.md)
2. [Data Model](docs/DATA_MODEL_README.md)
3. [Features](docs/FEATURES_README.md)
4. [Backend And Ops](docs/BACKEND_README.md)
5. [Configuration And Security](docs/CONFIGURATION_AND_SECURITY.md)
6. [Study Guide](docs/STUDY_GUIDE.md)

## Quick Run

```bash
flutter pub get
flutter run
```

## Local Environment

This project uses Flutter `--dart-define` values for runtime configuration.

Files included for setup:

- `.env.local`: local-only file for development on your machine, ignored by Git
- `.env.github.example`: tracked template for GitHub Actions secrets

For local runs on Windows PowerShell, you can use:

```powershell
.\scripts\flutter-with-env.ps1 run
```

For local APK builds:

```powershell
.\scripts\flutter-with-env.ps1 build apk --release
```

## Android Release

```bash
flutter build apk --release
```

Latest built APK path:

`build/app/outputs/flutter-apk/app-release.apk`

## Important Runtime Config

- Firestore admin config document:
  - collection: `app`
  - document: `config`
  - field: `roomAdminEmail`
- Supabase storage bucket names come from dart defines or `AppEnv`
- Firebase configuration is generated in `lib/firebase_options.dart`
- Sensitive runtime config is intentionally excluded from version control

## Cleanup Notes

Generated/local artifacts such as `build/`, `.dart_tool/`, IDE folders, `functions/node_modules/`, and release APKs should not live in the long-term project snapshot. The `.gitignore` file now reflects that more clearly.

## Verification

Current project checks used during maintenance:

```bash
flutter analyze
flutter test
```

## GitHub Actions

The repository includes a GitHub Actions workflow at `.github/workflows/android-ci.yml`.

It does three things on `push`, `pull_request`, or manual trigger:

- runs `flutter analyze`
- runs `flutter test`
- builds an Android release APK and uploads it as an artifact

Because sensitive Firebase files are not committed, the workflow expects these GitHub repository secrets:

- `FIREBASE_OPTIONS_DART`
- `GOOGLE_SERVICES_JSON`

Optional build-time secrets for app environment values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_AVATAR_BUCKET`
- `SUPABASE_CHAT_IMAGE_BUCKET`
- `GOOGLE_WEB_CLIENT_ID`

How to set the required file secrets:

1. Copy the full contents of your local `lib/firebase_options.dart` into `FIREBASE_OPTIONS_DART`.
2. Copy the full contents of your local `android/app/google-services.json` into `GOOGLE_SERVICES_JSON`.
3. In GitHub, go to `Settings -> Secrets and variables -> Actions -> New repository secret`.

## Releases And Versioning

The repository also includes `.github/workflows/android-release.yml`.

Release flow:

1. Update `version:` in `pubspec.yaml`
2. Commit the version change
3. Create a matching Git tag in the form `vX.Y.Z`
4. Push the tag to GitHub

Example:

```bash
git tag v0.1.0
git push origin v0.1.0
```

When the tag matches the `pubspec.yaml` version, GitHub Actions will:

- build the Android release APK
- create a GitHub Release
- upload `flashchat-X.Y.Z-android-release.apk` to the Releases section

## Publication Notes

This repository is prepared to keep sensitive configuration out of version control. Before sharing the project more broadly, review [Configuration And Security](docs/CONFIGURATION_AND_SECURITY.md).

For web push notifications, `web/firebase-messaging-sw.js` is committed with placeholder Firebase values and should be filled with the correct web app configuration during deployment.
