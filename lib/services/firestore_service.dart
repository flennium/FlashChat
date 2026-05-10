import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/firebase_constants.dart';
import '../models/message_model.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';

class MentionNotificationTargets {
  const MentionNotificationTargets({
    required this.uids,
    required this.tokens,
  });

  final List<String> uids;
  final List<String> tokens;
}

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  // Rooms

  Stream<List<RoomModel>> watchRooms() {
    return _firestore
        .collection(FirebaseConstants.rooms)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => RoomModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<RoomModel?> watchRoom(String roomId) {
    return _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RoomModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<String> watchRoomAdminEmail() {
    return _firestore
        .collection(FirebaseConstants.app)
        .doc(FirebaseConstants.config)
        .snapshots()
        .map((doc) =>
            (doc.data()?['roomAdminEmail'] as String?)?.trim().toLowerCase() ??
            '');
  }

  Future<void> createRoom({
    required String name,
    required String description,
    required bool isPrivate,
    String accessCode = '',
    String avatarUrl = '',
  }) async {
    final user = _auth.currentUser!;
    final ownerProfile = await fetchCurrentUserProfile();
    final doc = _firestore.collection(FirebaseConstants.rooms).doc(_uuid.v4());
    final room = RoomModel(
      id: doc.id,
      name: name,
      description: description,
      createdBy: user.uid,
      createdByName: ownerProfile?.name ?? user.displayName ?? '',
      createdByUsername: ownerProfile?.username ?? '',
      isPrivate: isPrivate,
      accessCode: accessCode,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
      memberCount: 1,
    );
    await doc.set(room.toMap());
    await doc.collection(FirebaseConstants.members).doc(user.uid).set({
      'joinedAt': FieldValue.serverTimestamp(),
      'lastReadAt': FieldValue.serverTimestamp(),
      'unreadCount': 0,
    });
  }

  Future<void> updateRoom({
    required RoomModel room,
    required String name,
    required String description,
    required bool isPrivate,
    String accessCode = '',
    String? avatarUrl,
  }) {
    return _firestore.collection(FirebaseConstants.rooms).doc(room.id).update({
      'name': name,
      'description': description,
      'isPrivate': isPrivate,
      'accessCode': isPrivate ? accessCode : '',
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
  }

  Future<void> deleteRoom(String roomId) {
    return _firestore.collection(FirebaseConstants.rooms).doc(roomId).delete();
  }

  Future<bool> isCurrentUserRoomMember(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.members)
        .doc(user.uid)
        .get();
    return doc.exists;
  }

  Future<bool> joinRoom({
    required RoomModel room,
    String accessCode = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final isMember = await isCurrentUserRoomMember(room.id);
    if (isMember) return true;

    if (room.isPrivate && room.accessCode.trim() != accessCode.trim()) {
      return false;
    }

    final roomRef = _firestore.collection(FirebaseConstants.rooms).doc(room.id);
    final memberRef =
        roomRef.collection(FirebaseConstants.members).doc(user.uid);

    await _firestore.runTransaction((txn) async {
      final memberSnap = await txn.get(memberRef);
      if (!memberSnap.exists) {
        txn.set(memberRef, {
          'joinedAt': FieldValue.serverTimestamp(),
          'lastReadAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        });
        txn.update(roomRef, {'memberCount': FieldValue.increment(1)});
      }
    });

    return true;
  }

  // Messages

  /// Streams the most recent [limit] messages for a room, ordered oldest to newest.
  Stream<List<MessageModel>> watchMessages(String roomId, {int limit = 30}) {
    return _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.messages)
        .orderBy('timestamp')
        .limitToLast(limit)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> sendMessage({
    required String roomId,
    required UserModel sender,
    String text = '',
    String imageUrl = '',
    Map<String, dynamic>? replyTo,
  }) async {
    final doc = _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.messages)
        .doc(_uuid.v4());
    final message = MessageModel(
      id: doc.id,
      text: text,
      imageUrl: imageUrl,
      senderId: sender.uid,
      senderName: sender.name,
      senderUsername: sender.username,
      senderAvatar: sender.avatarUrl,
      timestamp: DateTime.now(),
      readBy: [sender.uid],
      replyTo: replyTo,
    );
    final membersSnap = await _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.members)
        .get();

    final batch = _firestore.batch();
    batch.set(doc, message.toMap());

    for (final memberDoc in membersSnap.docs) {
      if (memberDoc.id == sender.uid) continue;
      batch.set(
        memberDoc.reference,
        {
          'unreadCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
  }) {
    return _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.messages)
        .doc(messageId)
        .update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessageForEveryone({
    required String roomId,
    required String messageId,
  }) {
    return _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.messages)
        .doc(messageId)
        .update({'isDeleted': true, 'text': '', 'imageUrl': ''});
  }

  Future<void> deleteMessageForMe({
    required String roomId,
    required String messageId,
    required String uid,
  }) {
    return _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.messages)
        .doc(messageId)
        .update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String uid,
    required List<String> currentUsers,
  }) {
    final nextUsers = currentUsers.contains(uid)
        ? currentUsers.where((u) => u != uid).toList()
        : [...currentUsers, uid];
    return _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.messages)
        .doc(messageId)
        .update({'reactions.$emoji': nextUsers});
  }

  Future<void> markRoomRead(
    String roomId,
    List<MessageModel> messages,
    String uid,
  ) async {
    final batch = _firestore.batch();
    for (final m in messages.where((m) => !m.readBy.contains(uid))) {
      final ref = _firestore
          .collection(FirebaseConstants.rooms)
          .doc(roomId)
          .collection(FirebaseConstants.messages)
          .doc(m.id);
      batch.update(ref, {
        'readBy': [...m.readBy, uid],
      });
    }
    await batch.commit();
    await _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.members)
        .doc(uid)
        .set({
      'lastReadAt': FieldValue.serverTimestamp(),
      'unreadCount': 0,
    }, SetOptions(merge: true));
  }

  Stream<int> watchCurrentUserUnreadCount(String roomId) {
    final user = _auth.currentUser;
    if (user == null) return Stream<int>.value(0);

    return _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.members)
        .doc(user.uid)
        .snapshots()
        .map((doc) => (doc.data()?['unreadCount'] as num?)?.toInt() ?? 0);
  }

  // Users

  Future<UserModel?> fetchCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection(FirebaseConstants.users)
        .doc(user.uid)
        .get();
    return doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null;
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _firestore
        .collection(FirebaseConstants.users)
        .doc(uid)
        .snapshots()
        .map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? bio,
    String? avatarUrl,
    String? fcmToken,
    String? theme,
    bool? notificationsEnabled,
  }) {
    return _firestore.collection(FirebaseConstants.users).doc(uid).update({
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (theme != null) 'theme': theme,
      if (notificationsEnabled != null)
        'notificationsEnabled': notificationsEnabled,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Username

  /// Resolves a username to its owner's uid, or null if not found.
  Future<String?> getUidByUsername(String username) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usernames)
        .doc(username.toLowerCase())
        .get();
    return doc.data()?['uid'] as String?;
  }

  /// Returns true if [username] is not already reserved.
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usernames)
        .doc(username.toLowerCase())
        .get();
    return !doc.exists;
  }

  /// Atomically reserves [username] for [uid], releasing [oldUsername] if provided.
  Future<void> claimUsername({
    required String uid,
    required String username,
    String? oldUsername,
  }) async {
    final batch = _firestore.batch();
    final lc = username.toLowerCase();
    batch.set(_firestore.collection(FirebaseConstants.usernames).doc(lc), {
      'uid': uid,
    });
    if (oldUsername != null && oldUsername.isNotEmpty) {
      batch.delete(
        _firestore.collection(FirebaseConstants.usernames).doc(
              oldUsername.toLowerCase(),
            ),
      );
    }
    batch.update(_firestore.collection(FirebaseConstants.users).doc(uid), {
      'username': lc,
    });
    await batch.commit();
  }

  // User search

  /// Returns up to [limit] users whose username starts with [prefix].
  Future<List<UserModel>> searchUsersByUsername(
    String prefix, {
    int limit = 4,
  }) async {
    final lc = prefix.trim().toLowerCase();
    final snapshot = lc.isEmpty
        ? await _firestore
            .collection(FirebaseConstants.users)
            .orderBy('username')
            .limit(limit * 2)
            .get()
        : await _firestore
            .collection(FirebaseConstants.users)
            .orderBy('username')
            .where('username', isGreaterThanOrEqualTo: lc)
            .where('username', isLessThan: '$lc')
            .limit(limit)
            .get();
    return snapshot.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .where((user) => user.username.isNotEmpty)
        .take(limit)
        .toList();
  }

  // Notifications

  /// Returns FCM tokens of every room member except [excludeUid].
  /// Respects each user's [notificationsEnabled] flag.
  Future<List<String>> getRoomMemberFcmTokens({
    required String roomId,
    required String excludeUid,
    Set<String> excludeUids = const {},
  }) async {
    final membersSnap = await _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.members)
        .get();

    final uids = membersSnap.docs
        .map((d) => d.id)
        .where((uid) => uid != excludeUid && !excludeUids.contains(uid))
        .toList();

    if (uids.isEmpty) return [];

    final tokens = <String>[];
    // Firestore whereIn supports max 10 items per query
    for (int i = 0; i < uids.length; i += 10) {
      final batch = uids.sublist(i, (i + 10).clamp(0, uids.length));
      final usersSnap = await _firestore
          .collection(FirebaseConstants.users)
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in usersSnap.docs) {
        final d = doc.data();
        final token = (d['fcmToken'] as String?) ?? '';
        final enabled = (d['notificationsEnabled'] as bool?) ?? true;
        if (token.isNotEmpty && enabled) tokens.add(token);
      }
    }
    return tokens;
  }

  Future<MentionNotificationTargets> getMentionNotificationTargets({
    required String roomId,
    required Iterable<String> usernames,
    required String excludeUid,
  }) async {
    final normalized = usernames
        .map((username) => username.trim().toLowerCase())
        .where((username) => username.isNotEmpty)
        .toSet()
        .toList();

    if (normalized.isEmpty) {
      return const MentionNotificationTargets(uids: [], tokens: []);
    }

    final membersSnap = await _firestore
        .collection(FirebaseConstants.rooms)
        .doc(roomId)
        .collection(FirebaseConstants.members)
        .get();
    final memberUids = membersSnap.docs.map((doc) => doc.id).toSet();

    final usernameDocs = await Future.wait(
      normalized.map(
        (username) => _firestore
            .collection(FirebaseConstants.usernames)
            .doc(username)
            .get(),
      ),
    );

    final mentionedUids = usernameDocs
        .map((doc) => doc.data()?['uid'] as String?)
        .whereType<String>()
        .where((uid) => uid != excludeUid && memberUids.contains(uid))
        .toSet()
        .toList();

    if (mentionedUids.isEmpty) {
      return const MentionNotificationTargets(uids: [], tokens: []);
    }

    final tokens = <String>[];
    for (int i = 0; i < mentionedUids.length; i += 10) {
      final batch = mentionedUids.sublist(
        i,
        (i + 10).clamp(0, mentionedUids.length),
      );
      final usersSnap = await _firestore
          .collection(FirebaseConstants.users)
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final token = (data['fcmToken'] as String?) ?? '';
        final enabled = (data['notificationsEnabled'] as bool?) ?? true;
        if (token.isNotEmpty && enabled) {
          tokens.add(token);
        }
      }
    }

    return MentionNotificationTargets(uids: mentionedUids, tokens: tokens);
  }

  // Mute

  Future<void> toggleMuteRoom({
    required String uid,
    required String roomId,
    required bool isMuted,
  }) {
    return _firestore.collection(FirebaseConstants.users).doc(uid).update({
      'mutedRooms': isMuted
          ? FieldValue.arrayUnion([roomId])
          : FieldValue.arrayRemove([roomId]),
    });
  }
}
