import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_env.dart';
import '../core/constants/firebase_constants.dart';
import '../core/utils/platform_support.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: kIsWeb && AppEnv.googleWebClientId.isNotEmpty
                  ? AppEnv.googleWebClientId
                  : null,
            );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? preferredUsername,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final username = await _resolveUsername(
      preferredUsername: preferredUsername,
      email: email,
      uid: uid,
    );
    await _createUserDocument(uid: uid, name: name, email: email, username: username);
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
    final doc =
        await _firestore.collection(FirebaseConstants.users).doc(user.uid).get();
    if (!doc.exists) {
      final username = await _resolveUsername(
        email: user.email ?? '',
        uid: user.uid,
      );
      await _createUserDocument(
        uid: user.uid,
        name: user.displayName ?? 'FlashChat User',
        email: user.email ?? '',
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
    if (user == null) return;
    await _firestore.collection(FirebaseConstants.users).doc(user.uid).delete();
    await user.delete();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
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
    final prefix = email
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .substring(0, min(15, email.split('@').first.length));

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
      name: name,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
    );
    final batch = _firestore.batch();
    batch.set(_firestore.collection(FirebaseConstants.users).doc(uid), user.toMap());
    if (username.isNotEmpty) {
      batch.set(
        _firestore.collection(FirebaseConstants.usernames).doc(username),
        {'uid': uid},
      );
    }
    await batch.commit();
  }
}
