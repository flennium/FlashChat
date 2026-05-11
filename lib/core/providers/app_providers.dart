import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../services/firestore_service.dart';
import '../../services/presence_service.dart';
import '../../services/remote_config_service.dart';
import '../../services/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
final presenceServiceProvider =
    Provider<PresenceService>((ref) => PresenceService());
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());
final remoteConfigServiceProvider =
    Provider<RemoteConfigService>((ref) => RemoteConfigService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream<UserModel?>.empty();
  return ref.watch(firestoreServiceProvider).watchUserProfile(authUser.uid);
});

final userProfileByIdProvider =
    StreamProvider.autoDispose.family<UserModel?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchUserProfile(uid);
});

final userOnlineStatusProvider =
    StreamProvider.autoDispose.family<bool, String>((ref, uid) {
  return ref.watch(presenceServiceProvider).watchUserOnlineStatus(uid);
});

final onlineCountProvider = StreamProvider<int>((ref) {
  return ref.watch(presenceServiceProvider).watchOnlineCount();
});

final roomAdminEmailProvider = StreamProvider<String>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream<String>.value('');
  return ref.watch(firestoreServiceProvider).watchRoomAdminEmail();
});

final roomUnreadCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, roomId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchCurrentUserUnreadCount(roomId);
});

final announcementProvider = FutureProvider<String>((ref) async {
  return ref.watch(remoteConfigServiceProvider).fetchPinnedMessage();
});

/// How many messages to load for a given room (grows as the user pages up).
final messagePageLimitProvider =
    StateProvider.autoDispose.family<int, String>((ref, roomId) => 50);

/// The message currently being replied to, keyed by room ID.
final replyMessageProvider = StateProvider.autoDispose
    .family<MessageModel?, String>((ref, roomId) => null);

/// The room ID the user is currently viewing — null when not in any room.
/// Used to suppress foreground push-notification banners for the active room.
final activeRoomIdProvider = StateProvider<String?>((ref) => null);

/// Username prefix suggestions for @mention autocomplete.
final mentionSuggestionsProvider =
    FutureProvider.autoDispose.family<List<UserModel>, String>((ref, query) {
  return ref.read(firestoreServiceProvider).searchUsersByUsername(query);
});
