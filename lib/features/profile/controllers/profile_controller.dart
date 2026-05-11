import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_env.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/input_sanitizer.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(ref);
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<bool> updateProfile({
    required String uid,
    required String name,
    required String bio,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(firestoreServiceProvider).updateProfile(
            uid: uid,
            name: name,
            bio: bio,
          );
    });
    return !state.hasError;
  }

  /// Claims a new username, releasing the old one atomically.
  /// Returns false and sets an error state if the new username is taken.
  Future<bool> updateUsername({
    required String uid,
    required String newUsername,
    required String oldUsername,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final lc = InputSanitizer.normalizeUsername(newUsername);
      final previous = InputSanitizer.normalizeUsername(oldUsername);
      if (lc != previous) {
        final available =
            await ref.read(firestoreServiceProvider).isUsernameAvailable(lc);
        if (!available) throw Exception('@$lc is already taken');
      }
      await ref.read(firestoreServiceProvider).claimUsername(
            uid: uid,
            username: lc,
            oldUsername: previous.isEmpty ? null : previous,
          );
      // Also push the updated username into the RTDB presence node so typing
      // indicators reflect the change immediately.
      await ref.read(presenceServiceProvider).updatePresenceUsername(lc);
    });
    return !state.hasError;
  }

  Future<bool> updateAvatar(String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final imageUrl =
          await ref.read(storageServiceProvider).pickAndUploadImage(
                path: uid,
                bucket: AppEnv.supabaseAvatarBucket,
                source: ImageSource.gallery,
              );
      if (imageUrl != null) {
        await ref
            .read(firestoreServiceProvider)
            .updateProfile(uid: uid, avatarUrl: imageUrl);
      }
    });
    return !state.hasError;
  }
}
