import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../controllers/profile_controller.dart';
import '../widgets/avatar_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  Timer? _usernameDebounce;
  bool? _usernameAvailable;
  bool _checkingUsername = false;
  String _initialUsername = '';

  bool _populated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _populate(user) {
    if (_populated) return;
    _populated = true;
    _nameController.text = user.name;
    _usernameController.text = user.username;
    _bioController.text = user.bio;
    _initialUsername = user.username;
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    setState(() {
      _usernameAvailable = null;
      _checkingUsername = false;
    });
    final v = value.trim().toLowerCase();
    if (v == _initialUsername || v.isEmpty || Validators.username(v) != null) return;

    setState(() => _checkingUsername = true);
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final available =
            await ref.read(firestoreServiceProvider).isUsernameAvailable(v);
        if (mounted) {
          setState(() {
            _usernameAvailable = available;
            _checkingUsername = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final state = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        data: (user) {
          if (user == null) return const Center(child: Text('No profile found.'));
          _populate(user);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: AvatarPicker(
                  imageUrl: user.avatarUrl,
                  onTap: () => ref
                      .read(profileControllerProvider.notifier)
                      .updateAvatar(user.uid),
                ),
              ),
              const SizedBox(height: 20),
              // Display name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 16),
              // Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  suffixIcon: _buildUsernameStatus(theme),
                  helperText: 'Lowercase letters, numbers, _ and . only.',
                ),
                onChanged: _onUsernameChanged,
              ),
              if (_usernameAvailable == false) ...[
                const SizedBox(height: 6),
                Text(
                  '@${_usernameController.text.trim()} is already taken.',
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              // Email (read-only)
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Email'),
                child: Text(user.email),
              ),
              const SizedBox(height: 16),
              // Bio
              TextField(
                controller: _bioController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 16),
              Text(
                'Member since ${DateFormatter.memberSince(user.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              if (state.hasError) ...[
                Text(
                  state.error.toString(),
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed:
                    (state.isLoading || _usernameAvailable == false) ? null : () => _save(user),
                child: Text(state.isLoading ? 'Saving…' : 'Save profile'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
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
      return Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20);
    }
    if (_usernameAvailable == false) {
      return Icon(Icons.cancel_outlined, color: theme.colorScheme.error, size: 20);
    }
    return null;
  }

  Future<void> _save(user) async {
    final notifier = ref.read(profileControllerProvider.notifier);
    final newUsername = _usernameController.text.trim().toLowerCase();

    // Update username if changed
    if (newUsername != _initialUsername) {
      final ok = await notifier.updateUsername(
        uid: user.uid,
        newUsername: newUsername,
        oldUsername: _initialUsername,
      );
      if (!ok) return;
      _initialUsername = newUsername;
    }

    // Update name + bio
    await notifier.updateProfile(
      uid: user.uid,
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );
  }
}
