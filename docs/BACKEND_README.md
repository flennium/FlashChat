# FlashChat Backend And Operations

FlashChat uses a hybrid backend built around Firebase, with Supabase used for media storage and push-delivery infrastructure.

## 1. Backend Overview

### Firebase is used for

- Authentication
- Cloud Firestore
- Realtime Database
- Firebase Cloud Messaging
- Firebase Remote Config
- Crashlytics

### Supabase is used for

- Storage buckets
- Edge Function that sends FCM v1 push notifications

## 2. Current Source Of Truth By Concern

| Concern | Primary backend |
| --- | --- |
| Sign-in and identity | Firebase Auth |
| Users, rooms, messages | Cloud Firestore |
| Presence and typing | Realtime Database |
| Global announcement | Firebase Remote Config |
| Crash reporting | Firebase Crashlytics |
| Media files | Supabase Storage |
| Push delivery transport | Supabase Edge Function |

## 3. Firebase Authentication

Supported methods:

- email/password
- Google Sign-In on supported platforms

Current behavior:

- registration creates the Auth account
- the app then creates the Firestore profile
- first-time Google sign-in also creates the Firestore profile

Main file:

- `lib/services/auth_service.dart`

## 4. Cloud Firestore

Firestore is the main persistent data store.

Main responsibilities:

- user profiles
- username reservation
- room metadata
- room membership
- room messages
- unread counters
- app configuration such as `roomAdminEmail`

Main file:

- `lib/services/firestore_service.dart`

Important current note:

- much of the app logic that could live in backend triggers is currently executed by the Flutter client directly

## 5. Realtime Database

Realtime Database is used for ephemeral live state, not long-term records.

Current responsibilities:

- online/offline state
- typing room id
- username snapshot for live typing labels

Main file:

- `lib/services/presence_service.dart`

Current design note:

- room online count is derived by combining room members from Firestore with online presence data from RTDB

## 6. Firebase Remote Config

Remote Config currently powers one global announcement string.

Key:

- `global_pinned_message`

Main file:

- `lib/services/remote_config_service.dart`

## 7. Firebase Cloud Messaging

FCM is used for device notification delivery, but the app does not rely on a full Firebase Cloud Functions backend for the current active flow.

Current responsibilities:

- device token registration
- receiving foreground/background notifications
- passing notification payloads into the app

Main file:

- `lib/services/fcm_service.dart`

## 8. Crashlytics

Crashlytics is initialized during app bootstrap on supported platforms.

Current behavior:

- Flutter framework errors can be reported
- platform-level uncaught errors can be reported
- desktop support is intentionally limited by platform capability rules

Main file:

- `lib/services/app_bootstrap.dart`

## 9. Supabase Storage

Supabase Storage is used for uploaded media only.

Current buckets:

- `avatars`
- `chat-images`

What is stored there:

- profile avatars
- room avatars
- chat image attachments

The app stores the resulting public URLs in Firestore.

Main file:

- `lib/services/storage_service.dart`

## 10. Supabase Edge Function

Active function:

- `supabase/functions/send-notification/index.ts`

Purpose:

- accept a list of FCM tokens
- create an OAuth2 access token for FCM v1 using a Firebase service account
- send push notifications through the FCM v1 API

Expected request body fields:

- `tokens`
- `title`
- `body`
- `data`

Current implementation note:

- all payload `data` values are coerced to strings because FCM v1 requires string values

## 11. Current Notification Flow

The current active notification path is:

1. the Flutter client creates or observes the message event
2. it gathers eligible tokens from Firestore
3. it calls the Supabase Edge Function
4. the Edge Function sends the FCM v1 notifications

This applies to:

- room-message notifications
- mention notifications

Important tradeoff:

- this is simpler than a full server-triggered model, but less authoritative than a backend-only notification pipeline

## 12. Username And Mention Resolution

Mentions are resolved through Firestore, not through a special backend service.

Current flow:

- the client parses `@username`
- usernames are resolved via `usernames/{username}`
- valid room-member targets are converted into notification targets

Main logic lives in:

- `lib/services/firestore_service.dart`
- `lib/core/utils/mention_utils.dart`

## 13. Room Membership And Unread Counters

Room membership is stored in:

- `rooms/{roomId}/members/{uid}`

Current responsibilities in this structure:

- membership existence
- join timestamp
- unread counter
- last read timestamp

Current note:

- unread tracking is maintained by client-side flows and Firestore writes, not by an active server trigger

## 14. Legacy Firebase Cloud Functions

Legacy reference folder:

- `functions/`

Current status:

- it is not the primary production path for the current setup
- it remains useful as historical reference for earlier backend logic

Examples found there:

- unread count updates
- mention notification targeting
- simple moderation
- member count maintenance

Why it matters:

- some documentation or older assumptions may still reference these functions
- the active app flow has moved away from depending on them directly

## 15. Configuration Values

### Dart environment values

Read from `lib/core/constants/app_env.dart`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_AVATAR_BUCKET`
- `SUPABASE_CHAT_IMAGE_BUCKET`
- `GOOGLE_WEB_CLIENT_ID`

### Firestore config document

Path:

- `app/config`

Important field:

- `roomAdminEmail`

Purpose:

- allows a configured email to manage rooms globally

### Supabase secret

Edge Function secret:

- `FIREBASE_SERVICE_ACCOUNT`

This must not be committed into the repo.

## 16. Local Operations

Common local commands:

```bash
flutter pub get
flutter analyze
flutter test
```

Typical local run on Windows PowerShell:

```powershell
.\scripts\flutter-with-env.ps1 run
```

For setup details, read:

- `docs/SETUP_GUIDE.md`

## 17. Deployment Notes

### Flutter app

Built with standard Flutter build commands or GitHub Actions workflows.

### Android signing

Release builds should use the same release keystore every time.

### Supabase Edge Function

Deploy from:

- `supabase/functions/send-notification/`

### Legacy Firebase Functions

They are not required for the main active Spark-plan-style app flow.

## 18. Operational Risks

Current areas to watch:

- notification flow depends on client-triggered token gathering
- service-account secrets must remain outside the repo
- media cleanup can become orphaned without deeper cleanup routines
- account deletion is broader than a simple profile delete and should be tested carefully
- desktop support intentionally degrades around unsupported Firebase live features

## 19. Recommended Future Improvements

- move more notification logic to backend-triggered flows
- add cleanup routines for orphaned storage files
- expand moderation beyond legacy examples
- improve test coverage around backend-facing services
- formalize Realtime Database rules and document them alongside Firestore rules

## 20. Related Docs

- [ARCHITECTURE_README.md](ARCHITECTURE_README.md)
- [DATA_MODEL_README.md](DATA_MODEL_README.md)
- [CONFIGURATION_AND_SECURITY.md](CONFIGURATION_AND_SECURITY.md)
