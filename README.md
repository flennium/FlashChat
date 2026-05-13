# FlashChat

Real-time room-based chat built with Flutter, Firebase, and Supabase Storage.

## What It Includes

- Email and Google sign-in
- Public and private rooms
- Real-time messaging
- Replies, reactions, and mentions
- Unread counts, typing indicators, and presence
- Profiles and settings

## Tech Stack

| Layer | Tools |
| --- | --- |
| App | Flutter, Riverpod |
| Auth | Firebase Auth |
| Data | Cloud Firestore, Firebase Realtime Database |
| Notifications | Firebase Cloud Messaging, Firebase Remote Config |
| Media | Supabase Storage |

## Quick Start

1. Restore these local Firebase files:
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
2. Provide the app environment values used by `lib/core/constants/app_env.dart`
3. Install packages:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Required Environment Values

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_AVATAR_BUCKET`
- `SUPABASE_CHAT_IMAGE_BUCKET`
- `GOOGLE_WEB_CLIENT_ID`

## Firestore Admin Config

- Collection: `app`
- Document: `config`
- Field: `roomAdminEmail`

## GitHub Actions Secrets

Firebase config:

- `FIREBASE_OPTIONS_DART`
- `GOOGLE_SERVICES_JSON`

Android signing:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## Important Notes

- Android release builds must always use the same keystore.
- `supabase/functions/` contains the active notification backend.
- `functions/index.js` is legacy reference code.

## Documentation

| Topic | Link |
| --- | --- |
| Setup | [SETUP_GUIDE.md](docs/SETUP_GUIDE.md) |
| Architecture | [ARCHITECTURE_README.md](docs/ARCHITECTURE_README.md) |
| Data Model | [DATA_MODEL_README.md](docs/DATA_MODEL_README.md) |
| Features | [FEATURES_README.md](docs/FEATURES_README.md) |
| Backend | [BACKEND_README.md](docs/BACKEND_README.md) |
| Configuration and Security | [CONFIGURATION_AND_SECURITY.md](docs/CONFIGURATION_AND_SECURITY.md) |
| Study Guide | [STUDY_GUIDE.md](docs/STUDY_GUIDE.md) |
