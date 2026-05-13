import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme_variant.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/theme/theme_variant_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/login_screen.dart';

const _footerMessages = [
  'Compiled successfully... somehow.',
  'Running on Firebase and hope.',
  '99 little bugs in the code.',
  'The server is trying its best.',
  'Debugging since yesterday.',
  'Some features may be powered by luck.',
  'No keyboards were harmed... probably.',
  'Made with Flutter and sleep deprivation.',
  'AI generated? Maybe.',
  'Works on my machine.',
  'If this crashes, blame the compiler.',
  'Please ignore the spaghetti code.',
  'Trust the process.',
  'Feature or bug? Nobody knows.',
  'This footer changes more than my life plans.',
  'Made for a exam project and somehow still alive.',
];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _footerIndex = 0;
  Timer? _footerTimer;
  String _appVersionLabel = 'Version';
  String _appVersionName = '';
  String _appBuildNumber = '';
  String _appPackageName = '';

  @override
  void initState() {
    super.initState();
    _footerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(
            () => _footerIndex = (_footerIndex + 1) % _footerMessages.length);
      }
    });
    _loadAppVersion();
  }

  @override
  void dispose() {
    _footerTimer?.cancel();
    super.dispose();
  }

  void _showPasswordSheet(BuildContext context, String email) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _PasswordSheet(email: email),
    );
  }

  Future<void> _showDeleteAccountSheet({
    required BuildContext context,
    required String email,
    required String username,
  }) async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _DeleteAccountSheet(
        email: email,
        username: username,
      ),
    );

    if (deleted == true && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showBuildStudio() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _BuildStudioSheet(
        versionLabel: _appVersionLabel,
        versionName: _appVersionName,
        buildNumber: _appBuildNumber,
        packageName: _appPackageName,
      ),
    );
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionName = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();
      final versionSuffix = buildNumber.isEmpty ? '' : '+$buildNumber';
      final versionLabel = 'v$versionName$versionSuffix';

      if (mounted) {
        setState(() {
          _appVersionLabel = versionLabel;
          _appVersionName = versionName;
          _appBuildNumber = buildNumber;
          _appPackageName = packageInfo.packageName.trim();
        });
      }
    } catch (_) {
      // Keep the UI usable even if package metadata is unavailable.
      if (mounted) {
        setState(() {
          _appVersionLabel = 'Version unavailable';
          _appVersionName = '';
          _appBuildNumber = '';
          _appPackageName = '';
        });
      }
    }
  }

  String _platformLabel() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final activeVariant = ref.watch(themeVariantControllerProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;
    final mutedTitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.78);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Appearance ─────────────────────────────────────────────────────
          Text(
            'Appearance',
            style: theme.textTheme.titleLarge?.copyWith(color: titleColor),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeModeControllerProvider.notifier).setMode(s.first),
          ),
          const SizedBox(height: 20),
          Text(
            'Color theme',
            style: theme.textTheme.titleMedium?.copyWith(color: titleColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ThemeCatalog.all.map((entry) {
              final isActive = entry.variant == activeVariant;
              final isDark = theme.brightness == Brightness.dark;
              final swatch = isDark ? entry.darkPrimary : entry.lightPrimary;
              return GestureDetector(
                onTap: () => ref
                    .read(themeVariantControllerProvider.notifier)
                    .setVariant(entry.variant),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? swatch.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? swatch : Colors.transparent,
                      width: 1.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                            color: swatch, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isActive ? swatch : null,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_rounded, size: 14, color: swatch),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Account ────────────────────────────────────────────────────────
          Text(
            'Account',
            style: theme.textTheme.titleLarge?.copyWith(color: titleColor),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Email'),
            subtitle: Text(profile?.email ?? 'Not signed in'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Password'),
            subtitle: const Text('Change or reset your password'),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: profile == null
                ? null
                : () => _showPasswordSheet(context, profile.email),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sign out'),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Delete account'),
            subtitle: const Text('Permanently remove your profile and data'),
            textColor: theme.colorScheme.error,
            onTap: profile == null
                ? null
                : () => _showDeleteAccountSheet(
                      context: context,
                      email: profile.email,
                      username: profile.username,
                    ),
          ),

          const SizedBox(height: 28),

          // ── App ────────────────────────────────────────────────────────────
          Text(
            'App',
            style: theme.textTheme.titleLarge?.copyWith(color: titleColor),
          ),
          const SizedBox(height: 16),

          // Version card — opens a cleaner build detail sheet
          _AppCard(
            child: InkWell(
              onTap: _showBuildStudio,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.24),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build studio',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'FlashChat',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Badge(
                              label: _appVersionLabel,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            _Badge(
                              label: _platformLabel(),
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to open release notes, build metadata, and platform details.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.66),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.north_east_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),

          const SizedBox(height: 10),

          // Maintainer card
          _AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAINTAINED BY',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedTitleColor,
                        fontSize: 10,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mokhtari Abderrahmane',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // About card
          _AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'About',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'FlashChat is a real-time chat application built with Flutter and Firebase, focused on room-based messaging, profiles, and interactive communication features.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The app combines modern chat features inspired by Instagram, Discord, and Messenger — with reactions, profiles, replies, typing indicators, and live interactions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Technology card
          _AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TECH STACK',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedTitleColor,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PoweredBadge(label: 'Flutter', emoji: '💙', theme: theme),
                    _PoweredBadge(label: 'Firebase', emoji: '🔥', theme: theme),
                    _PoweredBadge(label: 'Supabase', emoji: '⚡', theme: theme),
                    _PoweredBadge(label: 'Riverpod', emoji: '🎯', theme: theme),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Rotating funny footer ─────────────────────────────────────────
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: Text(
                '// ${_footerMessages[_footerIndex]}',
                key: ValueKey(_footerIndex),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.32),
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ),
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

// ─── Shared card shell ────────────────────────────────────────────────────────

class _AppCard extends StatelessWidget {
  const _AppCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _PoweredBadge extends StatelessWidget {
  const _PoweredBadge({
    required this.label,
    this.emoji = '',
    required this.theme,
  });
  final String label;
  final String emoji;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final iconSurface = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.035);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: _buildBrandIcon(),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandIcon() {
    switch (label) {
      case 'Flutter':
        return const Icon(
          SimpleIcons.flutter,
          color: SimpleIconColors.flutter,
          size: 24,
        );
      case 'Firebase':
        return const Icon(
          SimpleIcons.firebase,
          color: SimpleIconColors.firebase,
          size: 24,
        );
      case 'Supabase':
        return const Icon(
          SimpleIcons.supabase,
          color: SimpleIconColors.supabase,
          size: 24,
        );
      case 'Riverpod':
        return Image.asset(
          'assets/branding/riverpod_icon.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Password sheet ──────────────────────────────────────────────────────────

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet({
    required this.email,
    required this.username,
  });

  final String email;
  final String username;

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_confirmCtrl.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = 'Type DELETE to confirm account removal.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success =
        await ref.read(authControllerProvider.notifier).deleteAccount();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final failure = ref.read(authControllerProvider);
    final rawError = failure.asError?.error.toString() ?? '';
    setState(() {
      _loading = false;
      _error = rawError.contains('requires-recent-login')
          ? 'For security, sign in again before deleting your account.'
          : 'Account deletion failed. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usernameLabel =
        widget.username.isNotEmpty ? '@${widget.username}' : widget.email;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: theme.colorScheme.error,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete account',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usernameLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action is permanent.',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Deleting your account will remove your profile, username reservation, presence status, room memberships, rooms you created, and messages tied to this account.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.78),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Older chats will stay visible, but your identity will be replaced with Deleted user.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.64),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Type DELETE to confirm',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmCtrl,
              textCapitalization: TextCapitalization.characters,
              enabled: !_loading,
              decoration: const InputDecoration(
                hintText: 'DELETE',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: _loading ? null : _deleteAccount,
                    child: _loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onError,
                            ),
                          )
                        : const Text('Delete account'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordSheet extends ConsumerStatefulWidget {
  const _PasswordSheet({required this.email});
  final String email;

  @override
  ConsumerState<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends ConsumerState<_PasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  bool _emailSent = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentCtrl.text.trim();
    final newPw = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (newPw.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (newPw != confirm) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).changePassword(
            currentPassword: current,
            newPassword: newPw,
          );
      if (mounted) Navigator.pop(context);
    } on Exception catch (e) {
      final msg = e.toString();
      setState(() {
        _error =
            msg.contains('wrong-password') || msg.contains('invalid-credential')
                ? 'Current password is incorrect.'
                : msg.contains('weak-password')
                    ? 'New password is too weak.'
                    : 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _loading = true;
      _error = null;
      _emailSent = false;
    });
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(widget.email);
      if (mounted) {
        setState(() {
          _emailSent = true;
          _loading = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to send reset email.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Password',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),

            // ── Change password fields ────────────────────────────────────
            TextField(
              controller: _currentCtrl,
              obscureText: !_showCurrent,
              decoration: InputDecoration(
                labelText: 'Current password',
                suffixIcon: IconButton(
                  icon: Icon(_showCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showCurrent = !_showCurrent),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newCtrl,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: 'New password',
                suffixIcon: IconButton(
                  icon: Icon(_showNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmCtrl,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _changePassword,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update password'),
            ),

            const SizedBox(height: 24),

            // ── Or reset via email ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'or',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_emailSent)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reset email sent to ${widget.email}',
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _loading ? null : _sendResetEmail,
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Send password reset email'),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuildStudioSheet extends StatelessWidget {
  const _BuildStudioSheet({
    required this.versionLabel,
    required this.versionName,
    required this.buildNumber,
    required this.packageName,
  });

  final String versionLabel;
  final String versionName;
  final String buildNumber;
  final String packageName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platformName = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.18),
                      theme.colorScheme.secondary.withValues(alpha: 0.13),
                      theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Build studio',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'FlashChat release snapshot',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StudioChip(
                          icon: Icons.sell_rounded,
                          label: versionLabel,
                          color: theme.colorScheme.primary,
                        ),
                        _StudioChip(
                          icon: Icons.desktop_windows_rounded,
                          label: platformName,
                          color: theme.colorScheme.secondary,
                        ),
                        _StudioChip(
                          icon: Icons.verified_rounded,
                          label: 'Runtime metadata',
                          color: theme.colorScheme.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'A cleaner home for app identity, build details, and release context.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _StudioPanel(
                title: 'Build metadata',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    _StudioRow(
                      label: 'Version',
                      value: versionName.isNotEmpty ? versionName : versionLabel,
                    ),
                    const SizedBox(height: 12),
                    _StudioRow(
                      label: 'Build number',
                      value: buildNumber.isNotEmpty ? buildNumber : 'Unavailable',
                    ),
                    const SizedBox(height: 12),
                    _StudioRow(
                      label: 'Package id',
                      value: packageName.isNotEmpty ? packageName : 'Unavailable',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _StudioPanel(
                title: 'Release notes',
                icon: Icons.tips_and_updates_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This panel replaces the old random tap easter egg with something more useful and polished.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use it when you want to confirm the real runtime version, not just a hardcoded label.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudioChip extends StatelessWidget {
  const _StudioChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioPanel extends StatelessWidget {
  const _StudioPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StudioRow extends StatelessWidget {
  const _StudioRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
