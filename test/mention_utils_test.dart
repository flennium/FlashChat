import 'package:flashchat/core/utils/mention_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MentionUtils.findMentions', () {
    test('finds standalone mentions', () {
      final mentions = MentionUtils.findMentions('Hi @alice and @bob_2.');

      expect(mentions.length, 2);
      expect(mentions[0].username, 'alice');
      expect(mentions[1].username, 'bob_2');
    });

    test('ignores at-signs inside emails and uris', () {
      final mentions = MentionUtils.findMentions(
        'mail me at hi@test.com and visit https://site.com/@alice before pinging @bob',
      );

      expect(mentions.length, 1);
      expect(mentions.single.username, 'bob');
    });
  });

  group('MentionUtils.activeQueryAt', () {
    test('returns active query at cursor', () {
      final query = MentionUtils.activeQueryAt('hello @ali there', 10);

      expect(query, isNotNull);
      expect(query!.query, 'ali');
      expect(query.start, 6);
      expect(query.end, 10);
    });

    test('returns null for email-style at-sign', () {
      final query = MentionUtils.activeQueryAt('hello test@ali', 14);

      expect(query, isNull);
    });
  });
}
