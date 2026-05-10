import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../models/message_model.dart';
import '../../../models/room_model.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/message_skeleton.dart';
import '../widgets/online_indicator.dart';
import '../widgets/pinned_banner.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/unread_divider.dart';
import '../../rooms/controllers/room_controller.dart';
import '../../rooms/screens/create_room_screen.dart';

// Sentinel value inserted into the display-item list to mark the unread divider.
const _kUnreadDivider = '__unread_divider__';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.room});

  final RoomModel room;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  // ── Scroll ──────────────────────────────────────────────────────────────
  final _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  // ── Timestamp reveal (horizontal swipe) ─────────────────────────────────
  double _timestampReveal = 0.0;
  double _dragStartX = 0.0;

  // ── Pagination ──────────────────────────────────────────────────────────
  bool _isLoadingMore = false;

  // ── Scroll-position restore after loading older messages ─────────────────
  // When older items are prepended the list grows "above" the current view.
  // We capture pixels+maxExtent before the load and then jump by the delta
  // after the new frame so the user stays at the same visual spot.
  int _lastKnownItemCount = 0;
  bool _needsPositionRestore = false;
  double _restoreBasePixels = 0;
  double _restoreBaseMaxExtent = 0;

  // ── Unread divider ──────────────────────────────────────────────────────
  String? _firstUnreadId;
  bool _initialLoadDone = false;
  bool _hasScrolledToUnread = false;
  bool _scrollToUnreadScheduled = false;

  // ── Message cache ────────────────────────────────────────────────────────
  // Keeps the last delivered list so the ListView is never swapped out for a
  // skeleton while the stream re-subscribes during a load-more page increment.
  List<MessageModel>? _cachedMessages;

  // ── Reply-scroll (GlobalKey map) ─────────────────────────────────────────
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    ref.read(activeRoomIdProvider.notifier).state = widget.room.id;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.id != widget.room.id) {
      ref.read(activeRoomIdProvider.notifier).state = widget.room.id;
    }
  }

  @override
  void dispose() {
    final activeRoomId = ref.read(activeRoomIdProvider);
    if (activeRoomId == widget.room.id) {
      ref.read(activeRoomIdProvider.notifier).state = null;
    }
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll listener ──────────────────────────────────────────────────────

  void _onScroll() {
    final pos = _scrollController.position;

    // Show FAB only when the user is meaningfully scrolled up —
    // 350 px keeps it hidden while viewing the last ~4-5 messages.
    final show = pos.pixels > 350;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }

    // Load older messages when user reaches the top (far end in reverse list)
    if (!_isLoadingMore &&
        pos.pixels >= pos.maxScrollExtent - 120 &&
        pos.maxScrollExtent > 0) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    // Snapshot current scroll state so we can restore it after the new
    // items are prepended and the list grows "above" the viewport.
    if (_scrollController.hasClients) {
      _restoreBasePixels = _scrollController.position.pixels;
      _restoreBaseMaxExtent = _scrollController.position.maxScrollExtent;
      _needsPositionRestore = _restoreBasePixels > 150;
    }
    setState(() => _isLoadingMore = true);
    ref.read(chatControllerProvider.notifier).loadMoreMessages(widget.room);
    // Give the stream a moment to deliver new docs before hiding the spinner.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _scrollToBottom() {
    // Hide FAB immediately — don't wait for the scroll animation to cross
    // the threshold, which can leave the button visible until 220 px is passed.
    if (_showScrollToBottom) setState(() => _showScrollToBottom = false);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  // ── Horizontal drag (timestamp reveal) ──────────────────────────────────

  void _onDragStart(DragStartDetails d) => _dragStartX = d.localPosition.dx;

  void _onDragUpdate(DragUpdateDetails d) {
    final reveal = ((_dragStartX - d.localPosition.dx) / 80.0).clamp(0.0, 1.0);
    if (reveal != _timestampReveal) setState(() => _timestampReveal = reveal);
  }

  void _onDragEnd(DragEndDetails _) {
    if (_timestampReveal != 0.0) setState(() => _timestampReveal = 0.0);
  }

  // ── Grouping helpers ─────────────────────────────────────────────────────

  static bool _canGroup(MessageModel a, MessageModel b) {
    if (a.senderId != b.senderId) return false;
    return b.timestamp.difference(a.timestamp).inSeconds.abs() < 180;
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ── Display-item list builder ────────────────────────────────────────────

  List<Object> _buildItems(List<MessageModel> messages, String currentUid) {
    // Set the unread marker exactly once on the first data delivery.
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      for (final m in messages) {
        if (!m.readBy.contains(currentUid) && m.senderId != currentUid) {
          _firstUnreadId = m.id;
          break;
        }
      }
    }

    final items = <Object>[];
    for (int i = 0; i < messages.length; i++) {
      final m = messages[i];
      final prev = i > 0 ? messages[i - 1] : null;
      final next = i < messages.length - 1 ? messages[i + 1] : null;

      // Date separator when the calendar day changes
      if (prev == null || !_sameDay(prev.timestamp, m.timestamp)) {
        items.add(_DateItem(m.timestamp));
      }

      // Unread divider
      if (m.id == _firstUnreadId) items.add(_kUnreadDivider);

      final isFirstInGroup = prev == null || !_canGroup(prev, m);
      final isLastInGroup = next == null || !_canGroup(m, next);

      items.add(_MessageItem(
        message: m,
        isFirstInGroup: isFirstInGroup,
        isLastInGroup: isLastInGroup,
      ));
    }
    return items;
  }

  void _scheduleScrollToUnread() {
    if (_hasScrolledToUnread ||
        _firstUnreadId == null ||
        _scrollToUnreadScheduled) {
      return;
    }
    _scrollToUnreadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToUnreadScheduled = false;
      if (!mounted || _hasScrolledToUnread) return;
      // Mark done unconditionally — prevents re-triggering on every rebuild
      // if the message key isn't ready yet on the first frame.
      _hasScrolledToUnread = true;
      final key = _messageKeys[_firstUnreadId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.4,
        );
      }
    });
  }

  // ── Message area ─────────────────────────────────────────────────────────
  //
  // Uses a local cache (_cachedMessages) so the ListView is never swapped for
  // a skeleton while the StreamProvider briefly re-subscribes after a
  // load-more limit increment. The spinner at the top of the list shows the
  // user that more messages are loading; position is preserved via the
  // _restoreBasePixels / _restoreBaseMaxExtent delta-jump.

  Widget _buildMessageArea(
    AsyncValue<List<MessageModel>> messagesAsync,
    RoomModel room,
    String currentUid,
  ) {
    // Always update the cache when fresh data arrives.
    if (messagesAsync.hasValue) _cachedMessages = messagesAsync.value!;

    final messages = _cachedMessages;

    // Nothing cached yet — genuine first load.
    if (messages == null) {
      if (messagesAsync.hasError) {
        return Center(child: Text(messagesAsync.error.toString()));
      }
      return const MessageSkeleton();
    }

    // Mark messages as read (write-loop guard: only when unread ones exist).
    final hasUnread = messages.any(
      (m) => !m.readBy.contains(currentUid) && m.senderId != currentUid,
    );
    if (hasUnread) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatControllerProvider.notifier).markRead(room, messages);
      });
    }

    if (messages.isEmpty) return _EmptyState(roomName: room.name);

    final items = _buildItems(messages, currentUid);

    // When older messages are loaded the list grows at the "top" (high-pixel
    // end in a reverse list). Jump by the extra maxScrollExtent so the user
    // stays at the same visual spot instead of being teleported to the bottom.
    if (_needsPositionRestore && items.length > _lastKnownItemCount) {
      _needsPositionRestore = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final delta = _scrollController.position.maxScrollExtent -
            _restoreBaseMaxExtent;
        if (delta > 0 && _restoreBasePixels > 0) {
          _scrollController.jumpTo(
            (_restoreBasePixels + delta).clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            ),
          );
        }
      });
    }
    _lastKnownItemCount = items.length;

    _scheduleScrollToUnread();

    return Stack(
      children: [
        GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: ListView.builder(
            reverse: true,
            controller: _scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            itemCount: items.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (_, index) {
              // Loading spinner at the top (highest index in a reverse list).
              if (_isLoadingMore && index == items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = items[items.length - 1 - index];

              if (item == _kUnreadDivider) return const UnreadDivider();
              if (item is _DateItem) return _DateSeparator(date: item.date);

              final msgItem = item as _MessageItem;
              final message = msgItem.message;

              _messageKeys[message.id] ??= GlobalKey();

              return KeyedSubtree(
                key: _messageKeys[message.id],
                child: MessageBubble(
                  message: message,
                  isMe: currentUid == message.senderId,
                  room: room,
                  timestampReveal: _timestampReveal,
                  onReplyTap: _scrollToMessage,
                  isFirstInGroup: msgItem.isFirstInGroup,
                  isLastInGroup: msgItem.isLastInGroup,
                ),
              );
            },
          ),
        ),
        if (_showScrollToBottom)
          Positioned(
            right: 14,
            bottom: 14,
            child: _ScrollToBottomFab(onTap: _scrollToBottom),
          ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.room.id));
    final room = roomAsync.value ?? widget.room;
    final messagesAsync = ref.watch(roomMessagesProvider(widget.room.id));
    final onlineCount = ref.watch(onlineCountProvider).value ?? 0;
    final announcement = ref.watch(announcementProvider).value ?? '';
    final typingUsers =
        ref.watch(typingUsersProvider(widget.room.id)).value ?? [];
    final currentUid = ref.watch(currentUserProfileProvider).value?.uid ?? '';
    final currentProfile = ref.watch(currentUserProfileProvider).value;
    final roomAdminEmail = ref.watch(roomAdminEmailProvider).value ?? '';
    final canManageRoom = currentProfile != null &&
        (currentProfile.uid == room.createdBy ||
            (roomAdminEmail.isNotEmpty &&
                currentProfile.email.trim().toLowerCase() == roomAdminEmail));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (room.avatarUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(room.avatarUrl),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    room.ownerLabel.isNotEmpty
                        ? 'Room owner ${room.ownerLabel.toLowerCase()}'
                        : 'Room owner unknown',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (canManageRoom)
            IconButton(
              onPressed: () async {
                final wasDeleted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => CreateRoomScreen(room: room),
                  ),
                );
                if (wasDeleted == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit room',
            ),
          OnlineIndicator(count: onlineCount),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          if (announcement.isNotEmpty || room.pinnedMessage.isNotEmpty)
            PinnedBanner(
              message: room.pinnedMessage.isNotEmpty
                  ? room.pinnedMessage
                  : announcement,
            ),
          Expanded(
            child: _buildMessageArea(messagesAsync, room, currentUid),
          ),
          // Typing indicator just above the input
          TypingIndicator(typingUsers: typingUsers),
          MessageInput(room: room),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ScrollToBottomFab extends StatelessWidget {
  const _ScrollToBottomFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: theme.colorScheme.primary,
          size: 22,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.roomName});

  final String roomName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to say something in $roomName!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Display-item data types
// ─────────────────────────────────────────────────────────────────────────────

class _MessageItem {
  const _MessageItem({
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  final MessageModel message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
}

class _DateItem {
  const _DateItem(this.date);
  final DateTime date;
}

// ─────────────────────────────────────────────────────────────────────────────
// Date separator widget
// ─────────────────────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final yr = date.year != now.year ? ', ${date.year}' : '';
    return '${_monthName(date.month)} ${date.day}$yr';
  }

  static const _months = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _monthName(int m) => _months[m];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _label(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
