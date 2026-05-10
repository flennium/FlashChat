import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/constants/firebase_constants.dart';

class PresenceService {
  PresenceService({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  Future<void> setOnline({String username = ''}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final ref = _database.ref('${FirebaseConstants.userPresence}/${user.uid}');
      await ref.set({'online': true, 'typingRoomId': '', 'username': username});
      await ref.onDisconnect().set({'online': false, 'typingRoomId': '', 'username': username});
    } catch (_) {}
  }

  Future<void> updatePresenceUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _database
          .ref('${FirebaseConstants.userPresence}/${user.uid}')
          .update({'username': username});
    } catch (_) {}
  }

  Future<void> setTyping(String roomId, bool isTyping) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _database.ref('${FirebaseConstants.userPresence}/${user.uid}').update({
        'typingRoomId': isTyping ? roomId : '',
        'online': true,
      });
    } catch (_) {}
  }

  Stream<int> watchOnlineCount() {
    try {
      return _database.ref(FirebaseConstants.userPresence).onValue.map((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) return 0;
        return raw.values.where((v) => v is Map && v['online'] == true).length;
      });
    } catch (_) {
      return Stream<int>.value(0);
    }
  }

  /// Returns display names (e.g. "@alice" or "Bob") of users currently typing
  /// in [roomId], excluding the signed-in user.
  Stream<List<String>> watchTypingUsers(String roomId) {
    try {
      final currentUid = _auth.currentUser?.uid;
      return _database.ref(FirebaseConstants.userPresence).onValue.map((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) return <String>[];
        return raw.entries
            .where((e) =>
                e.key != currentUid &&
                e.value is Map &&
                e.value['typingRoomId'] == roomId)
            .map((e) {
              final username = (e.value['username'] as String?) ?? '';
              return username.isNotEmpty ? '@$username' : 'Someone';
            })
            .toList();
      });
    } catch (_) {
      return Stream<List<String>>.value(const []);
    }
  }

  /// Real-time online status for a specific user (via RTDB presence node).
  Stream<bool> watchUserOnlineStatus(String uid) {
    try {
      return _database
          .ref('${FirebaseConstants.userPresence}/$uid/online')
          .onValue
          .map((event) => event.snapshot.value == true);
    } catch (_) {
      return Stream<bool>.value(false);
    }
  }
}
