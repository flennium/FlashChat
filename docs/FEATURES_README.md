# FlashChat Features

This document describes the user-facing features currently implemented in FlashChat and how they behave in the live app.

## 1. Authentication

Supported sign-in methods:

- email and password
- Google Sign-In on supported platforms

Current platform note:

- Google Sign-In is available on mobile and web-oriented setups
- Windows users primarily rely on email/password

Current behavior:

- creating an account through the app also creates a Firestore user profile
- each user gets a username record in `usernames/{username}`
- first-time Google sign-in also creates the matching profile data

Main files:

- `lib/services/auth_service.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/register_screen.dart`
- `lib/features/auth/controllers/auth_controller.dart`

## 2. Startup And Session Flow

The app starts in `SplashScreen` and then routes based on Firebase Auth state.

Behavior:

- signed-in users are sent to `HomeShell`
- signed-out users are sent to `LoginScreen`
- app services are initialized in `AppBootstrap`

Main files:

- `lib/main.dart`
- `lib/services/app_bootstrap.dart`
- `lib/features/auth/screens/splash_screen.dart`

## 3. Rooms

Users can:

- browse all rooms
- search rooms by name or description
- create rooms
- edit rooms they own
- edit rooms if their email matches the configured room admin email
- delete owned/admin rooms
- join private rooms with an access code

Room design notes:

- room cards show a simplified overview
- extra room information lives in a dedicated room info sheet
- room details can be opened from the room list and from the chat header

Private room behavior:

- private rooms store `isPrivate` and `accessCode`
- users who are already members can open the room without re-entering the code
- access-code errors are handled inline in the dialog

Main files:

- `lib/features/rooms/screens/room_list_screen.dart`
- `lib/features/rooms/screens/create_room_screen.dart`
- `lib/features/rooms/widgets/room_tile.dart`
- `lib/features/rooms/widgets/room_info_sheet.dart`
- `lib/features/rooms/controllers/room_controller.dart`

## 4. Room Avatars

Rooms can have custom avatars.

Behavior:

- room creators/admins can upload a room avatar
- room avatars appear on room cards, room info sheets, and the chat header
- private rooms also display a lock badge

Media is uploaded through Supabase Storage and the public URL is saved in Firestore.

## 5. Messaging

Supported message content:

- text messages
- image messages

Current chat behavior:

- messages stream live from Firestore
- newest messages load first
- older messages load as the user scrolls up
- the chat view restores scroll position when older messages are loaded

Chat UI features:

- date separators
- unread divider
- reply preview
- message grouping
- timestamp reveal
- scroll-to-bottom action

Main files:

- `lib/features/chat/screens/chat_screen.dart`
- `lib/features/chat/widgets/message_input.dart`
- `lib/features/chat/widgets/message_bubble.dart`
- `lib/features/chat/controllers/chat_controller.dart`

## 6. Message Actions

Users can:

- edit their own message text
- delete for everyone
- delete for me
- reply to a message
- react with emoji

Current behavior:

- edits mark the message as edited
- delete-for-everyone clears visible content but keeps the message shell
- delete-for-me uses per-user soft deletion
- replies store an embedded reply snapshot

## 7. Mentions

Users can mention others with `@username`.

Current mention behavior:

- the input detects an active mention query while typing
- a small autocomplete list appears under the input
- selecting a suggestion inserts the username directly into the text
- chat bubbles render mentions in styled text

Notification behavior:

- the app resolves mentioned usernames through Firestore
- only valid room members are targeted for mention notifications

Main files:

- `lib/core/utils/mention_utils.dart`
- `lib/features/chat/widgets/message_input.dart`
- `lib/features/chat/widgets/message_bubble.dart`
- `lib/services/firestore_service.dart`

## 8. Read State And Unread Counts

Unread state is visible in two places:

- room list unread badges
- unread divider inside a chat

Current behavior:

- when a room is open, unread messages are detected
- `markRead(...)` updates both per-message `readBy` data and room-member unread data
- room cards read their badge count from member unread data

## 9. Presence, Online Status, And Typing

Presence uses Firebase Realtime Database.

Current live features:

- online/offline state
- typing room tracking
- room-scoped online count in the chat header
- profile modal status pills

Platform note:

- desktop avoids full RTDB live-signal behavior where the platform support is limited
- recent `lastSeen` is used as a fallback for profile activity wording

Main files:

- `lib/services/presence_service.dart`
- `lib/features/shell/screens/home_shell.dart`
- `lib/features/chat/widgets/online_indicator.dart`
- `lib/features/chat/widgets/typing_indicator.dart`
- `lib/features/profile/widgets/user_profile_modal.dart`

## 10. Notifications

FlashChat currently supports:

- general room-message notifications
- mention notifications

Current flow:

- the Flutter client gathers eligible FCM tokens
- it calls the Supabase Edge Function
- the Edge Function sends FCM v1 requests

Foreground behavior:

- the app shows a custom in-app banner for incoming notifications
- banners are suppressed if the user is already inside the same room

Platform note:

- push notifications are not treated as a primary desktop feature in the current setup

## 11. Media Uploads

Supported uploads:

- profile avatars
- room avatars
- chat images

Current flow:

1. pick an image locally
2. upload bytes to Supabase Storage
3. store the resulting public URL in Firestore

Main file:

- `lib/services/storage_service.dart`

## 12. Profile Features

Users can manage:

- display name
- bio
- username
- avatar

Current behavior:

- username changes are checked for availability
- the username reservation is moved atomically
- presence username snapshots are refreshed after username changes
- profile modal shows account details, status, and activity

Main files:

- `lib/features/profile/screens/profile_screen.dart`
- `lib/features/profile/controllers/profile_controller.dart`
- `lib/features/profile/widgets/user_profile_modal.dart`

## 13. Settings Features

Settings currently include:

- light / dark / system theme mode
- theme color variants
- sign out
- password change
- password reset email
- delete account
- app version/build details via the Build Studio sheet

Local preference behavior:

- theme mode and theme variant are stored locally

Main files:

- `lib/features/profile/screens/settings_screen.dart`
- `lib/core/theme/theme_mode_controller.dart`
- `lib/core/theme/theme_variant_controller.dart`

## 14. Account Deletion

The app includes a delete-account flow with confirmation.

Current cleanup intent includes:

- auth account
- user profile
- username reservation
- presence data
- memberships and other user-linked data

This area is more complex than simple sign-out and remains one of the higher-risk flows to keep testing carefully.

## 15. Global Announcement

The app can show a global announcement using Firebase Remote Config.

Current behavior:

- the app fetches a single announcement string
- if present, it appears as a banner in chat contexts
- unsupported desktop platforms fall back safely

Main files:

- `lib/services/remote_config_service.dart`
- `lib/core/providers/app_providers.dart`

## 16. Distribution Targets

The current repo is set up to produce:

- Android APK builds
- Windows desktop release builds
- Windows installer and portable release assets through GitHub Actions

## 17. Testing Status

Current automated coverage is still limited compared with the feature surface.

The most notable tested utility area is mention parsing, while much of the app behavior still depends on manual UI testing.

## 18. Known Tradeoffs

Current tradeoffs include:

- notification triggering is still client-driven
- some desktop experiences intentionally degrade where Firebase plugins are not fully supported
- account cleanup and deep data cleanup need ongoing attention
- automated coverage is lighter than ideal for the amount of UI and realtime behavior
