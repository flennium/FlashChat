# FlashChat Architecture

FlashChat is a Flutter chat app with a practical feature-based client architecture and a hybrid Firebase + Supabase backend.

This document explains how the app is organized today and how data and actions move through the system.

## 1. High-Level Architecture

FlashChat is built around these major parts:

- Flutter client for UI and app logic
- Firebase Auth for identity
- Cloud Firestore for persistent app data
- Firebase Realtime Database for presence and typing
- Firebase Remote Config for a global announcement
- Firebase Cloud Messaging for device notification delivery
- Supabase Storage for uploaded media
- Supabase Edge Function for FCM v1 push sending

## 2. Repository Structure

| Area | Purpose |
| --- | --- |
| `lib/` | Main Flutter application |
| `lib/features/` | Feature-specific screens, controllers, and widgets |
| `lib/services/` | Firebase, Supabase, and device-facing service layer |
| `lib/models/` | Main Dart models |
| `lib/core/` | Providers, constants, utilities, and theming |
| `supabase/functions/` | Active Edge Function backend |
| `functions/` | Legacy Firebase Functions reference |
| `docs/` | Project documentation |

## 3. Client Structure

The client is not organized as strict clean architecture. It uses a simpler flow that matches the current size of the app:

- widgets and screens render UI
- controllers perform actions
- services talk to Firebase, Supabase, and device APIs
- models map Firestore documents into Dart objects

Current design strengths:

- easy to trace from UI to backend call
- lightweight enough for a student/project-scale app
- real-time streams stay close to where the UI needs them

Tradeoff:

- business logic is spread across the client instead of being centralized in a deep domain layer

## 4. Main Layers

### `models`

Current model classes:

- `UserModel`
- `RoomModel`
- `MessageModel`

These are plain Dart data models with `fromMap` / `toMap` style conversions.

### `services`

This is the backend integration layer.

Examples:

- `AuthService`
- `FirestoreService`
- `PresenceService`
- `StorageService`
- `FcmService`
- `RemoteConfigService`

### `core`

Holds app-wide infrastructure such as:

- Riverpod providers
- constants and environment access
- mention utilities
- platform support checks
- theme controllers

### `features`

UI and interaction logic is grouped by app feature:

- auth
- rooms
- chat
- profile
- shell

## 5. State Management

The app uses Riverpod throughout the client.

Current patterns:

- `Provider` for services
- `StreamProvider` for live data
- `FutureProvider` for one-shot async loads
- `StateProvider` for lightweight local shared state
- `StateNotifierProvider` for action-oriented controllers

Examples:

- `authStateProvider`
- `currentUserProfileProvider`
- `roomListProvider`
- `roomMessagesProvider`
- `chatControllerProvider`
- `roomOnlineCountProvider`

This gives the app a strong reactive flow without introducing a larger framework than needed.

## 6. App Startup Flow

The startup path is:

1. `main.dart` initializes Flutter bindings
2. background FCM handling is registered where supported
3. `AppBootstrap.initialize()` runs
4. Firebase initializes
5. Supabase initializes if config exists
6. Crashlytics hooks are installed on supported platforms
7. the app starts inside `ProviderScope`

Routing flow:

- `SplashScreen` observes auth state
- signed-in users go to `HomeShell`
- signed-out users go to `LoginScreen`

## 7. Navigation Structure

`HomeShell` is the main signed-in container.

Top-level sections:

- Rooms
- Profile
- Settings

Navigation patterns:

- room list pushes `ChatScreen`
- create/edit room flows use `CreateRoomScreen`
- room and user details open in sheets/modals

This keeps the main app structure shallow and easy to follow.

## 8. Room Architecture

Room features are split across:

- room list screen
- create/edit room screen
- room tile UI
- room info sheet
- room controller

Current room flow:

1. rooms stream from Firestore
2. room list filters locally in the UI
3. selecting a room checks membership and private-room access
4. joining a room writes membership data into Firestore
5. opening a room pushes the chat screen

Important design choice:

- room cards are intentionally lighter now
- extra room metadata lives in the room info sheet and the chat header entry point

