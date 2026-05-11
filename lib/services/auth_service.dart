import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../core/constants/app_env.dart';
import '../core/constants/firebase_constants.dart';
import '../core/utils/input_sanitizer.dart';
import '../core/utils/platform_support.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
    GoogleSignIn? googleSignIn,
    SupabaseClient? supabase,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: kIsWeb && AppEnv.googleWebClientId.isNotEmpty
                  ? AppEnv.googleWebClientId
                  : null,
            ),
        _supabase = supabase;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;
  final GoogleSignIn _googleSignIn;
  final SupabaseClient? _supabase;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: InputSanitizer.normalizeEmail(email),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? preferredUsername,
  }) async {
    final normalizedEmail = InputSanitizer.normalizeEmail(email);
    final normalizedName = InputSanitizer.normalizeDisplayName(name);
    final normalizedPreferredUsername = preferredUsername == null
        ? null
        : InputSanitizer.normalizeUsername(preferredUsername);
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final uid = credential.user!.uid;
    final username = await _resolveUsername(
      preferredUsername: normalizedPreferredUsername,
      email: normalizedEmail,
      uid: uid,
    );
    await _createUserDocument(
      uid: uid,
      name: normalizedName,
      email: normalizedEmail,
      username: username,
    );
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!PlatformSupport.supportsGoogleSignIn) {
      throw FirebaseAuthException(
        code: 'unsupported-platform',
        message: 'Google Sign-In is not available on this platform.',
      );
    }
    if (kIsWeb && AppEnv.googleWebClientId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-web-client-id',
        message: 'Google Sign-In on web requires GOOGLE_WEB_CLIENT_ID.',
      );
    }
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
          code: 'aborted', message: 'Google sign-in cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final doc = await _firestore
        .collection(FirebaseConstants.users)
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      final username = await _resolveUsername(
        email: InputSanitizer.normalizeEmail(user.email ?? ''),
        uid: user.uid,
      );
      await _createUserDocument(
        uid: user.uid,
        name: InputSanitizer.normalizeDisplayName(
          user.displayName ?? 'FlashChat User',
        ),
        email: InputSanitizer.normalizeEmail(user.email ?? ''),
        avatarUrl: user.photoURL ?? '',
        username: username,
      );
    }
    return userCredential;
  }

  Future<void> signOut() async {
    if (PlatformSupport.supportsGoogleSignIn) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final profile = await _loadUserProfile(user.uid);
    await _removeUserFromRoomMemberships(user.uid);
    await _anonymizeOwnedRooms(user.uid);
    await _anonymizeUserMessages(user.uid);
    await _anonymizeReplySnapshots(user.uid);
    await _softDeleteUserProfile(user.uid, profile?.username ?? '');
    await _deleteUserPresence(user.uid);
    await _deleteUserAvatar(profile?.avatarUrl ?? '');
    await user.delete();
    if (PlatformSupport.supportsGoogleSignIn) {
      await _googleSignIn.signOut();
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(
      email: InputSanitizer.normalizeEmail(email),
    );
  }

  /// Re-authenticates with [currentPassword] then sets [newPassword].
  /// Throws a [FirebaseAuthException] or plain [Exception] on failure.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Not signed in with an email account.');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Generates a unique username, trying [preferredUsername] first, then
  /// deriving from [email] with random suffix until a free slot is found.
  Future<String> _resolveUsername({
    String? preferredUsername,
    required String email,
    required String uid,
  }) async {
    if (preferredUsername != null && preferredUsername.isNotEmpty) {
      final available = await _isUsernameAvailable(preferredUsername);
      if (available) return preferredUsername.toLowerCase();
    }
    return _generateUniqueUsername(email: email, uid: uid);
  }

  /// Derives a base name from [email] prefix (strips non-alphanumeric chars)
  /// and appends a random numeric suffix until the username is unclaimed.
  Future<String> _generateUniqueUsername({
    required String email,
    required String uid,
  }) async {
    final normalizedEmail = InputSanitizer.normalizeEmail(email);
    final prefix = normalizedEmail
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .substring(0, min(15, normalizedEmail.split('@').first.length));

    final rng = Random();
    for (var attempt = 0; attempt < 10; attempt++) {
      final suffix = (rng.nextInt(9000) + 1000).toString(); // 4-digit suffix
      final candidate = '${prefix}_$suffix';
      if (await _isUsernameAvailable(candidate)) return candidate;
    }
    // Fallback: UID-based username (always unique)
    return 'user_${uid.substring(0, 8)}';
  }

  Future<bool> _isUsernameAvailable(String username) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usernames)
        .doc(username.toLowerCase())
        .get();
    return !doc.exists;
  }

  Future<void> _createUserDocument({
    required String uid,
    required String name,
    required String email,
    String avatarUrl = '',
    String username = '',
  }) async {
    final user = UserModel(
      uid: uid,
      name: InputSanitizer.normalizeDisplayName(name),
      username: InputSanitizer.normalizeUsername(username),
      email: InputSanitizer.normalizeEmail(email),
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
    );
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection(FirebaseConstants.users).doc(uid),
      user.toMap(),
    );
    if (user.username.isNotEmpty) {
      batch.set(
        _firestore.collection(FirebaseConstants.usernames).doc(user.username),
        {'uid': uid},
      );
    }
    await batch.commit();
  }

  Future<UserModel?> _loadUserProfile(String uid) async {
    final doc =
        await _firestore.collection(FirebaseConstants.users).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> _removeUserFromRoomMemberships(String uid) async {
    final roomsSnap =
        await _firestore.collection(FirebaseConstants.rooms).get();
    for (final roomDoc in roomsSnap.docs) {
      final memberRef =
          roomDoc.reference.collection(FirebaseConstants.members).doc(uid);
      final memberSnap = await memberRef.get();
      if (!memberSnap.exists) {
        continue;
      }

      final batch = _firestore.batch();
      batch.delete(memberRef);
      batch.update(roomDoc.reference, {
        'memberCount': FieldValue.increment(-1),
      });
      await batch.commit();
    }
  }

  Future<void> _anonymizeOwnedRooms(String uid) async {
    final roomsSnap = await _firestore
        .collection(FirebaseConstants.rooms)
        .where('createdBy', isEqualTo: uid)
        .get();
    for (final roomDoc in roomsSnap.docs) {
      await roomDoc.reference.update({
        'createdByName': 'Deleted user',
        'createdByUsername': '',
      });
    }
  }

  Future<void> _anonymizeUserMessages(String uid) async {
    final roomsSnap =
        await _firestore.collection(FirebaseConstants.rooms).get();
    for (final roomDoc in roomsSnap.docs) {
      final messagesSnap = await roomDoc.reference
          .collection(FirebaseConstants.messages)
          .where('senderId', isEqualTo: uid)
          .get();
      if (messagesSnap.docs.isEmpty) {
        continue;
      }

      final batch = _firestore.batch();
      for (final messageDoc in messagesSnap.docs) {
        batch.update(messageDoc.reference, {
          'senderName': 'Deleted user',
          'senderUsername': '',
          'senderAvatar': '',
        });
      }
      await batch.commit();
    }
  }

  Future<void> _anonymizeReplySnapshots(String uid) async {
    final roomsSnap =
        await _firestore.collection(FirebaseConstants.rooms).get();
    for (final roomDoc in roomsSnap.docs) {
      final repliesSnap = await roomDoc.reference
          .collection(FirebaseConstants.messages)
          .where('replyTo.senderId', isEqualTo: uid)
          .get();
      if (repliesSnap.docs.isEmpty) {
        continue;
      }

      final batch = _firestore.batch();
      for (final replyDoc in repliesSnap.docs) {
        final existingReplyTo = Map<String, dynamic>.from(
            replyDoc.data()['replyTo'] as Map? ?? const {});
        existingReplyTo['senderName'] = 'Deleted user';
        existingReplyTo['senderUsername'] = '';
        existingReplyTo['imageUrl'] = existingReplyTo['imageUrl'] ?? '';
        batch.update(replyDoc.reference, {
          'replyTo': existingReplyTo,
        });
      }
      await batch.commit();
    }
  }

  Future<void> _softDeleteUserProfile(String uid, String username) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection(FirebaseConstants.users).doc(uid), {
      'name': 'Deleted user',
      'username': '',
      'email': '',
      'avatarUrl': '',
      'fcmToken': '',
      'bio': '',
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'notificationsEnabled': false,
      'blockedUsers': <String>[],
      'mutedRooms': <String>[],
    });
    if (username.isNotEmpty) {
      batch.delete(
        _firestore
            .collection(FirebaseConstants.usernames)
            .doc(username.toLowerCase()),
      );
    }
    await batch.commit();
  }

  Future<void> _deleteUserPresence(String uid) async {
    try {
      await _database.ref('${FirebaseConstants.userPresence}/$uid').remove();
    } catch (_) {}
  }

  Future<void> _deleteUserAvatar(String avatarUrl) {
    return _deletePublicStorageUrl(avatarUrl);
  }

  Future<void> _deletePublicStorageUrl(String url) async {
    if (url.isEmpty || !AppEnv.hasSupabaseStorageConfig) return;

    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        return;
      }

      final publicIndex = uri.pathSegments.indexOf('public');
      if (publicIndex == -1 || publicIndex + 2 > uri.pathSegments.length) {
        return;
      }

      final bucket = uri.pathSegments[publicIndex + 1];
      final objectPath = uri.pathSegments
          .sublist(publicIndex + 2)
          .map(Uri.decodeComponent)
          .join('/');
      if (bucket.isEmpty || objectPath.isEmpty) {
        return;
      }

      final client = _resolveSupabaseClient();
      if (client == null) {
        return;
      }

      await client.storage.from(bucket).remove([objectPath]);
    } catch (_) {}
  }

  SupabaseClient? _resolveSupabaseClient() {
    if (_supabase != null) {
      return _supabase;
    }
    if (!AppEnv.hasSupabaseStorageConfig) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
