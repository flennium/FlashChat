import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/room_model.dart';
import '../../../services/firestore_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../controllers/room_controller.dart';
import '../screens/create_room_screen.dart';

class RoomTile extends ConsumerStatefulWidget {
  const RoomTile({super.key, required this.room});

  final RoomModel room;

  @override
  ConsumerState<RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends ConsumerState<RoomTile> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final unreadAsync = ref.watch(roomUnreadCountProvider(room.id));
    final currentProfileAsync = ref.watch(currentUserProfileProvider);
    final adminEmailAsync = ref.watch(roomAdminEmailProvider);
    final unreadCount = unreadAsync.valueOrNull ?? 0;
    final currentProfile = currentProfileAsync.valueOrNull;
    final adminEmail = adminEmailAsync.valueOrNull ?? '';
    final canManage = currentProfile != null &&
        (currentProfile.uid == room.createdBy ||
            (adminEmail.isNotEmpty &&
                currentProfile.email.trim().toLowerCase() == adminEmail));

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: _RoomAvatar(room: room),
        title: Text(room.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Room owner ${room.ownerLabel.isNotEmpty ? room.ownerLabel : 'Unknown'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
            ),
            if (room.description.isNotEmpty)
              Text(
                room.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: _isWorking
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : SizedBox(
                width: canManage ? 164 : 114,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _RoomStatusCluster(
                        unreadCount: unreadCount,
                        memberCount: room.memberCount,
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 8),
                      PopupMenuButton<_RoomMenuAction>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) =>
                            _handleRoomAction(context, value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _RoomMenuAction.edit,
                            child: Text('Edit room'),
                          ),
                          PopupMenuItem(
                            value: _RoomMenuAction.delete,
                            child: Text('Delete room'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
        onTap: _isWorking ? null : _handleTap,
      ),
    );
  }

  Future<void> _handleTap() async {
    setState(() => _isWorking = true);
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final isMember = await firestore.isCurrentUserRoomMember(widget.room.id);

      if (!mounted) return;

      if (!widget.room.isPrivate || isMember) {
        final result = await firestore.joinRoom(room: widget.room);
        if (!mounted) return;

        if (result == RoomJoinResult.success) {
          _openChat(context);
        } else {
          _showJoinFailure(result);
        }
        return;
      }

      final joined = await showDialog<bool>(
        context: context,
        builder: (_) => _PrivateRoomAccessDialog(room: widget.room),
      );

      if (joined == true && mounted) {
        _openChat(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _handleRoomAction(
    BuildContext context,
    _RoomMenuAction action,
  ) async {
    switch (action) {
      case _RoomMenuAction.edit:
        Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => CreateRoomScreen(room: widget.room),
          ),
        );
        break;
      case _RoomMenuAction.delete:
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete room'),
            content: Text('Delete "${widget.room.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (shouldDelete == true && context.mounted) {
          setState(() => _isWorking = true);
          final ok = await ref
              .read(roomControllerProvider.notifier)
              .deleteRoom(widget.room);
          if (!mounted) return;
          setState(() => _isWorking = false);
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Room deleted.')),
            );
          }
        }
        break;
    }
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatScreen(room: widget.room)),
    );
  }

  void _showJoinFailure(RoomJoinResult result) {
    final message = switch (result) {
      RoomJoinResult.invalidAccessCode => 'Wrong access code.',
      RoomJoinResult.roomUnavailable => 'This room is no longer available.',
      RoomJoinResult.unauthenticated => 'Please sign in and try again.',
      RoomJoinResult.success => null,
    };

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _PrivateRoomAccessDialog extends ConsumerStatefulWidget {
  const _PrivateRoomAccessDialog({required this.room});

  final RoomModel room;

  @override
  ConsumerState<_PrivateRoomAccessDialog> createState() =>
      _PrivateRoomAccessDialogState();
}

class _PrivateRoomAccessDialogState
    extends ConsumerState<_PrivateRoomAccessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  bool _obscureText = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Private room'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the access code for "${widget.room.name}".',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                obscureText: _obscureText,
                enabled: !_isSubmitting,
                textInputAction: TextInputAction.done,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: 'Access code',
                  hintText: 'Enter room code',
                  errorText: _errorText,
                  suffixIcon: IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _obscureText = !_obscureText),
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: Validators.accessCodeRequired,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              Text(
                'Codes are case-sensitive.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final result = await ref.read(firestoreServiceProvider).joinRoom(
          room: widget.room,
          accessCode: _controller.text,
        );

    if (!mounted) {
      return;
    }

    switch (result) {
      case RoomJoinResult.success:
        Navigator.of(context).pop(true);
        return;
      case RoomJoinResult.invalidAccessCode:
        setState(() {
          _isSubmitting = false;
          _errorText = 'That access code is incorrect. Please try again.';
        });
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
        return;
      case RoomJoinResult.roomUnavailable:
        setState(() {
          _isSubmitting = false;
          _errorText = 'This room is no longer available.';
        });
        return;
      case RoomJoinResult.unauthenticated:
        setState(() {
          _isSubmitting = false;
          _errorText = 'Please sign in and try again.';
        });
        return;
    }
  }
}

class _RoomAvatar extends StatelessWidget {
  const _RoomAvatar({required this.room});

  final RoomModel room;

  @override
  Widget build(BuildContext context) {
    if (room.avatarUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(room.avatarUrl),
      );
    }

    return CircleAvatar(
      child: Icon(room.isPrivate ? Icons.lock_rounded : Icons.forum_rounded),
    );
  }
}

class _RoomStatusCluster extends StatelessWidget {
  const _RoomStatusCluster({
    required this.unreadCount,
    required this.memberCount,
  });

  final int unreadCount;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = unreadCount > 0;
    final unreadLabel = unreadCount > 99 ? '99+' : '$unreadCount';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: hasUnread
              ? _RoomMetaPill(
                  key: const ValueKey('unread'),
                  icon: Icons.mark_chat_unread_rounded,
                  label: '$unreadLabel new',
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  borderColor: theme.colorScheme.error.withValues(alpha: 0.18),
                  emphasized: true,
                )
              : _RoomMetaPill(
                  key: const ValueKey('quiet'),
                  icon: Icons.done_all_rounded,
                  label: '',
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.72),
                  foregroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  borderColor: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
        ),
        const SizedBox(height: 8),
        _RoomMetaPill(
          icon: Icons.group_rounded,
          label: '$memberCount members',
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.74),
          borderColor: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}

class _RoomMetaPill extends StatelessWidget {
  const _RoomMetaPill({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: foregroundColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
                  letterSpacing: 0.1,
                ),
          ),
        ],
      ),
    );
  }
}

enum _RoomMenuAction {
  edit,
  delete,
}
