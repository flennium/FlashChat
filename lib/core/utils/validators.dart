import 'input_sanitizer.dart';

class Validators {
  const Validators._();

  static String? requiredField(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, label: 'Email');
    if (required != null) return required;
    final normalized = InputSanitizer.normalizeEmail(value!);
    if (normalized.length > 254) {
      return 'Email is too long';
    }
    final matches = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
    return matches ? null : 'Enter a valid email address';
  }

  static String? password(String? value) {
    final required = requiredField(value, label: 'Password');
    if (required != null) return required;
    return value!.trim().length >= 6
        ? null
        : 'Password must be at least 6 characters';
  }

  static String? displayName(String? value) {
    final required = requiredField(value, label: 'Display name');
    if (required != null) return required;
    final normalized = InputSanitizer.normalizeDisplayName(value!);
    if (normalized.isEmpty) {
      return 'Display name must be at least 1 characters';
    }
    if (normalized.length > 40) {
      return 'Display name must be 40 characters or fewer';
    }
    return null;
  }

  static String? bio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final normalized = InputSanitizer.normalizeBio(value);
    if (normalized.length > 160) {
      return 'Bio must be 160 characters or fewer';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    final normalized = InputSanitizer.normalizeUsername(value);
    if (normalized.length < 4) return 'Username must be at least 4 characters';
    if (normalized.length > 15) {
      return 'Username must be 15 characters or fewer';
    }
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(normalized)) {
      return 'Only lowercase letters, numbers, _ and . are allowed';
    }
    return null;
  }

  static String? usernameOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return username(value);
  }

  static String? roomName(String? value) {
    final required = requiredField(value, label: 'Room name');
    if (required != null) return required;
    final normalized = InputSanitizer.normalizeRoomName(value!);
    if (normalized.length < 3) {
      return 'Room name must be at least 3 characters';
    }
    if (normalized.length > 15) {
      return 'Room name must be 15 characters or fewer';
    }
    return null;
  }

  static String? roomDescription(String? value) {
    final required = requiredField(value, label: 'Description');
    if (required != null) return required;
    final normalized = InputSanitizer.normalizeRoomDescription(value!);
    if (normalized.length > 15) {
      return 'Description must be 15 characters or fewer';
    }
    return null;
  }

  static String? accessCodeRequired(String? value) {
    final required = requiredField(value, label: 'Access code');
    if (required != null) return required;
    final normalized = InputSanitizer.normalizeAccessCode(value!);
    if (normalized.length < 4) {
      return 'Access code must be at least 4 characters';
    }
    if (normalized.length > 20) {
      return 'Access code must be 20 characters or fewer';
    }
    return null;
  }
}
