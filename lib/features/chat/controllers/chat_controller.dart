import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_env.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/message_model.dart';
import '../../../models/room_model.dart';

final roomMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, roomId) {
  final limit = ref.watch(messagePageLimitProvider(roomId));
  return ref
      .watch(firestoreServiceProvider)
      .watchMessages(roomId, limit: limit);
});

final typingUsersProvider =
    StreamProvider.autoDispose.family<List<String>, String>((ref, roomId) {
  return ref.watch(presenceServiceProvider).watchTypingUsers(roomId);
});

final chatControllerProvider =
    StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref);
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  ChatController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> setTyping(RoomModel room, bool typing) {
    return ref.read(presenceServiceProvider).setTyping(room.id, typing);
  }

  Future<bool> sendText(
    RoomModel room,
    String text, {
    Map<String, dynamic>? replyTo,
  }) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(firestoreServiceProvider).sendMessage(
            roomId: room.id,
            sender: user,
            text: text.trim(),
            replyTo: replyTo,
          );
    });
    return !state.hasError;
  }

  Future<bool> sendImage(RoomModel room) async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final imageUrl =
          await ref.read(storageServiceProvider).pickAndUploadImage(
                path: 'rooms/${room.id}/images',
                bucket: AppEnv.supabaseChatImageBucket,
                source: ImageSource.gallery,
              );
      if (imageUrl == null) return;
      await ref.read(firestoreServiceProvider).sendMessage(
            roomId: room.id,
            sender: user,
            imageUrl: imageUrl,
          );
    });
    return !state.hasError;
  }

  Future<void> editMessage({
    required RoomModel room,
    required String messageId,
    required String newText,
  }) {
    return ref.read(firestoreServiceProvider).editMessage(
          roomId: room.id,
          messageId: messageId,
          newText: newText,
        );
  }

  Future<void> deleteForEveryone({
    required RoomModel room,
    required String messageId,
  }) {
    return ref.read(firestoreServiceProvider).deleteMessageForEveryone(
          roomId: room.id,
          messageId: messageId,
        );
  }

  Future<void> deleteForMe({
    required RoomModel room,
    required MessageModel message,
  }) {
    final uid = ref.read(currentUserProfileProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return Future.value();
    return ref.read(firestoreServiceProvider).deleteMessageForMe(
          roomId: room.id,
          messageId: message.id,
          uid: uid,
        );
  }

  Future<void> toggleReaction({
    required RoomModel room,
    required MessageModel message,
    required String emoji,
  }) {
    final uid = ref.read(currentUserProfileProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return Future.value();
    return ref.read(firestoreServiceProvider).toggleReaction(
          roomId: room.id,
          messageId: message.id,
          emoji: emoji,
          uid: uid,
          currentUsers: message.reactions[emoji] ?? [],
        );
  }

  Future<void> markRead(RoomModel room, List<MessageModel> messages) async {
    final uid = ref.read(currentUserProfileProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref
        .read(firestoreServiceProvider)
        .markRoomRead(room.id, messages, uid);
  }

  /// Increases the page limit by 30 to load older messages.
  void loadMoreMessages(RoomModel room) {
    final current = ref.read(messagePageLimitProvider(room.id));
    ref.read(messagePageLimitProvider(room.id).notifier).state = current + 30;
  }
}
