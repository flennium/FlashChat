# FlashChat Features

## 1. Authentication

Supported sign-in methods:

- email + password
- Google Sign-In

Relevant files:

- `lib/services/auth_service.dart`
- `lib/features/auth/controllers/auth_controller.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/register_screen.dart`

Important behavior:

- a Firestore profile is created automatically for new users
- each new user also gets a unique username
- if Google sign-in creates a first-time user, a profile document is also created

## 2. Splash and Session Handling

The app opens on `SplashScreen`.

What it does:

- listens to Firebase Auth
- waits briefly for branding/smooth startup
- sends signed-in users to `HomeShell`
- sends signed-out users to `LoginScreen`

## 3. Rooms

Users can:

- browse all rooms
- search rooms by name or description
- create rooms
- edit owned/admin rooms
- join private rooms with an access code

Room list logic:

- rooms stream from Firestore in real time
- UI filters the list locally using the search query

Private room logic:

- room stores `isPrivate`
- room stores `accessCode`
- join is rejected if the code does not match

## 4. Messaging

Supported message types:

- text messages
- image messages

Messaging behavior:

- messages stream live from Firestore
- newest messages are loaded with `limitToLast(...)`
- older messages load on scroll
- pagination increases the query limit

Extra message features:

- edit message text
- delete for everyone
- delete for me
- reply to a specific message
- emoji reactions
- unread divider
- date separators

## 5. Read State

When a room is open:

- the screen watches room messages
- unread messages are detected
- `markRead(...)` updates both message `readBy` lists and the member unread counter

User-facing results:

- unread counts on rooms
- unread divider inside chat

## 6. Typing Indicators

Typing is tracked with Realtime Database presence.

Behavior:

- when the user starts/stops typing, `typingRoomId` is updated
- other users subscribed to presence see matching typing-room entries
- the chat screen shows a typing indicator near the input

## 7. Online Presence

Presence is initialized in `HomeShell`.

Behavior:

- signed-in user is marked online
- `onDisconnect()` marks the user offline automatically
- the app can display an online count

## 8. Mentions

Users can mention others with `@username`.

Mention support exists in two layers:

### Client-side parsing

The app detects:

- mentions already present in text
- an active mention query while the user is typing

This supports autocomplete and better text handling.

### Server-side notification

Firebase Cloud Functions scan new messages for mentions and notify matching users.

## 9. Push Notifications

There are two kinds of push notifications:

- room-message notifications
- mention notifications

Room-message notifications:

- triggered by the sender client
- sent through the Supabase Edge Function

Mention notifications:

- triggered by Firebase Cloud Functions
- sent through Firebase Admin SDK

Foreground behavior:

- the app shows a custom notification banner
- if the user is already inside the same room, the banner is suppressed

## 10. Media Uploads

Supported uploads:

- user avatar
- room avatar
- chat image

Flow:

1. pick image with `image_picker`
2. upload bytes to Supabase Storage
3. save the resulting public URL in Firestore

## 11. Profile Management

Users can manage:

- name
- bio
- username
- avatar

Username change logic:

- checks availability
- reserves the new username
- releases the old username
- updates the presence username snapshot

## 12. Settings

Settings include:

- theme mode: light, dark, system
- theme color variant
- change password
- password reset email
- sign out
- delete account

Theme choices are stored locally with `SharedPreferences`.

## 13. Global Announcement

The app can display a global pinned announcement using Firebase Remote Config.

This allows changing a message without publishing a new app version.

## 14. Tests

Current tests include:

- mention parsing behavior
- basic widget test scaffold

The strongest current automated coverage is for mention parsing logic.

## 15. Distribution Targets

The repository is currently prepared to distribute:

- Android APK builds
- Windows desktop ZIP bundles

These can be produced locally or through GitHub Actions releases.

## 16. Feature Gaps / Improvement Ideas

Possible future improvements:

- server-side general notifications instead of client-triggered sending
- stronger moderation
- message search
- media caching
- better account deletion cleanup across related collections
- broader test coverage
