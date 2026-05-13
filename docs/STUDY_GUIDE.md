# FlashChat Study Guide

This guide is for understanding, presenting, and defending the FlashChat project.

## 1. Short Project Summary

FlashChat is a room-based real-time chat application built with Flutter.

Users can:

- create an account
- join or create rooms
- send text and image messages
- react to messages
- reply to messages
- mention other users
- use private rooms with access codes
- see unread counts, typing indicators, and presence

The app uses Firebase as the main backend and Supabase for media storage and push-delivery infrastructure.

## 2. One-Minute Explanation

If you need a short answer:

> FlashChat is a Flutter chat app that uses Firebase Authentication for login, Cloud Firestore for users, rooms, and messages, Realtime Database for presence and typing, and Supabase Storage for uploaded media. Riverpod manages state on the client, and push notifications are sent through a Supabase Edge Function using Firebase Cloud Messaging.

## 3. Main Goal Of The Project

The goal of FlashChat is not just to send messages. The goal is to build a modern chat app with the kinds of interactive features users expect in real products, such as:

- live updates
- unread state
- replies
- reactions
- mentions
- profile customization
- room privacy
- push notifications

So this project is a good example of a medium-sized Flutter app with real backend integration, realtime data flow, and platform tradeoffs.

## 4. Technologies Used And Why

### Flutter

Why it was chosen:

- one codebase for multiple platforms
- fast UI iteration
- strong widget system for custom chat interfaces

What it gives this project:

- shared Android and Windows UI
- quick experimentation with custom chat layouts

### Riverpod

Why it was chosen:

- clean dependency injection
- simple reactive access to streams and services
- good fit for auth state, Firestore streams, and action controllers

What it gives this project:

- providers for services
- stream-based UI updates
- clearer separation between widgets and logic

### Firebase Authentication

Why it was chosen:

- fast setup for email/password login
- built-in session handling
- optional Google sign-in support

What it gives this project:

- identity
- session persistence
- reliable auth state stream

### Cloud Firestore

Why it was chosen:

- real-time snapshots
- simple document structure for users, rooms, and messages
- flexible schema for a project that evolved over time

What it gives this project:

- the main persistent data layer
- real-time room and message streams

### Firebase Realtime Database

Why it was chosen:

- better fit for fast-changing temporary presence data
- supports `onDisconnect()`

What it gives this project:

- online/offline state
- typing indicators
- live room online counts

### Firebase Cloud Messaging

Why it was chosen:

- standard push notification system for Firebase-based apps

What it gives this project:

- device token registration
- push delivery target for room and mention notifications

### Firebase Remote Config

Why it was chosen:

- simple way to change one global announcement without shipping a new app build

### Firebase Crashlytics

Why it was chosen:

- capture runtime crashes on supported platforms

### Supabase Storage

Why it was chosen:

- convenient public file hosting for media uploads
- keeps raw image files out of Firestore

What it gives this project:

- avatar uploads
- room avatar uploads
- chat image uploads

### Supabase Edge Function

Why it was chosen:

- FCM v1 requires OAuth2 access-token generation
- the client should not contain a Firebase service-account secret

What it gives this project:

- backend push delivery without relying on a full Blaze-plan Firebase Functions setup

## 5. High-Level App Structure

The project is organized like this:

- `lib/models/`
- `lib/services/`
- `lib/core/`
- `lib/features/`

### `models`

Contains the main Dart data models:

- `UserModel`
- `RoomModel`
- `MessageModel`

### `services`

Contains backend and platform integrations:

- `AuthService`
- `FirestoreService`
- `PresenceService`
- `StorageService`
- `FcmService`
- `RemoteConfigService`
- `AppBootstrap`

### `core`

Contains shared infrastructure:

- Riverpod providers
- constants
- environment access
- mention parsing utilities
- platform support checks
- theme controllers

### `features`

Contains app-specific UI and controllers:

- auth
- rooms
- chat
- profile
- shell

## 6. Main Backend Responsibilities

### Firebase handles

- authentication
- users
- usernames
- rooms
- room membership
- messages
- unread counters
- room admin config
- presence
- typing indicators
- remote config announcement
- crash reporting

### Supabase handles

- storage buckets
- edge function used to send FCM notifications

## 7. End-To-End User Flow

### Registration

1. user enters name, email, and password
2. Firebase Auth creates the account
3. the app creates `users/{uid}`
4. the app creates `usernames/{username}`

Important note:

- creating a Firebase user manually in Firebase Console does not create the Firestore profile automatically
- the app flow is what creates the matching documents

### Login

1. user signs in
2. Firebase Auth session becomes active
3. `SplashScreen` detects the signed-in state
4. app navigates to `HomeShell`

### App startup after login

1. `AppBootstrap.initialize()` runs
2. Firebase initializes
3. Supabase initializes if environment values are available
4. presence is initialized where supported
5. FCM token setup runs where supported
6. the app loads Rooms / Profile / Settings navigation

### Creating a room

1. user opens the create room screen
2. user enters room name, description, privacy mode, and optional access code
3. user can upload a room avatar
4. the app writes a room document
5. the creator is also added to the room members subcollection

### Opening a private room

1. the app checks if the user is already a member
2. if not, it asks for the access code
3. the latest room data is fetched before validation
4. membership is created if the code is valid

### Sending a message

1. the user types in `MessageInput`
2. the chat controller reads the current user profile
3. a message document is created in Firestore
4. the sender is included in `readBy`
5. the message stream updates the UI
6. unread tracking and mention targeting logic run through the client-side flow

### Uploading media

1. user picks an image
2. file bytes upload to Supabase Storage
3. returned public URL is saved in Firestore
4. UI reads that URL later

