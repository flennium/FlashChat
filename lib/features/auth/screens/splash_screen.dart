import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../shell/screens/home_shell.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _handleAuthState(ref.read(authStateProvider)));
    _authSubscription = ref.listenManual<AsyncValue<User?>>(
      authStateProvider,
      (_, next) {
        _handleAuthState(next);
      },
    );
  }

  Future<void> _handleAuthState(AsyncValue<User?> state) async {
    final user = state.valueOrNull;
    if (state.isLoading || _hasNavigated) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;
    final route = MaterialPageRoute<void>(
      builder: (_) => user == null ? const LoginScreen() : const HomeShell(),
    );
    Navigator.of(context).pushAndRemoveUntil(route, (route) => false);
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(
                image: AssetImage('assets/branding/flashchat_mark.png'),
                width: 112,
                height: 112,
              ),
              SizedBox(height: 20),
              Image(
                image: AssetImage('assets/branding/flashchat_wordmark.png'),
                width: 220,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
