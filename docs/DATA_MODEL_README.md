# FlashChat Data Model

## 1. Main Collections

The project mainly uses these Firestore collections:

- `users`
- `usernames`
- `rooms`
- `rooms/{roomId}/members`
- `rooms/{roomId}/messages`
- `app/config`

It also uses one Realtime Database path:

- `presence/{uid}`

## 2. User Model

Firestore path:

- `users/{uid}`

Important fields:

- `name`: display name
- `username`: unique public username
- `email`: login email
- `avatarUrl`: profile image URL
- `fcmToken`: push-notification device token
- `bio`: user biography
- `createdAt`: account creation time
- `lastSeen`: last profile update / activity timestamp
- `theme`: saved theme preference
- `notificationsEnabled`: whether push is allowed
- `blockedUsers`: reserved for future blocking logic
- `mutedRooms`: list of muted room ids

Model class:

- `lib/models/user_model.dart`

## 3. Username Reservation Model

Firestore path:

- `usernames/{username}`

Fields:

- `uid`: owner user id

Why this exists:

- usernames must be unique
- querying by document id is simpler than scanning `users`
- mentions can resolve quickly from username to uid

## 4. Room Model

Firestore path:

- `rooms/{roomId}`

Important fields:

- `name`: room title
- `description`: room description
- `createdBy`: owner uid
- `createdByName`: owner display name snapshot
- `createdByUsername`: owner username snapshot
- `isPrivate`: whether join requires access code
- `accessCode`: room join code if private
- `avatarUrl`: room image URL
- `pinnedMessage`: room-level pinned message
- `memberCount`: cached number of members
- `createdAt`: room creation time

Model class:

- `lib/models/room_model.dart`

Notes:

- `createdByName` and `createdByUsername` are denormalized snapshots
- this avoids extra lookups when showing owner information

## 5. Room Member Model

Firestore path:

- `rooms/{roomId}/members/{uid}`

Important fields:

- `joinedAt`: when the user joined the room
- `lastReadAt`: last time the room was marked read
- `unreadCount`: unread-message counter for that user in that room

This subcollection determines membership.

If a member document exists, that user belongs to the room.

## 6. Message Model

Firestore path:

- `rooms/{roomId}/messages/{messageId}`

Important fields:

- `text`: message text
- `imageUrl`: optional image URL
- `senderId`: author uid
- `senderName`: display-name snapshot
- `senderUsername`: username snapshot
- `senderAvatar`: avatar snapshot
- `timestamp`: message creation time
- `isDeleted`: whether content has been deleted for everyone
- `isEdited`: whether message text was edited
- `editedAt`: edit timestamp
- `deletedFor`: per-user soft-delete list
- `reactions`: emoji to list-of-user-ids map
- `readBy`: list of users who have read the message
- `replyTo`: embedded reply metadata

Model class:

- `lib/models/message_model.dart`

## 7. Reply Data Structure

`replyTo` is stored directly inside a message document.

Expected structure:

- `id`
- `senderId`
- `senderName`
- `senderUsername`
- `text`
- `imageUrl`

Why embed it:

- reply preview still works even if the original message changes later
- no extra fetch is required to render a reply bubble

## 8. Realtime Database Presence Model

Realtime Database path:

- `presence/{uid}`

Fields:

- `online`: boolean
- `typingRoomId`: room id currently being typed in
- `username`: latest username snapshot

This data is temporary and presence-oriented, not long-term business data.

## 9. Remote Config Model

Remote Config key:

- `global_pinned_message`

The app fetches this value and can display it as a global announcement banner.

## 10. Denormalization Strategy

The project intentionally duplicates some user data inside room and message documents.

Examples:

- `senderName`
- `senderUsername`
- `senderAvatar`
- `createdByName`
- `createdByUsername`

Why this is useful:

- chat UIs need fast reads
- fewer joins are needed
- old messages keep the display context they were created with

Tradeoff:

- updates to the source profile do not automatically rewrite all old messages

## 11. Read/Unread Logic

Unread state is tracked in two places:

- message-level `readBy`
- member-level `unreadCount`

Purpose of each:

- `readBy` supports fine-grained read state per message
- `unreadCount` supports fast badge display in room lists

This is a common chat optimization pattern.

## 12. Notification-Related Data

Push-related fields:

- `users/{uid}.fcmToken`
- `users/{uid}.notificationsEnabled`
- message text, sender info, and room id in payloads

Notification payload data commonly includes:

- `roomId`
- `type`

## 13. Security-Relevant Relationships

Important access rules:

- signed-in users can read app data
- users can write only their own user document
- room creators or configured room admins can manage rooms
- message creation requires `senderId == request.auth.uid`
- message edits are limited to the sender, plus read/reaction-only shared updates

Read `firestore.rules` together with this data model.
