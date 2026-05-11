import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  const AuthErrorMapper._();

  static String message(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'wrong-password':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Choose a stronger password with at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled right now.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'popup-closed-by-user':
        case 'aborted':
          return 'Sign-in was cancelled.';
        case 'requires-recent-login':
          return 'Please sign in again before performing this action.';
        case 'missing-google-web-client-id':
          return 'Google Sign-In is not configured for web yet.';
        default:
          final fallback = error.message?.trim();
          if (fallback != null && fallback.isNotEmpty) {
            return fallback;
          }
      }
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return raw;
  }
}
