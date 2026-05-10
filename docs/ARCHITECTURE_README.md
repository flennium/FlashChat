# FlashChat Architecture

## 1. Purpose

FlashChat is a real-time chat application built with Flutter. Its goal is to provide room-based messaging with modern social features such as replies, reactions, typing indicators, unread counts, mentions, avatars, and push notifications.

The project uses a hybrid backend:

- Firebase Authentication for login and identity
- Cloud Firestore for main app data
- Firebase Realtime Database for live presence
- Firebase Remote Config for a global announcement
- Firebase Cloud Functions for automation
- Firebase Cloud Messaging for push delivery
- Supabase Storage for uploaded images

## 2. High-Level Structure

The project is split into these main areas:

- `lib/`: Flutter client application
- `functions/`: Firebase Cloud Functions
- `supabase/functions/send-notification/`: Supabase Edge Function for FCM v1 delivery
- `assets/branding/`: app images and logos
- `test/`: unit and widget tests
- `docs/`: project documentation

## 3. Client Architecture

The Flutter app follows a lightweight layered structure:

- `models/`: plain Dart models for users, rooms, and messages
- `services/`: direct integrations with Firebase, Supabase, and device APIs
- `core/`: constants, providers, theme, and reusable utilities
- `features/`: UI and state per app feature

This is not a strict clean architecture project with repositories and use cases. Instead, it uses a practical structure:

- UI widgets call controllers
- controllers call services
- services talk to Firebase/Supabase
- models convert Firestore maps into Dart objects

## 4. State Management

The app uses Riverpod.

Main Riverpod patterns in this project:

- `Provider`: for singleton-style services such as `AuthService` and `FirestoreService`
- `StreamProvider`: for real-time Firestore/Auth/Presence streams
- `FutureProvider`: for one-shot async loads such as Remote Config
- `StateProvider`: for local app state such as active room id or pagination limits
- `StateNotifierProvider`: for controllers that perform actions like sign-in or sending a message

This keeps UI code relatively thin and makes dependencies easy to access with `ref.read(...)` and `ref.watch(...)`.

## 5. App Startup Flow

Startup path:

1. `main.dart` initializes Flutter bindings.
2. Background FCM handler is registered.
3. `AppBootstrap.initialize()` runs.
4. Firebase is initialized.
5. Supabase is initialized if credentials are available.
6. Crashlytics hooks are registered.
7. `ProviderScope` wraps the app.
8. `FlashChatApp` loads theme state and opens `SplashScreen`.

`SplashScreen` listens to Firebase Auth state:

- if a user is signed in, it navigates to `HomeShell`
- otherwise it navigates to `LoginScreen`

## 6. Navigation Structure

The main in-app container is `HomeShell`.

It shows three top-level sections:

- Rooms
- Profile
- Settings

From Rooms, the user can:

- browse rooms
- search rooms
- create a room
- join/open a room

Opening a room pushes `ChatScreen`.

## 7. Data Flow Example: Sending a Message

When a user sends text:

1. `MessageInput` triggers the chat controller.
2. `ChatController.sendText(...)` loads the current profile.
3. It calls `FirestoreService.sendMessage(...)`.
4. A message document is created in `rooms/{roomId}/messages/{messageId}`.
5. The sender is added to `readBy`.
6. After success, the app attempts to send push notifications.
7. It collects room-member FCM tokens except the sender.
8. It calls the Supabase Edge Function `send-notification`.
9. Firebase Cloud Functions separately update unread counters and mention notifications.

This means push sending is split:

- normal room-message notifications are triggered by the Flutter client through Supabase
- mention notifications are triggered server-side through Firebase Cloud Functions

## 8. Presence and Live UX

Presence is handled with Firebase Realtime Database instead of Firestore.

Why:

- presence updates change often
- RTDB is cheaper and more natural for online status
- it supports `onDisconnect()`, which is useful for marking a user offline automatically

Presence node stores:

- `online`
- `typingRoomId`
- `username`

This powers:

- online counter
- typing indicator
- username-aware typing labels

## 9. Notification Design

There are two notification systems:

### Client-triggered room notifications

Used for general room messages.

- The sender app gathers FCM tokens of other room members.
- It calls the Supabase Edge Function.
- The Edge Function sends FCM v1 requests to Google.

### Server-triggered mention notifications

Used when a message contains `@username`.

- Firebase Cloud Function parses the text.
- It resolves usernames through the `usernames` collection.
- It sends a notification only to mentioned users who are room members.

### Foreground suppression

When the app is already open in a room, the active room id is tracked in Riverpod.

If a foreground push arrives for the same room:

- the custom in-app banner is suppressed
- the user still sees the message directly in chat

## 10. Media Handling

Supabase Storage is used only for uploaded media:

- user avatars
- room avatars
- chat images

Firestore stores only the resulting public URLs, not the file bytes.

This keeps Firestore focused on structured data while storage handles files.

## 11. Theme System

The app supports:

- light mode
- dark mode
- system mode
- multiple color variants

Theme preferences are stored locally with `SharedPreferences`.

## 12. Backend Responsibilities Split

Firebase handles:

- auth
- structured app data
- presence
- cloud automation
- config
- crash reporting

Supabase handles:

- file storage
- custom notification edge function

This split is unusual but valid. It works because each service is used for a focused purpose.

## 13. Strengths of the Current Architecture

- Simple to follow once services are understood
- Good use of real-time streams for chat
- Clear separation between models, services, and screens
- Presence is implemented with the right Firebase product
- Media is kept out of Firestore

## 14. Limitations and Tradeoffs

- Business logic is distributed between Flutter, Firebase Functions, and Supabase
- General push notifications are client-triggered, which is simpler but less authoritative than a full server-driven design
- Some generated/config files were mixed into the project directory before cleanup
- There is no Git repository metadata in this folder, so change history is not available

## 15. Files to Read First

If you want to understand the architecture quickly, read these in order:

1. `lib/main.dart`
2. `lib/services/app_bootstrap.dart`
3. `lib/core/providers/app_providers.dart`
4. `lib/services/firestore_service.dart`
5. `lib/features/chat/controllers/chat_controller.dart`
6. `functions/index.js`
7. `supabase/functions/send-notification/index.ts`
