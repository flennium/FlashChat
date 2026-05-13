# FlashChat Data Model

This document explains how FlashChat stores app data across Firestore and Realtime Database, and which Dart models represent that data in the app.

## At A Glance

### Firestore

| Path | Purpose |
| --- | --- |
| `users/{uid}` | User profile data |
| `usernames/{username}` | Username reservation and lookup |
| `rooms/{roomId}` | Room metadata |
| `rooms/{roomId}/members/{uid}` | Room membership and unread state |
| `rooms/{roomId}/messages/{messageId}` | Chat messages |
| `app/config` | Global admin-style app config |

### Realtime Database

| Path | Purpose |
| --- | --- |
| `presence/{uid}` | Online state and typing presence |

## Dart Models In This Project

These are the model classes currently present in `lib/models/`:

| Model | File | Stored In |
| --- | --- | --- |
| `UserModel` | `lib/models/user_model.dart` | `users/{uid}` |
| `RoomModel` | `lib/models/room_model.dart` | `rooms/{roomId}` |
| `MessageModel` | `lib/models/message_model.dart` | `rooms/{roomId}/messages/{messageId}` |

Important note:

- there is no dedicated Dart model yet for `room members`, `username reservations`, or `presence`
- those structures are still important and are documented below because the app reads and writes them directly

## 1. UserModel

**File:** `lib/models/user_model.dart`  
**Firestore path:** `users/{uid}`

### Core fields

| Field | Type | Meaning |
| --- | --- | --- |
| `uid` | string | Firestore document id and Auth user id |
| `name` | string | Display name |
| `username` | string | Public unique username |
| `email` | string | Login email |
| `avatarUrl` | string | Profile image URL |
| `bio` | string | User bio |
| `createdAt` | timestamp | Account creation time |
| `lastSeen` | timestamp? | Last known activity timestamp |

### Settings and notification fields

| Field | Type | Meaning |
| --- | --- | --- |
| `theme` | string | Saved theme preference |
| `notificationsEnabled` | bool | Whether push notifications are allowed |
| `fcmToken` | string | Device push token |
| `mutedRooms` | list<string> | Room ids muted by the user |

### Moderation / lifecycle fields

| Field | Type | Meaning |
| --- | --- | --- |
| `isDeleted` | bool | Whether the account was soft-deleted |
| `deletedAt` | timestamp? | When deletion happened |
| `blockedUsers` | list<string> | Reserved for blocking logic |

### App-level computed getters

`UserModel` also exposes:

- `displayName`
- `handleLabel`

These are presentation helpers used by the UI so deleted or incomplete profiles still render safely.

## 2. RoomModel

**File:** `lib/models/room_model.dart`  
**Firestore path:** `rooms/{roomId}`

### Core fields

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Room document id |
| `name` | string | Room name |
| `description` | string | Room description |
| `createdBy` | string | Owner uid |
| `createdAt` | timestamp | Room creation time |

### Access and identity fields

| Field | Type | Meaning |
| --- | --- | --- |
| `isPrivate` | bool | Whether the room needs an access code |
| `accessCode` | string | Private-room code |
| `avatarUrl` | string | Room avatar URL |
| `createdByName` | string | Owner display-name snapshot |
| `createdByUsername` | string | Owner username snapshot |

### Room state fields

| Field | Type | Meaning |
| --- | --- | --- |
| `pinnedMessage` | string | Room-level pinned text |
| `memberCount` | int | Cached member count |

### App-level helpers

`RoomModel` also exposes:

- `ownerLabel`
- `copyWith(...)`

The owner snapshot fields are intentionally denormalized so room cards and room info screens can show owner information without additional lookups.

## 3. MessageModel

**File:** `lib/models/message_model.dart`  
**Firestore path:** `rooms/{roomId}/messages/{messageId}`

### Core message fields

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Message document id |
| `text` | string | Message text |
| `imageUrl` | string | Optional uploaded image |
| `senderId` | string | Sender uid |
| `senderName` | string | Sender display-name snapshot |
| `senderUsername` | string | Sender username snapshot |
| `senderAvatar` | string | Sender avatar snapshot |
| `timestamp` | timestamp | Message creation time |

