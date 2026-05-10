import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int _versionTapStreak = 0;
  Timer? _footerTimer;

  @override
  void initState() {
    super.initState();
    _footerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(
            () => _footerIndex = (_footerIndex + 1) % _footerMessages.length);
      }
    });
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

  void _onVersionTap() {
    _versionTapStreak++;

    // Keep a small hidden interaction without making the tap target frustrating.
    final shouldOpen = _versionTapStreak >= 12 || Random().nextInt(8) == 0;

    if (shouldOpen) {
      _versionTapStreak = 0;
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          pageBuilder: (_, __, ___) => const _CelebrationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final activeVariant = ref.watch(themeVariantControllerProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final theme = Theme.of(context);
    const titleColor = Colors.white;
    final mutedTitleColor = Colors.white.withValues(alpha: 0.78);

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
            textColor: theme.colorScheme.error,
            onTap: () =>
                ref.read(authControllerProvider.notifier).deleteAccount(),
          ),

          const SizedBox(height: 28),

          // ── App ────────────────────────────────────────────────────────────
          Text(
            'App',
            style: theme.textTheme.titleLarge?.copyWith(color: titleColor),
          ),
          const SizedBox(height: 16),

          // Version card — tap for 0.1% easter egg
          _AppCard(
            child: GestureDetector(
              onTap: _onVersionTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.flash_on_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FlashChat',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Badge(
                              label: 'v0.1.1',
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            _Badge(
                              label: 'Project Build',
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
    required this.emoji,
    required this.theme,
  });
  final String label;
  final String emoji;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 5),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─── Password sheet ──────────────────────────────────────────────────────────

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

// Hidden version detail screen

class _CelebrationScreen extends StatefulWidget {
  const _CelebrationScreen();

  @override
  State<_CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<_CelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleIn;
  late final Animation<double> _glow;
  bool _canDismiss = false;

  // Deterministic particle layout for a consistent visual effect.
  static final _rng = Random(42);
  final _particles = List.generate(
    22,
    (i) => _ParticleData(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      size: 14.0 + _rng.nextDouble() * 18,
      speed: 0.25 + _rng.nextDouble() * 0.5,
      emoji: ['👑', '💎', '✨', '⭐', '🌟', '💫'][i % 6],
    ),
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _scaleIn = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _canDismiss = true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _canDismiss ? () => Navigator.pop(context) : null,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final g = _glow.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                      const Color.fromARGB(255, 71, 237, 226), const Color.fromARGB(255, 183, 242, 155), g)!,
                  Color.lerp(
                      const Color.fromARGB(255, 4, 135, 116), const Color.fromARGB(255, 153, 233, 144), g)!,
                  Color.lerp(
                      const Color.fromARGB(255, 2, 82, 84), const Color.fromARGB(255, 2, 124, 71), g)!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Floating particles
                ..._particles.map(
                  (p) => _FloatingParticle(particle: p, ctrl: _ctrl),
                ),
                // Center content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _scaleIn,
                          child: const Text(
                            '💖',
                            style: TextStyle(fontSize: 88),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ScaleTransition(
                          scale: _scaleIn,
                          child: const Text(
                            'FLASHCHAT\nVERSION DETAIL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.25,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Project detail view unlocked',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thanks for exploring the project.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 13),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3B1F00).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color(0xFF3B1F00)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _canDismiss
                                ? 'Tap anywhere to close'
                                : 'Preparing view...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ParticleData {
  const _ParticleData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.emoji,
  });
  final double x;
  final double y;
  final double size;
  final double speed;
  final String emoji;
}

class _FloatingParticle extends StatelessWidget {
  const _FloatingParticle({required this.particle, required this.ctrl});
  final _ParticleData particle;
  final Animation<double> ctrl;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = (ctrl.value * particle.speed) % 1.0;
        final yPos = ((particle.y - t * 1.4) % 1.0) * screen.height;
        final opacity =
            (0.35 + 0.65 * sin(ctrl.value * pi * 2 * particle.speed))
                .clamp(0.0, 1.0);
        return Positioned(
          left: particle.x * screen.width,
          top: yPos,
          child: Opacity(
            opacity: opacity,
            child: Text(
              particle.emoji,
              style: TextStyle(fontSize: particle.size),
            ),
          ),
        );
      },
    );
  }
}
