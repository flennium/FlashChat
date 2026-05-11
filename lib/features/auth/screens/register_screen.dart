import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/platform_support.dart';
import '../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/google_sign_in_button.dart';
import '../../shell/screens/home_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Timer? _usernameDebounce;
  bool? _usernameAvailable; // null=unchecked, true=available, false=taken
  bool _checkingUsername = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    setState(() {
      _usernameAvailable = null;
      _checkingUsername = false;
    });

    final v = value.trim().toLowerCase();
    if (v.isEmpty || Validators.username(v) != null) return;

    setState(() => _checkingUsername = true);
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final available =
          await ref.read(firestoreServiceProvider).isUsernameAvailable(v);
      if (mounted) {
        setState(() {
          _usernameAvailable = available;
          _checkingUsername = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (v) =>
                      Validators.requiredField(v, label: 'Display name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'e.g. abdou_05',
                    prefixText: '@',
                    helperText:
                        'Leave blank to auto-generate. Lowercase, letters, numbers, _ and . only.',
                    helperMaxLines: 2,
                    suffixIcon: _buildUsernameStatus(theme),
                  ),
                  onChanged: _onUsernameChanged,
                  validator: Validators.usernameOptional,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: Validators.password,
                ),
              ],
            ),
          ),
          if (authState.hasError) ...[
            const SizedBox(height: 12),
            Text(
              authState.error.toString(),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (_usernameAvailable == false) ...[
            const SizedBox(height: 8),
            Text(
              '@${_usernameController.text.trim()} is already taken.',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed:
                isLoading || _usernameAvailable == false ? null : _submit,
            child: Text(isLoading ? 'Creating account…' : 'Register'),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: theme.textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          if (PlatformSupport.supportsGoogleSignIn)
            GoogleSignInButton(
              loading: isLoading,
              onPressed: () async {
                final navigator = Navigator.of(context);
                final ok = await ref
                    .read(authControllerProvider.notifier)
                    .signInWithGoogle();
                if (!mounted || !ok) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const HomeShell()),
                  (route) => false,
                );
              },
            ),
          if (!PlatformSupport.supportsGoogleSignIn) ...[
            const SizedBox(height: 4),
            Text(
              'Google Sign-In is available on the mobile and web versions of FlashChat.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildUsernameStatus(ThemeData theme) {
    if (_checkingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_usernameAvailable == true) {
      return Icon(Icons.check_circle_outline,
          color: Colors.green.shade600, size: 20);
    }
    if (_usernameAvailable == false) {
      return Icon(Icons.cancel_outlined,
          color: theme.colorScheme.error, size: 20);
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final preferred = _usernameController.text.trim().toLowerCase();
    final ok =
        await ref.read(authControllerProvider.notifier).registerWithEmail(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              preferredUsername: preferred.isEmpty ? null : preferred,
            );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeShell()),
        (route) => false,
      );
    }
  }
}
