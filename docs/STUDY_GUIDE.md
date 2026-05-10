# FlashChat Explain Guide

## 1. What This Project Is

FlashChat is a room-based real-time chat app built with Flutter.

The main idea is:

- users sign in
- they create or join chat rooms
- they exchange text and image messages
- the app shows live updates, typing state, unread counts, and notifications

## 2. One-Minute Explanation

> FlashChat is a Flutter chat app that uses Firebase Authentication for login, Firestore for rooms and messages, Realtime Database for online presence and typing indicators, and Supabase Storage for images. Riverpod is used for state management, and notifications are sent through Firebase Cloud Messaging.

## 3. Why Each Technology Was Chosen

### Flutter

- one codebase for multiple platforms
- fast UI development

### Riverpod

- clean dependency injection
- reactive UI with providers
- good for real-time streams

### Firebase Authentication

- easy email and Google sign-in
- managed sessions

### Cloud Firestore

- real-time document database
- good fit for rooms, users, and messages

### Realtime Database

- better suited for presence and typing updates
- supports `onDisconnect()`

### Firebase Cloud Functions

- automatic backend actions on Firestore events
- used for unread counts, mention notifications, and member counts

### Supabase Storage

- easy file storage and public URLs
- keeps images out of Firestore

## 4. End-to-End User Flow

### Registration

1. user enters name, email, and password
2. Firebase creates the auth account
3. app creates a `users/{uid}` document
4. app reserves a unique username in `usernames/{username}`

### Login

1. Firebase validates credentials
2. auth stream updates
3. app opens `HomeShell`

### Opening the App

1. splash screen listens for auth state
2. if signed in, app loads home
3. `HomeShell` initializes presence and FCM token registration

### Creating a Room

1. user enters room data
2. app writes a room document
3. app creates a membership document for the creator

### Sending a Message

1. chat controller creates a Firestore message
2. sender is marked as having read it
3. the app tries to send notifications to other room members
4. backend functions update unread counts

## 5. Files You Should understand

If you understand these files, you understand most of the project:

- `lib/main.dart`
- `lib/services/app_bootstrap.dart`
- `lib/core/providers/app_providers.dart`
- `lib/services/auth_service.dart`
- `lib/services/firestore_service.dart`
- `lib/services/presence_service.dart`
- `lib/services/storage_service.dart`
- `lib/features/chat/controllers/chat_controller.dart`
- `lib/features/chat/screens/chat_screen.dart`
- `functions/index.js`
- `supabase/functions/send-notification/index.ts`

## 6. Questions And Good Answers

### "Why did you use Firestore for chat messages?"

Because Firestore gives real-time streams and document-based storage, which fits rooms and messages well. It also works nicely with Flutter streams through `snapshots()`.

### "Why not store images in Firestore?"

Firestore is for structured data, not raw file storage. Images are uploaded to Supabase Storage, then only their URLs are stored in Firestore.

### "Why use Realtime Database as well as Firestore?"

Presence and typing status change very frequently. Realtime Database is more suitable for temporary live state and supports automatic offline handling with `onDisconnect()`.

### "How do unread messages work?"

Each message has a `readBy` list, and each room member document also has an `unreadCount`. The count is fast for badges, while `readBy` is detailed enough for per-message logic.

### "How are mentions implemented?"

The client detects mention text while typing, and the backend parses new message text with a regex. It resolves usernames using the `usernames` collection and sends notifications to valid mentioned users.

### "What does Riverpod do here?"

Riverpod provides app services, real-time streams, and action controllers. It keeps business logic out of widgets and makes state changes easier to track.

## 7. Design Decisions

- storing username reservations in a separate collection for uniqueness
- keeping avatars and images in Supabase instead of Firestore
- using Realtime Database for presence
- using denormalized sender fields in messages for faster UI rendering
- separating controllers from services

## 8. Honest Weaknesses I Admit

These are reasonable engineering tradeoffs to mention:

- notification logic is split between Firebase Functions and a Supabase Edge Function
- moderation is basic and based on a simple banned-word list
- test coverage is still limited
- some generated files had to be cleaned from the project directory

These answers sound informed, not defensive.


## 9. Suggested Reading Order

1. `README.md`
2. `docs/ARCHITECTURE_README.md`
3. `docs/DATA_MODEL_README.md`
4. `docs/FEATURES_README.md`
5. `docs/BACKEND_README.md`
6. read the core files listed in section 5
