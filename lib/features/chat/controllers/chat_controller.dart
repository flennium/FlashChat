import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_env.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/mention_utils.dart';
import '../../../models/message_model.dart';
import '../../../models/room_model.dart';
import '../../../models/user_model.dart';

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
    final messageText = text.trim();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(firestoreServiceProvider).sendMessage(
            roomId: room.id,
            sender: user,
            text: messageText,
            replyTo: replyTo,
          );
      await _sendNotificationsForMessage(
        room: room,
        sender: user,
        text: messageText,
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
      await _sendNotificationsForMessage(
        room: room,
        sender: user,
        text: 'Sent a photo',
      );
    });
    return !state.hasError;
  }

  Future<void> _sendNotificationsForMessage({
    required RoomModel room,
    required UserModel sender,
    required String text,
  }) async {
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final fcm = ref.read(fcmServiceProvider);
      final senderName = sender.displayName;
      final body = text.isEmpty ? 'New message' : text;
      final mentions = MentionUtils.findMentions(text)
          .map((mention) => mention.username)
          .toSet();

      final mentionTargets = await firestore.getMentionNotificationTargets(
        roomId: room.id,
        usernames: mentions,
        excludeUid: sender.uid,
      );
      if (mentionTargets.tokens.isNotEmpty) {
        await fcm.sendNotification(
          tokens: mentionTargets.tokens,
          title: '$senderName mentioned you in ${room.name}',
          body: body,
          data: {'roomId': room.id, 'type': 'mention'},
          notificationTag: 'room_${room.id}_mention_${sender.uid}',
          iosThreadId: room.id,
          collapseId: 'room_${room.id}_mention_${sender.uid}',
        );
      }

      final roomTokens = await firestore.getRoomMemberFcmTokens(
        roomId: room.id,
        excludeUid: sender.uid,
        excludeUids: mentionTargets.uids.toSet(),
      );
      if (roomTokens.isNotEmpty) {
        await fcm.sendNotification(
          tokens: roomTokens,
          title: '${room.name} - $senderName',
          body: body,
          data: {'roomId': room.id, 'type': 'room-message'},
          notificationTag: 'room_${room.id}',
          iosThreadId: room.id,
          collapseId: 'room_${room.id}',
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Could not queue notification: $error\n$stackTrace');
      }
    }
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