## 9. Chat Architecture

The chat feature is the most real-time-heavy part of the app.

Main pieces:

- `ChatScreen`
- `ChatController`
- `MessageInput`
- `MessageBubble`

Current responsibilities:

- live message stream
- pagination
- reply handling
- reactions
- read tracking
- typing updates
- room-scoped online count

The chat screen combines multiple live data sources:

- Firestore messages
- Firestore room data
- Realtime Database presence
- local reply state
- local pagination state

## 10. Data Flow Example: Sending A Message

Current send-text flow:

1. the user types into `MessageInput`
2. `ChatController.sendText(...)` is called
3. the current user profile is read from Riverpod
4. `FirestoreService.sendMessage(...)` writes the message document
5. the sender is included in the initial `readBy`
6. the UI refreshes automatically from the Firestore stream

If the message is a reply:

- a compact `replyTo` snapshot is embedded into the message document

If the message contains mentions:

- mention parsing and notification targeting are resolved through client-side logic plus Firestore lookup helpers

## 11. Presence And Live Interaction

Presence is intentionally separated from Firestore.

Current Realtime Database usage:

- `online`
- `typingRoomId`
- `username`

This powers:

- online status in profiles
- room-scoped chat online count
- typing indicator labels

Important platform behavior:

- desktop platforms intentionally avoid some live features where Firebase plugin support is limited
- profile UI falls back to recent `lastSeen` for better status wording

## 12. Notification Architecture

Notifications are not driven by a full server-triggered backend pipeline right now.

Current notification path:

1. the Flutter client decides which users should be notified
2. it collects FCM tokens from Firestore
3. it calls the Supabase Edge Function
4. the Edge Function sends FCM v1 notifications

This supports:

- room-message notifications
- mention notifications

Foreground UX:

- a custom banner is shown in-app
- banners are suppressed if the user is already inside the active room

Tradeoff:

- the design is simple and cost-friendly
- it is less authoritative than a fully backend-triggered system

## 13. Media Architecture

Supabase Storage handles file uploads.

Current upload types:

- user avatars
- room avatars
- chat images

Architecture choice:

- binary files stay out of Firestore
- Firestore stores only public URLs and metadata

This keeps the structured data layer focused and easier to reason about.

## 14. Theme And Appearance Architecture

The app supports:

- light mode
- dark mode
- system mode
- multiple color variants

These are managed through small dedicated controllers in `lib/core/theme/`.

Persistence:

- theme choices are stored locally, not in Firestore

## 15. Platform Support Strategy

The app does not treat every platform identically.

Examples:

- push notifications are primarily mobile/web oriented
- Crashlytics is mobile-focused
- desktop Firebase initialization reuses the web Firebase options path
- some live presence features are intentionally reduced on desktop

This is a pragmatic compatibility strategy rather than a perfectly uniform one.

## 16. Backend Responsibility Split

### Firebase handles

- identity
- app data
- presence
- remote config
- push token registration
- crash reporting

### Supabase handles

- media storage
- FCM v1 transport through the Edge Function

This split is deliberate:

- Firebase remains the main application backend
- Supabase is used where it adds value without replacing the whole stack

## 17. Current Architectural Strengths

- straightforward feature-based organization
- clear real-time data flow using Riverpod streams
- practical split between persistent data and ephemeral presence
- good separation between structured data and uploaded media
- simple enough to onboard quickly

## 18. Current Architectural Tradeoffs

- some important backend behavior is still client-triggered
- business rules are distributed across services and controllers
- desktop support is intentionally partial in some realtime areas
- notification authority and cleanup logic are not as centralized as they would be in a larger production backend

## 19. Suggested Reading Order

If you want to understand the app quickly, read these files in this order:

1. `lib/main.dart`
2. `lib/services/app_bootstrap.dart`
3. `lib/core/providers/app_providers.dart`
4. `lib/services/firestore_service.dart`
5. `lib/services/presence_service.dart`
6. `lib/features/rooms/controllers/room_controller.dart`
7. `lib/features/chat/controllers/chat_controller.dart`
8. `supabase/functions/send-notification/index.ts`