## 8. Core Features You Should Be Able To Explain

### Rooms

- rooms are streamed from Firestore
- search is filtered locally in the UI
- private rooms require an access code
- room details are shown in a room info sheet
- room cards were redesigned to show less clutter and move detail into the room info flow

### Messages

- real-time Firestore stream
- pagination using larger message limits
- replies
- reactions
- edit
- delete for me
- delete for everyone
- unread divider
- date separators

### Mentions

- detects an active mention query while typing
- shows autocomplete suggestions
- inserts the selected username into the input
- highlights mentions in rendered messages
- resolves mentioned usernames through Firestore

### Presence and typing

- presence stored in Realtime Database
- typing stored as `typingRoomId`
- profile status can fall back to recent `lastSeen`
- room online count is room-scoped, not global

### Notifications

- general room-message notifications
- mention notifications
- custom in-app foreground banner
- suppression when user is already inside the active room

### Settings and profile

- theme mode and theme variants
- build/version details
- profile editing
- avatar upload
- username changes
- password change/reset
- account deletion flow

## 9. Important Design Decisions

These are good design decisions to mention in a presentation:

- using a separate `usernames` collection to enforce unique usernames cleanly
- using Firestore for main data and Realtime Database for temporary presence
- storing media in Supabase instead of Firestore
- denormalizing sender and owner snapshot fields for faster reads
- grouping logic into services and controllers instead of placing everything in widgets
- using a room info sheet to reduce clutter in the room list UI

## 10. Why Denormalization Was Used

Some user data is intentionally copied into messages and rooms.

Examples:

- `senderName`
- `senderUsername`
- `senderAvatar`
- `createdByName`
- `createdByUsername`

Why this helps:

- fewer follow-up reads
- faster rendering
- old content keeps the visual context it had when created

Tradeoff:

- profile updates do not automatically rewrite all historical room/message snapshots

## 11. Files You Should Understand First

If you understand these files, you understand most of the project:

- `lib/main.dart`
- `lib/services/app_bootstrap.dart`
- `lib/core/providers/app_providers.dart`
- `lib/services/auth_service.dart`
- `lib/services/firestore_service.dart`
- `lib/services/presence_service.dart`
- `lib/services/storage_service.dart`
- `lib/features/rooms/controllers/room_controller.dart`
- `lib/features/chat/controllers/chat_controller.dart`
- `lib/features/chat/screens/chat_screen.dart`
- `lib/features/chat/widgets/message_input.dart`
- `supabase/functions/send-notification/index.ts`

## 12. Questions You May Be Asked

### "Why did you use both Firestore and Realtime Database?"

Good answer:

> Firestore is the main structured data store for users, rooms, and messages. Realtime Database is used only for fast-changing temporary state like online presence and typing because it supports `onDisconnect()` and is a better fit for that kind of live signal.

### "Why not store images directly in Firestore?"

Good answer:

> Firestore is good for structured documents, not binary file storage. Supabase Storage stores the actual files, while Firestore stores only the resulting public URLs and related metadata.

### "How do private rooms work?"

Good answer:

> A room stores `isPrivate` and `accessCode`. When a user tries to enter a private room, the app checks whether the user is already a member. If not, it prompts for the code and validates it against the latest Firestore room data before creating the membership document.

### "How do unread counts work?"

Good answer:

> The app tracks read state at two levels: each message has a `readBy` list, and each room member document stores an `unreadCount`. `readBy` supports message-level logic, while `unreadCount` is faster for room-list badges.

### "How are mentions implemented?"

Good answer:

> The client parses `@username` in two ways: while typing for autocomplete, and after sending for final resolution. Usernames are resolved through the `usernames` collection, and only valid room members are targeted for mention notifications.

### "Why are notifications sent through Supabase?"

Good answer:

> The project uses a Supabase Edge Function to send FCM v1 notifications because FCM v1 requires server-side OAuth2 token creation using a Firebase service account. That secret should not be shipped in the client.

### "What does Riverpod do in this project?"

Good answer:

> Riverpod provides services, real-time streams, and action controllers. It lets the UI react to Firebase state cleanly and helps keep widgets smaller by moving actions into controllers and services.

### "What are the current platform tradeoffs?"

Good answer:

> The app is strongest on Android. Windows support exists, but some Firebase live features intentionally degrade where plugin support is limited, such as push notifications and full realtime presence behavior.

## 13. Honest Weaknesses To Admit

These are honest and reasonable tradeoffs to mention:

- notification triggering is still largely client-driven
- automated test coverage is still lighter than the feature surface
- desktop support is partial in some realtime areas
- account deletion and deep cleanup flows are more complex than simple CRUD
- some backend responsibilities are spread across Flutter logic and the Edge Function instead of living in one authoritative backend layer

These are not project failures. They are useful engineering tradeoffs to acknowledge clearly.

## 14. Strengths Worth Highlighting

Strong points of the project:

- real-time chat with multiple interactive features
- practical hybrid backend design
- clean feature grouping in Flutter
- good use of Firebase products for different workloads
- meaningful UI polish beyond a basic CRUD app
- support for richer chat behavior like mentions, replies, and reactions

## 15. Best Reading Order

If you want to study the project efficiently:

1. `README.md`
2. `docs/SETUP_GUIDE.md`
3. `docs/ARCHITECTURE_README.md`
4. `docs/DATA_MODEL_README.md`
5. `docs/FEATURES_README.md`
6. `docs/BACKEND_README.md`
7. then read the core files from section 11

## 16. Framing

A stronger framing is:

> FlashChat is a multi-service real-time Flutter application that combines authentication, room-based messaging, presence, media upload, notifications, and profile management in one cohesive product.

That framing better matches the actual amount of engineering in the project.
