import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/utils/validators.dart';
import '../../../models/room_model.dart';
import '../../chat/screens/chat_screen.dart';
import '../controllers/room_controller.dart';
import '../screens/create_room_screen.dart';

class RoomTile extends ConsumerWidget {
  const RoomTile({super.key, required this.room});

  final RoomModel room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(roomUnreadCountProvider(room.id));
    final currentProfileAsync = ref.watch(currentUserProfileProvider);
    final adminEmailAsync = ref.watch(roomAdminEmailProvider);
    final isLoading = ref.watch(roomControllerProvider).isLoading;
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
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : SizedBox(
                width: canManage ? 126 : 76,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '+$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          if (unreadCount > 0) const SizedBox(height: 6),
                          Chip(label: Text('${room.memberCount}')),
                        ],
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<_RoomMenuAction>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) =>
                            _handleRoomAction(context, ref, value),
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
        onTap: isLoading ? null : () => _handleTap(context, ref),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final firestore = ref.read(firestoreServiceProvider);
    final isMember = await firestore.isCurrentUserRoomMember(room.id);

    if (!context.mounted) return;

    if (!room.isPrivate || isMember) {
      final ok =
          await ref.read(roomControllerProvider.notifier).joinRoom(room: room);
      if (ok && context.mounted) {
        _openChat(context);
      }
      return;
    }

    final accessCode = await _promptForAccessCode(context);
    if (!context.mounted || accessCode == null) return;

    final ok = await ref
        .read(roomControllerProvider.notifier)
        .joinRoom(room: room, accessCode: accessCode);

    if (ok && context.mounted) {
      _openChat(context);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong access code.')),
      );
    }
  }

  Future<void> _handleRoomAction(
    BuildContext context,
    WidgetRef ref,
    _RoomMenuAction action,
  ) async {
    switch (action) {
      case _RoomMenuAction.edit:
        Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => CreateRoomScreen(room: room),
          ),
        );
        break;
      case _RoomMenuAction.delete:
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete room'),
            content: Text('Delete "${room.name}"?'),
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
          final ok =
              await ref.read(roomControllerProvider.notifier).deleteRoom(room);
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
      MaterialPageRoute<void>(builder: (_) => ChatScreen(room: room)),
    );
  }

  Future<String?> _promptForAccessCode(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _PrivateRoomAccessDialog(),
    );

    final trimmed = InputSanitizer.normalizeAccessCode(result ?? '');
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _PrivateRoomAccessDialog extends StatefulWidget {
  const _PrivateRoomAccessDialog();

  @override
  State<_PrivateRoomAccessDialog> createState() =>
      _PrivateRoomAccessDialogState();
}

class _PrivateRoomAccessDialogState extends State<_PrivateRoomAccessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Private room'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Access code',
            hintText: 'Enter room code',
          ),
          validator: Validators.accessCodeRequired,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Join'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      InputSanitizer.normalizeAccessCode(_controller.text),
    );
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

enum _RoomMenuAction {
  edit,
  delete,
}
