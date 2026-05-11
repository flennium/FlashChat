class InputSanitizer {
  const InputSanitizer._();

  static String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  static String normalizeUsername(String value) {
    return _stripControlCharacters(value).trim().toLowerCase();
  }

  static String normalizeDisplayName(String value) {
    return _collapseWhitespace(_stripControlCharacters(value)).trim();
  }

  static String normalizeBio(String value) {
    return _stripControlCharacters(value)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
  }

  static String normalizeRoomName(String value) {
    return _collapseWhitespace(_stripControlCharacters(value)).trim();
  }

  static String normalizeRoomDescription(String value) {
    return _collapseWhitespace(_stripControlCharacters(value)).trim();
  }

  static String normalizeAccessCode(String value) {
    return _stripControlCharacters(value).trim();
  }

  static String _collapseWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _stripControlCharacters(String value) {
    return value.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }
}
