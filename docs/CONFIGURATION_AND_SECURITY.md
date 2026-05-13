# Configuration And Security

This document explains how FlashChat handles configuration, secrets, ignored files, and release-signing expectations.

## 1. Purpose

Use this guide to understand:

- which values must be provided locally
- which values must be provided in CI
- which files should stay out of version control
- which secrets are required for Android release builds

## 2. Configuration Sources

FlashChat reads configuration from several places:

| Source | Used For |
| --- | --- |
| `lib/firebase_options.dart` | Firebase client setup |
| `android/app/google-services.json` | Android Firebase client config |
| `.env.local` | local Dart define values for development |
| GitHub Actions secrets | CI-only Firebase config and signing data |
| Supabase Edge Function secrets | server-side notification delivery |
| Firestore `app/config` | small runtime admin config |

## 3. Local Development Configuration

For local development, the main non-committed inputs are:

- `android/app/google-services.json`
- `.env.local`

You may also have a local `lib/firebase_options.dart` depending on your setup.

Current repo note:

- `.gitignore` excludes `lib/firebase_options.dart`
- the file may still exist locally on a developer machine
- if you switch Firebase projects, regenerate or replace it accordingly

The recommended local run path is:

```powershell
.\scripts\flutter-with-env.ps1 run
```

That helper script reads `.env.local` and passes the required Dart defines to Flutter automatically.

## 4. Dart Define Values

The app reads these values from `lib/core/constants/app_env.dart`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_AVATAR_BUCKET`
- `SUPABASE_CHAT_IMAGE_BUCKET`
- `GOOGLE_WEB_CLIENT_ID`

Expected local file:

- `.env.local`

Example:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_AVATAR_BUCKET=avatars
SUPABASE_CHAT_IMAGE_BUCKET=chat-images
GOOGLE_WEB_CLIENT_ID=
```

Security note:

- `SUPABASE_ANON_KEY` is a client-side key, not a service-role secret
- it still should not be hardcoded unnecessarily in source files

## 5. Firebase Client Configuration

The app relies on FlutterFire client configuration.

Main files:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Important behavior:

- Android uses the Android Firebase config
- desktop currently reuses the web Firebase options path through `firebase_platform_options.dart`

That means the web configuration inside `lib/firebase_options.dart` must also be valid if you want desktop Firebase behavior to work correctly.

## 6. Ignored Files And Sensitive Files

The following are intentionally excluded by `.gitignore` or should otherwise stay out of version control:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- Firebase admin/service-account JSON files
- `.env.local`
- `functions/node_modules/`
- `supabase/.temp/`
- build outputs
- IDE-specific folders

Why:

- these files are environment-specific
- some contain secrets
- some are generated locally

## 7. CI / GitHub Actions Secrets

The repository uses GitHub Actions for Android and release workflows.

### Required Firebase secrets

- `FIREBASE_OPTIONS_DART`
- `GOOGLE_SERVICES_JSON`

These are typically the raw contents of:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

### Required Android signing secrets

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Why they matter:

- Android release builds must always use the same keystore
- otherwise CI can produce APKs that look like a different signing identity
- that breaks upgrade continuity and can cause Firebase/App Distribution confusion

Current release expectation:

- workflows should fail if required signing inputs are missing, rather than silently using the wrong signing path

## 8. Local Android Release Signing

For local release builds, the Gradle configuration can use:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Optional strict flag:

- `REQUIRE_RELEASE_SIGNING=true`

If these are absent, local release builds may fall back to debug signing unless strict signing is required.

Security note:

- do not commit keystore files
- do not commit keystore passwords
- do not paste signing secrets into source-controlled files

## 9. Supabase Secrets

The active notification backend is:

- `supabase/functions/send-notification`

Required backend secret:

- `FIREBASE_SERVICE_ACCOUNT`

This should contain the Firebase service-account JSON string used to obtain FCM v1 access tokens.

This must:

- stay in Supabase secrets or another secret manager
- never be committed into the repository
- never be exposed to the Flutter client

## 10. Firestore Runtime Config

The app also reads a small amount of operational config from Firestore.

Path:

- collection: `app`
- document: `config`

Important field:

- `roomAdminEmail`

Purpose:

- allows a configured email address to manage rooms even if that user is not the original creator

Security note:

- this is runtime app configuration, not a secret
- it should still be changed carefully because it affects moderation/admin behavior

## 11. Web Push Placeholder Config

The committed `web/firebase-messaging-sw.js` file uses placeholder Firebase values.

Before enabling real web push in deployment, replace placeholders such as:

- `__FIREBASE_API_KEY__`
- `__FIREBASE_AUTH_DOMAIN__`
- `__FIREBASE_PROJECT_ID__`
- `__FIREBASE_STORAGE_BUCKET__`
- `__FIREBASE_MESSAGING_SENDER_ID__`
- `__FIREBASE_APP_ID__`

These are client identifiers rather than admin secrets, but using placeholders in the repo helps prevent accidental publishing of environment-specific values.

## 12. Public Repository Checklist

Before sharing or publishing the repo more broadly, verify:

1. no Firebase service-account JSON files are tracked
2. no Supabase service-role keys are tracked
3. `google-services.json` is not tracked
4. `lib/firebase_options.dart` is not tracked in the public repo state
5. `.env.local` is not tracked
6. no keystore file is tracked
7. no password or token is hardcoded in source
8. CI uses secrets instead of committed sensitive files

## 13. Practical Security Notes

These are the most important real-world rules for this project:

- treat keystores and service-account JSON files as highly sensitive
- keep client config and server secrets separate
- prefer environment variables and secret managers over local plaintext reuse
- remember that notification delivery depends on a backend secret, not just client code
- keep signing identity stable across all Android releases

## 14. Related Docs

- [SETUP_GUIDE.md](SETUP_GUIDE.md)
- [BACKEND_README.md](BACKEND_README.md)
- [ARCHITECTURE_README.md](ARCHITECTURE_README.md)
