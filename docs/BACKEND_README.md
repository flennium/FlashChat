# FlashChat Backend And Operations

## 1. Backend Overview

FlashChat does not use a single backend service. Instead, it combines Firebase and Supabase.

Firebase is used for:

- Authentication
- Cloud Firestore
- Realtime Database
- Cloud Messaging
- Remote Config
- Crashlytics

Supabase is used for:

- Storage buckets
- Edge Function that sends FCM v1 push notifications

## 2. Firebase Authentication

Authentication methods:

- email/password
- Google Sign-In

The Flutter client creates a matching Firestore user document after registration or first Google sign-in.

## 3. Cloud Firestore

Firestore is the main source of truth for app data.

Key responsibilities:

- users
- usernames
- rooms
- room membership
- messages
- unread counters
- room admin configuration

Important service file:

- `lib/services/firestore_service.dart`

Current note:

- unread counters are updated directly by the Flutter client when a message is created

## 4. Realtime Database

Realtime Database is used only for ephemeral presence data.

Responsibilities:

- online/offline state
- typing-room tracking
- username snapshot for typing labels

Important service file:

- `lib/services/presence_service.dart`

## 5. Firebase Remote Config

Used for one global announcement string:

- key: `global_pinned_message`

Important service file:

- `lib/services/remote_config_service.dart`

## 6. Legacy Firebase Cloud Functions

Main file:

- `functions/index.js`

This folder is now kept as a legacy reference, not as the active production backend for the Spark-plan setup.

### `onNewMessage`

Trigger:

- Firestore `rooms/{roomId}/messages/{messageId}` on create

Responsibilities:

- increment unread counts for room members except sender
- extract `@username` mentions
- resolve usernames to user ids
- send mention notifications to valid room members

Current status:

- this logic has been replaced in the active app flow by Flutter client code plus the Supabase Edge Function

### `moderateMessage`

Trigger:

- Firestore `rooms/{roomId}/messages/{messageId}` on create

Responsibilities:

- check message text against a banned-word list
- soft-delete messages that contain banned content

Current moderation is intentionally simple and easy to extend.

Current status:

- no active Spark-plan replacement is deployed for this moderation function

### `updateMemberCount`

Trigger:

- Firestore `rooms/{roomId}/members/{uid}` on write

Responsibilities:

- recount member documents
- update cached `memberCount` on the room

Current status:

- room creation and join flows already keep `memberCount` updated on the client side

## 7. Supabase Edge Function

Main file:

- `supabase/functions/send-notification/index.ts`

Purpose:

- send FCM v1 push notifications using a Firebase service account

Why this exists:

- FCM v1 requires OAuth2 access tokens
- this edge function creates a signed JWT, exchanges it for an access token, and sends push messages

Request body contains:

- `tokens`
- `title`
- `body`
- `data`

Important behavior:

- all `data` values are converted to strings because FCM v1 requires string payload values
- message and mention notifications can be compacted by sender using platform-specific collapse keys / tags

## 8. Security Rules

Main files:

- `firestore.rules`
- `storage.rules`

Firestore rule highlights:

- only signed-in users can read most data
- users can write only their own profile
- usernames can be created/deleted only by the owner
- rooms can be managed by the creator or configured room admin
- messages can be created only by the authenticated sender
- shared message updates are limited to read and reaction fields

## 9. Configuration Values

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

Field:

- `roomAdminEmail`

Purpose:

- allows a configured email to manage rooms even if not the original creator

### Supabase secret

Edge Function secret:

- `FIREBASE_SERVICE_ACCOUNT`

This should contain the full Firebase service-account JSON string.

## 10. Local Development

Typical Flutter commands:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Legacy Firebase Functions install:

```bash
cd functions
npm install
```

Supabase Edge Function development depends on the Supabase CLI if local testing is needed.

## 11. Deployment Notes

Legacy Firebase Cloud Functions:

- deployment requires the Firebase Blaze plan
- they are not required for the current Spark-plan setup

Supabase Edge Function:

- deploy from `supabase/functions/send-notification/`

Flutter app:

- standard `flutter build` commands for Android/web/etc.

## 12. Operational Risks

Current areas to watch:

- notification logic depends on the Flutter client plus the Supabase Edge Function
- service-account secrets must not stay in the project folder
- client-triggered general notifications can be bypassed or duplicated more easily than server-triggered ones
- account deletion currently removes the auth user and profile doc, but deeper cleanup may still be desirable

## 13. Recommended Production Improvements

- move all push logic fully server-side
- expand moderation beyond a hard-coded banned-word list
- add cleanup jobs for orphaned media files
- add more tests for backend behavior
- move secrets entirely into environment/secret managers

## 14. Related Documentation

For publication and secret-handling guidance, also read:

- `docs/CONFIGURATION_AND_SECURITY.md`
