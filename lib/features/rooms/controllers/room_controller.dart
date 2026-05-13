import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_env.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/room_model.dart';
import '../../../services/firestore_service.dart';

final roomListProvider = StreamProvider<List<RoomModel>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) {
    return const Stream<List<RoomModel>>.empty();
  }
  return ref.watch(firestoreServiceProvider).watchRooms();
});

final roomByIdProvider =
    StreamProvider.autoDispose.family<RoomModel?, String>((ref, roomId) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) {
    return const Stream<RoomModel?>.empty();
  }
  return ref.watch(firestoreServiceProvider).watchRoom(roomId);
});

final roomControllerProvider =
    StateNotifierProvider<RoomController, AsyncValue<void>>((ref) {
  return RoomController(ref);
});

class RoomController extends StateNotifier<AsyncValue<void>> {
  RoomController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<bool> createRoom({
    required String name,
    required String description,
    required bool isPrivate,
    String accessCode = '',
    String avatarUrl = '',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(firestoreServiceProvider).createRoom(
            name: name,
            description: description,
            isPrivate: isPrivate,
            accessCode: accessCode,
            avatarUrl: avatarUrl,
          );
    });
    return !state.hasError;
  }

  Future<bool> updateRoom({
    required RoomModel room,
    required String name,
    required String description,
    required bool isPrivate,
    String accessCode = '',
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(firestoreServiceProvider).updateRoom(
            room: room,
            name: name,
            description: description,
            isPrivate: isPrivate,
            accessCode: accessCode,
            avatarUrl: avatarUrl,
          );
    });
    return !state.hasError;
  }

  Future<bool> deleteRoom(RoomModel room) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(firestoreServiceProvider).deleteRoom(room.id);
    });
    return !state.hasError;
  }

  Future<String?> uploadRoomAvatar(String roomId) {
    return ref.read(storageServiceProvider).pickAndUploadImage(
          path: 'rooms/$roomId/avatar',
          bucket: AppEnv.supabaseAvatarBucket,
          source: ImageSource.gallery,
        );
  }

  Future<bool> joinRoom({
    required RoomModel room,
    String accessCode = '',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(firestoreServiceProvider).joinRoom(
            room: room,
            accessCode: accessCode,
          );
      switch (result) {
        case RoomJoinResult.success:
          return;
        case RoomJoinResult.invalidAccessCode:
          throw Exception('Invalid access code');
        case RoomJoinResult.roomUnavailable:
          throw Exception('Room unavailable');
        case RoomJoinResult.unauthenticated:
          throw Exception('Authentication required');
      }
    });
    return !state.hasError;
  }
}
