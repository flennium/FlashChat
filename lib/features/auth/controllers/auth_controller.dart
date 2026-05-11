import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(authServiceProvider).signInWithEmail(
            email: email,
            password: password,
          );
    });
    return !state.hasError;
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? preferredUsername,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(authServiceProvider).registerWithEmail(
            name: name,
            email: email,
            password: password,
            preferredUsername: preferredUsername,
          );
    });
    return !state.hasError;
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(authServiceProvider).signInWithGoogle());
    return !state.hasError;
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
  }

  Future<bool> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(authServiceProvider).deleteAccount());
    return !state.hasError;
  }
}
