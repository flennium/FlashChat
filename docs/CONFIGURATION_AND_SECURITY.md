# Configuration And Security

## 1. Purpose

This document explains which configuration values are expected at runtime, which files are intentionally excluded from version control, and what should be checked before publishing or sharing the repository.

## 2. Files Not Committed

The repository is configured to exclude sensitive or environment-specific files such as:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- Firebase admin service-account JSON files
- `functions/node_modules/`
- local Supabase temp files
- build outputs and IDE folders

These exclusions are defined in `.gitignore`.

## 3. Runtime Configuration

The app reads environment values from `lib/core/constants/app_env.dart`.

Expected Dart defines:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_AVATAR_BUCKET`
- `SUPABASE_CHAT_IMAGE_BUCKET`
- `GOOGLE_WEB_CLIENT_ID`

For publication readiness, the repository now uses empty defaults for the Supabase URL, Supabase anon key, and Google web client id. Those values should be supplied through build-time environment variables or CI secrets.

Tracked setup file:

- `.env.github.example`

Local-only setup file:

- `.env.local`


## 4. Firebase Client Configuration

The project uses FlutterFire-generated Firebase options and the Android `google-services.json` file during builds.

These files are not committed. They should be restored from secure local copies or GitHub Actions secrets when needed.

Required CI secrets:

- `FIREBASE_OPTIONS_DART`
- `GOOGLE_SERVICES_JSON`

The same configuration model is used for:

- Android CI builds
- Android release builds
- Windows CI builds
- Windows release builds
- Windows installer packaging in GitHub Actions

## 5. Backend Secrets

The Supabase Edge Function for notifications expects:

- `FIREBASE_SERVICE_ACCOUNT`

This must stay in a secret manager or environment variable and must never be committed to the repository.

## 6. Public Repository Checklist

Before publishing:

1. Confirm no service-account JSON files are present.
2. Confirm `google-services.json` is not tracked.
3. Confirm `lib/firebase_options.dart` is not tracked.
4. Confirm no API tokens or private keys are hardcoded in application source.
5. Confirm CI is using repository secrets instead of committed config files.

## 7. Notes About Firebase Web Config

The committed `web/firebase-messaging-sw.js` file uses placeholders rather than a live Firebase web configuration.

Before enabling web push in a deployed environment, replace these placeholders with the correct Firebase web app values:

- `__FIREBASE_API_KEY__`
- `__FIREBASE_AUTH_DOMAIN__`
- `__FIREBASE_PROJECT_ID__`
- `__FIREBASE_STORAGE_BUCKET__`
- `__FIREBASE_MESSAGING_SENDER_ID__`
- `__FIREBASE_APP_ID__`

These are client-side identifiers rather than administrative secrets, but keeping placeholders in the repository reduces accidental publication of environment-specific configuration.
