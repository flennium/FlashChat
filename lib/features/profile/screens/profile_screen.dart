import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
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

  void _populate(UserModel user) {
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
    if (v == _initialUsername || v.isEmpty || Validators.username(v) != null) {
      return;
    }

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
          if (user == null) {
            return const Center(child: Text('No profile found.'));
          }
          _populate(user);

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _ProfileHero(
                user: user,
                onAvatarTap: () => ref
                    .read(profileControllerProvider.notifier)
                    .updateAvatar(user.uid),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ProfileStatChip(
                      icon: Icons.calendar_today_rounded,
                      label: 'Member since',
                      value: DateFormatter.memberSince(user.createdAt),
                    ),
                    _ProfileStatChip(
                      icon: Icons.badge_outlined,
                      label: 'Handle',
                      value: user.username.isEmpty
                          ? 'Not set'
                          : '@${user.username}',
                    ),
                  ],
                ),
              ),
              _ProfileSection(
                title: 'Identity',
                subtitle: 'Keep the basics clear and recognizable.',
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'Display name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      autocorrect: false,
                      enableSuggestions: false,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '@${_usernameController.text.trim()} is already taken.',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Email'),
                      child: Text(user.email),
                    ),
                  ],
                ),
              ),
              _ProfileSection(
                title: 'Bio',
                subtitle: 'Give people a quick sense of who you are.',
                child: TextField(
                  controller: _bioController,
                  minLines: 4,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'About you',
                    hintText: 'Share a short intro, interests, or vibe.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.hasError) ...[
                      Text(
                        state.error.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    FilledButton(
                      onPressed:
                          (state.isLoading || _usernameAvailable == false)
                              ? null
                              : () => _save(user),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          Text(state.isLoading ? 'Saving...' : 'Save profile'),
                    ),
                  ],
                ),
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
      return Icon(
        Icons.check_circle_outline,
        color: Colors.green.shade600,
        size: 20,
      );
    }
    if (_usernameAvailable == false) {
      return Icon(
        Icons.cancel_outlined,
        color: theme.colorScheme.error,
        size: 20,
      );
    }
    return null;
  }

  Future<void> _save(UserModel user) async {
    final notifier = ref.read(profileControllerProvider.notifier);
    final normalizedName =
        InputSanitizer.normalizeDisplayName(_nameController.text);
    final normalizedBio = InputSanitizer.normalizeBio(_bioController.text);
    final newUsername =
        InputSanitizer.normalizeUsername(_usernameController.text);

    final nameError = Validators.displayName(normalizedName);
    if (nameError != null) {
      _showError(nameError);
      return;
    }
    final usernameError = Validators.usernameOptional(newUsername);
    if (usernameError != null) {
      _showError(usernameError);
      return;
    }
    final bioError = Validators.bio(normalizedBio);
    if (bioError != null) {
      _showError(bioError);
      return;
    }

    if (newUsername != _initialUsername) {
      final ok = await notifier.updateUsername(
        uid: user.uid,
        newUsername: newUsername,
        oldUsername: _initialUsername,
      );
      if (!ok) return;
      _initialUsername = newUsername;
    }

    await notifier.updateProfile(
      uid: user.uid,
      name: normalizedName,
      bio: normalizedBio,
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.onAvatarTap,
  });

  final UserModel user;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.95),
            theme.colorScheme.tertiary.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your profile',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.username.isEmpty ? user.email : '@${user.username}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          AvatarPicker(
            imageUrl: user.avatarUrl,
            onTap: onAvatarTap,
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileStatChip extends StatelessWidget {
  const _ProfileStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