### Edit and deletion fields

| Field | Type | Meaning |
| --- | --- | --- |
| `isDeleted` | bool | Whether the message was deleted for everyone |
| `isEdited` | bool | Whether the message text was edited |
| `editedAt` | timestamp? | Edit time |
| `deletedFor` | list<string> | Users who hid the message locally |

### Realtime interaction fields

| Field | Type | Meaning |
| --- | --- | --- |
| `reactions` | map<string, list<string>> | Emoji -> user ids |
| `readBy` | list<string> | Users who have read the message |
| `replyTo` | map<string, dynamic>? | Embedded reply preview data |

### `replyTo` structure

When a message is a reply, the embedded payload typically contains:

- `id`
- `senderId`
- `senderName`
- `senderUsername`
- `text`
- `imageUrl`

This is stored inline so reply previews still work even if the original message changes later.

## 4. Stored Structures Without Dedicated Dart Models

These are still part of the real data model even though they are not separate classes in `lib/models/`.

### Username reservation

**Firestore path:** `usernames/{username}`

| Field | Type | Meaning |
| --- | --- | --- |
| `uid` | string | Owner of that username |

Why it exists:

- usernames must be unique
- fast lookup from `@username` to `uid`
- easier mention resolution

### Room member entry

**Firestore path:** `rooms/{roomId}/members/{uid}`

| Field | Type | Meaning |
| --- | --- | --- |
| `joinedAt` | timestamp | When the user joined |
| `lastReadAt` | timestamp | Last room-read timestamp |
| `unreadCount` | int | Cached unread counter for room list badges |

This structure decides room membership. If the member document exists, that user belongs to the room.

### Presence entry

**Realtime Database path:** `presence/{uid}`

| Field | Type | Meaning |
| --- | --- | --- |
| `online` | bool | Whether the user is online |
| `typingRoomId` | string | Room currently being typed in |
| `username` | string | Latest username snapshot |

This data is transient and presence-oriented, not long-term business data.

### App config entry

**Firestore path:** `app/config`

Common field used by the app:

| Field | Type | Meaning |
| --- | --- | --- |
| `roomAdminEmail` | string | Email allowed to manage rooms globally |

## 5. Denormalization Strategy

FlashChat intentionally duplicates some profile data into other documents.

Examples:

- `rooms.createdByName`
- `rooms.createdByUsername`
- `messages.senderName`
- `messages.senderUsername`
- `messages.senderAvatar`

Why this helps:

- chat screens render faster
- fewer follow-up reads are needed
- old messages keep the sender context they were created with

Tradeoff:

- updating a user profile does not automatically rewrite every historical room or message document

## 6. Read And Unread Tracking

Unread state is stored in two layers:

### Message level

- `messages.readBy`

Used for:

- per-message read logic
- deciding which messages are unread

### Membership level

- `members.unreadCount`
- `members.lastReadAt`

Used for:

- fast room-list unread badges
- efficient “mark room as read” behavior

This is a common denormalized chat pattern.

## 7. Notifications And Delivery Data

Push-related data is mostly driven by the user profile plus message context.

Relevant fields:

- `users/{uid}.fcmToken`
- `users/{uid}.notificationsEnabled`
- message sender snapshot fields
- room id carried in notification payloads

Common payload metadata:

- `roomId`
- `type`

## 8. Model Relationships

Here is the main relationship flow:

1. Firebase Auth creates the authenticated identity
2. `users/{uid}` stores the profile
3. `usernames/{username}` maps public usernames back to a uid
4. `rooms/{roomId}` stores room metadata
5. `rooms/{roomId}/members/{uid}` stores room membership and unread state
6. `rooms/{roomId}/messages/{messageId}` stores chat history
7. `presence/{uid}` stores temporary online and typing state

## 9. Security-Relevant Notes

Important access expectations in this data model:

- users should only edit their own user profile
- room creators or configured room admins manage rooms
- message creation should match `request.auth.uid`
- reaction and read-state writes are narrower than full message edits

To understand enforcement details, read this document together with:

- `firestore.rules`
- `realtime database rules` in Firebase console
- [CONFIGURATION_AND_SECURITY.md](CONFIGURATION_AND_SECURITY.md)
