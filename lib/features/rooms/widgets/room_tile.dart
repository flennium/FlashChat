import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/room_model.dart';
import '../../../services/firestore_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../controllers/room_controller.dart';
import '../screens/create_room_screen.dart';
import 'room_info_sheet.dart';

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
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _isWorking ? null : _handleTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
                theme.colorScheme.surfaceContainer.withValues(alpha: 0.96),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _RoomAvatar(room: room, unreadCount: unreadCount),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showRoomInfoSheet(context, room: room),
                        child: Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          /*GestureDetector(
                            onTap: () => showRoomInfoSheet(context, room: room),
                            child: _RoomPill(
                              icon: Icons.info_outline_rounded,
                              label: 'Room details',
                              backgroundColor:
                                  theme.colorScheme.primary.withValues(alpha: 0.1),
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),*/
                          if (unreadCount > 0)
                            _RoomPill(
                              icon: Icons.mark_chat_unread_rounded,
                              label: unreadCount > 99
                                  ? '99+ unread'
                                  : '$unreadCount unread',
                              backgroundColor: theme.colorScheme.errorContainer,
                              foregroundColor:
                                  theme.colorScheme.onErrorContainer,
                            )
                          else
                            _RoomPill(
                              icon: Icons.done_all_rounded,
                              label: '',
                              backgroundColor: theme.colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.7),
                              foregroundColor: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.68),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (_isWorking)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                else if (canManage)
                  PopupMenuButton<_RoomMenuAction>(
                    tooltip: 'Room actions',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (value) => _handleRoomAction(context, value),
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
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
        ),
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
  const _RoomAvatar({
    required this.room,
    required this.unreadCount,
  });

  final RoomModel room;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadLabel = unreadCount > 99 ? '99+' : '$unreadCount';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.88),
          backgroundImage:
              room.avatarUrl.isNotEmpty ? NetworkImage(room.avatarUrl) : null,
          child: room.avatarUrl.isEmpty
              ? Icon(
                  Icons.forum_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        if (room.isPrivate)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                unreadLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoomPill extends StatelessWidget {
  const _RoomPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
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
                  fontWeight: FontWeight.w800,
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
