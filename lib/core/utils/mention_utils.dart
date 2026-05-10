class MentionRange {
  const MentionRange({
    required this.start,
    required this.end,
    required this.username,
  });

  final int start;
  final int end;
  final String username;
}

class ActiveMentionQuery {
  const ActiveMentionQuery({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;
}

class MentionUtils {
  const MentionUtils._();

  static final RegExp _mentionChar = RegExp(r'[A-Za-z0-9_.]');
  static final RegExp _unsafePrefixChar = RegExp(r'[A-Za-z0-9._%+\-/:=#?&]');

  static List<MentionRange> findMentions(String text) {
    final mentions = <MentionRange>[];

    for (int i = 0; i < text.length; i++) {
      if (text[i] != '@' || !_isSafeMentionStart(text, i)) continue;

      var end = i + 1;
      while (end < text.length && _mentionChar.hasMatch(text[end])) {
        end++;
      }

      while (end > i + 1 && text[end - 1] == '.') {
        end--;
      }

      if (end == i + 1) continue;

      mentions.add(
        MentionRange(
          start: i,
          end: end,
          username: text.substring(i + 1, end),
        ),
      );

      i = end - 1;
    }

    return mentions;
  }

  static ActiveMentionQuery? activeQueryAt(String text, int cursorOffset) {
    if (cursorOffset < 0 || cursorOffset > text.length) return null;

    var start = cursorOffset - 1;
    while (start >= 0) {
      final char = text[start];
      if (char == '@') break;
      if (!_mentionChar.hasMatch(char)) return null;
      start--;
    }

    if (start < 0 || text[start] != '@' || !_isSafeMentionStart(text, start)) {
      return null;
    }

    final query = text.substring(start + 1, cursorOffset);
    if (query.contains(RegExp(r'[^A-Za-z0-9_.]'))) return null;

    return ActiveMentionQuery(
      start: start,
      end: cursorOffset,
      query: query,
    );
  }

  static bool _isSafeMentionStart(String text, int atIndex) {
    if (atIndex <= 0) return true;
    return !_unsafePrefixChar.hasMatch(text[atIndex - 1]);
  }
}
