import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/room_model.dart';

Future<void> showRoomInfoSheet(
  BuildContext context, {
  required RoomModel room,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RoomInfoSheet(room: room),
  );
}

class _RoomInfoSheet extends StatelessWidget {
  const _RoomInfoSheet({required this.room});

  final RoomModel room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ownerLabel =
        room.ownerLabel.isNotEmpty ? room.ownerLabel : 'Unknown owner';
    final createdLabel = DateFormat('MMM d, y').format(room.createdAt);

    return DraggableScrollableSheet(
      initialChildSize: 0.64,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomAvatarHero(room: room, radius: 34),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: room.isPrivate
                                  ? Icons.lock_rounded
                                  : Icons.public_rounded,
                              label:
                                  room.isPrivate ? 'Private room' : 'Open room',
                            ),
                            _InfoChip(
                              icon: Icons.group_rounded,
                              label: '${room.memberCount} members',
                            ),
                            _InfoChip(
                              icon: Icons.calendar_today_rounded,
                              label: createdLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (room.description.isNotEmpty) ...[
                const SizedBox(height: 24),
                _InfoSection(
                  title: 'About this room',
                  child: Text(
                    room.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _InfoSection(
                title: 'Owner',
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ownerLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (room.pinnedMessage.isNotEmpty) ...[
                const SizedBox(height: 18),
                _InfoSection(
                  title: 'Pinned message',
                  child: Text(
                    room.pinnedMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomAvatarHero extends StatelessWidget {
  const _RoomAvatarHero({
    required this.room,
    required this.radius,
  });

  final RoomModel room;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
          backgroundImage:
              room.avatarUrl.isNotEmpty ? NetworkImage(room.avatarUrl) : null,
          child: room.avatarUrl.isEmpty
              ? Icon(
                  Icons.forum_rounded,
                  size: radius,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        if (room.isPrivate)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 13,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
