import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_env.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/mention_utils.dart';
import '../../../models/message_model.dart';
import '../../../models/room_model.dart';
import '../../../models/user_model.dart';

final roomMessagesProvider =
    StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, roomId) {
  final limit = ref.watch(messagePageLimitProvider(roomId));
  return ref.watch(firestoreServiceProvider).watchMessages(roomId, limit: limit);
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
    final user = ref.read(currentUserProfileProvider).value;
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
    if (!state.hasError) {
      _pushNotification(room, user, text.trim());
    }
    return !state.hasError;
  }

  Future<bool> sendImage(RoomModel room) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final imageUrl = await ref.read(storageServiceProvider).pickAndUploadImage(
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
    if (!state.hasError) {
      _pushNotification(room, user, 'Photo');
    }
    return !state.hasError;
  }

  // Fire-and-forget: fetch member tokens then call the Edge Function.
  // Never awaited so it never delays the send response in the UI.
  void _pushNotification(RoomModel room, UserModel sender, String text) {
    Future(() async {
      try {
        final mentionedUsernames = MentionUtils.findMentions(text)
            .map((mention) => mention.username)
            .toSet();
        final mentionTargets = await ref
            .read(firestoreServiceProvider)
            .getMentionNotificationTargets(
              roomId: room.id,
              usernames: mentionedUsernames,
              excludeUid: sender.uid,
            );

        final tokens = await ref
            .read(firestoreServiceProvider)
            .getRoomMemberFcmTokens(
              roomId: room.id,
              excludeUid: sender.uid,
              excludeUids: mentionTargets.uids.toSet(),
            );

        final senderLabel =
            sender.name.isNotEmpty ? sender.name : '@${sender.username}';
        final senderKey =
            sender.username.isNotEmpty ? sender.username : sender.uid;
        final notificationKey = 'room_${room.id}_sender_$senderKey';

        if (tokens.isNotEmpty) {
          await ref.read(fcmServiceProvider).sendNotification(
                tokens: tokens,
                title: '${room.name} - $senderLabel',
                body: text.isEmpty ? 'Photo' : text,
                data: {
                  'roomId': room.id,
                  'type': 'message',
                  'senderId': sender.uid,
                  'senderUsername': sender.username,
                },
                notificationTag: notificationKey,
                iosThreadId: notificationKey,
                collapseId: notificationKey,
              );
        }

        if (mentionTargets.tokens.isNotEmpty && text.isNotEmpty) {
          final mentionKey = 'room_${room.id}_mention_$senderKey';
          await ref.read(fcmServiceProvider).sendNotification(
                tokens: mentionTargets.tokens,
                title: '$senderLabel mentioned you',
                body: text,
                data: {
                  'roomId': room.id,
                  'type': 'mention',
                  'senderId': sender.uid,
                  'senderUsername': sender.username,
                },
                notificationTag: mentionKey,
                iosThreadId: mentionKey,
                collapseId: mentionKey,
              );
        }
      } catch (_) {
        // Non-critical notification failures must never surface to the user.
      }
    });
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
    final uid = ref.read(currentUserProfileProvider).value?.uid ?? '';
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
    final uid = ref.read(currentUserProfileProvider).value?.uid ?? '';
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
    final uid = ref.read(currentUserProfileProvider).value?.uid;
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).markRoomRead(room.id, messages, uid);
  }

  /// Increases the page limit by 30 to load older messages.
  void loadMoreMessages(RoomModel room) {
    final current = ref.read(messagePageLimitProvider(room.id));
    ref.read(messagePageLimitProvider(room.id).notifier).state = current + 30;
  }
}
