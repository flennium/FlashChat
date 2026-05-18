import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/platform_support.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/settings_screen.dart';
import '../../rooms/screens/room_list_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  OverlayEntry? _notifOverlay;

  static const _screens = [
    RoomListScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_initPresence);
    if (PlatformSupport.supportsPushNotifications) {
      _fcmSubscription =
          FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(_saveFcmToken);
    }
    _authSubscription = ref.listenManual<AsyncValue<User?>>(
      authStateProvider,
      (_, next) {
        next.whenData((user) {
          if (user == null && mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        });
      },
    );
  }

  Future<void> _initPresence() async {
    final profile =
        await ref.read(firestoreServiceProvider).fetchCurrentUserProfile();
    final username = profile?.username ?? '';
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (PlatformSupport.supportsRealtimePresence) {
      await ref.read(presenceServiceProvider).setOnline(username: username);
    }

    final token = PlatformSupport.supportsPushNotifications
        ? await ref.read(fcmServiceProvider).initAndGetToken()
        : null;
    if (authUser != null) {
      await _saveFcmTokenForUser(authUser.uid, token);
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await _saveFcmTokenForUser(uid, token);
  }

  Future<void> _saveFcmTokenForUser(String uid, String? token) {
    if (token == null || token.isEmpty) return Future.value();
    return ref.read(firestoreServiceProvider).updateProfile(
          uid: uid,
          fcmToken: token,
        );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || !mounted) return;
    final activeRoomId = ref.read(activeRoomIdProvider);
    final incomingRoomId = message.data['roomId']?.toString();
    if (activeRoomId != null &&
        incomingRoomId != null &&
        incomingRoomId == activeRoomId) {
      return;
    }
    _showBanner(
      title: notification.title ?? '',
      body: notification.body ?? '',
    );
  }

  void _showBanner({required String title, required String body}) {
    _notifOverlay?.remove();
    _notifOverlay = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _NotifBanner(
        title: title,
        body: body,
        onDismiss: () {
          entry.remove();
          if (_notifOverlay == entry) _notifOverlay = null;
        },
      ),
    );

    _notifOverlay = entry;
    Overlay.of(context).insert(entry);
  }

  @override
  void dispose() {
    _notifOverlay?.remove();
    _fcmSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.forum_rounded), label: 'Rooms'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
          NavigationDestination(
              icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

class _NotifBanner extends StatefulWidget {
  const _NotifBanner({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback onDismiss;

  @override
  State<_NotifBanner> createState() => _NotifBannerState();
}

class _NotifBannerState extends State<_NotifBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    );
    _ctrl.forward();
    _timer = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topCenter,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            bottom: false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
              onVerticalDragEnd: (d) {
                // Swipe up dismisses immediately
                if ((d.primaryVelocity ?? 0) < -200) _dismiss();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1E).withValues(alpha: 0.96)
                          : Colors.white.withValues(alpha: 0.97),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.45 : 0.18),
                          blurRadius: 28,
                          spreadRadius: -4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Gradient icon circle — mirrors Instagram's app icon style
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.tertiary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Text column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title row + "now" timestamp
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'now',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.35)
                                          : Colors.black
                                              .withValues(alpha: 0.35),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.body.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : Colors.black.withValues(alpha: 0.52),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Dismiss chevron hint
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 18,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
