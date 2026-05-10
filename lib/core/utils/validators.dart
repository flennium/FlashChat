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
    final matches = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return matches ? null : 'Enter a valid email address';
  }

  static String? password(String? value) {
    final required = requiredField(value, label: 'Password');
    if (required != null) return required;
    return value!.trim().length >= 6 ? null : 'Password must be at least 6 characters';
  }

  // Lowercase letters, digits, underscores, dots — no spaces, min 4 chars.
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    final v = value.trim();
    if (v.length < 4) return 'Username must be at least 4 characters';
    if (v.length > 30) return 'Username must be 30 characters or fewer';
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(v)) {
      return 'Only lowercase letters, numbers, _ and . are allowed';
    }
    if (v.startsWith('.') || v.endsWith('.')) {
      return 'Username cannot start or end with a dot';
    }
    return null;
  }

  static String? usernameOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return username(value);
  }
}
