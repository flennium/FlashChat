import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/mention_utils.dart';
import '../../../models/message_model.dart';
import '../../../models/room_model.dart';
import '../../profile/widgets/user_profile_modal.dart';
import '../controllers/chat_controller.dart';

const _reactionEmojis = [
  '❤️',
  '😂',
  '😮',
  '😢',
  '😠',
  '👍',
  '👎',
  '🔥',
  '🎉',
  '💯',
];

// URL pattern — styled as links (add url_launcher to pubspec to make tappable)
final _urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);

// ── Group-aware bubble border radius ─────────────────────────────────────────
//
// isFirst/isLast control which corners get the "connected" small radius.
// The connected side is right for sent, left for received.
//
BorderRadius _bubbleRadius({
  required bool isMe,
  required bool isFirst,
  required bool isLast,
}) {
  const double r = 18; // full round
  const double s = 4; // small connector

  if (isFirst && isLast) return BorderRadius.circular(r);

  if (isMe) {
    return BorderRadius.only(
      topLeft: const Radius.circular(r),
      topRight: Radius.circular(isFirst ? r : s),
      bottomLeft: const Radius.circular(r),
      bottomRight: Radius.circular(isLast ? r : s),
    );
  } else {
    return BorderRadius.only(
      topLeft: Radius.circular(isFirst ? r : s),
      topRight: const Radius.circular(r),
      bottomLeft: Radius.circular(isLast ? r : s),
      bottomRight: const Radius.circular(r),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MessageBubble — top-level row widget
// ─────────────────────────────────────────────────────────────────────────────

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.room,
    this.timestampReveal = 0.0,
    this.onReplyTap,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  final MessageModel message;
  final bool isMe;
  final RoomModel room;
  final double timestampReveal;
  final void Function(String messageId)? onReplyTap;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUid =
        ref.watch(currentUserProfileProvider).valueOrNull?.uid ?? '';
    final isDeletedForMe = message.deletedFor.contains(currentUid);
    final isEffectivelyDeleted = message.isDeleted || isDeletedForMe;

    // 2 px inside a group, 3 px for image messages inside a group,
    // 10 px after the last message of a group.
    final bottomPadding =
        isLastInGroup ? 10.0 : (message.imageUrl.isNotEmpty ? 3.0 : 2.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: GestureDetector(
        onLongPress: isEffectivelyDeleted
            ? null
            : () => _showContextMenu(context, ref, currentUid),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Avatar zone (received only) ─────────────────────────────────
            // Always reserve 30 px so all bubbles in the group stay aligned.
            if (!isMe) ...[
              SizedBox(
                width: 30,
                height: 30,
                child: isLastInGroup
                    ? GestureDetector(
                        onTap: () =>
                            showUserProfileModal(context, message.senderId),
                        child: _FrozenAvatar(
                          avatarUrl: message.senderAvatar,
                          name: message.senderName,
                          theme: theme,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
            ] else
              // Left spacer for sent messages keeps them off the screen edge.
              const SizedBox(width: 36),

            // ── Main content column ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display name — received messages, first of group only
                  if (!isMe && !isEffectivelyDeleted && isFirstInGroup)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        message.senderName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ),

                  // Bubble
                  _Bubble(
                    message: message,
                    isMe: isMe,
                    isEffectivelyDeleted: isEffectivelyDeleted,
                    currentUid: currentUid,
                    theme: theme,
                    onReplyTap: onReplyTap,
                    isFirstInGroup: isFirstInGroup,
                    isLastInGroup: isLastInGroup,
                  ),

                  // "edited" for mid-group messages (footer only renders on last)
                  if (!isLastInGroup &&
                      message.isEdited &&
                      !isEffectivelyDeleted)
                    Padding(
                      padding: EdgeInsets.only(
                        top: 2,
                        left: isMe ? 0 : 4,
                        right: isMe ? 4 : 0,
                      ),
                      child: Text(
                        'edited',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.35),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  // ── Footer: time + status (last in group only) ────────────
                  // Sits outside the bubble so it doesn't bloat every message.
                  if (isLastInGroup && !isEffectivelyDeleted)
                    Padding(
                      padding: EdgeInsets.only(
                        top: 3,
                        left: isMe ? 0 : 4,
                        right: isMe ? 4 : 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isEdited)
                            Text(
                              'edited · ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.35),
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          Text(
                            DateFormatter.messageTime(message.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                              fontSize: 10.5,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 3),
                            _ReadReceipt(
                              readBy: message.readBy,
                              senderId: message.senderId,
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Reactions
                  if (message.reactions.isNotEmpty && !isEffectivelyDeleted)
                    _ReactionsRow(
                      message: message,
                      isMe: isMe,
                      room: room,
                      currentUid: currentUid,
                      theme: theme,
                    ),
                ],
              ),
            ),

            // ── Swipe-to-reveal timestamp ───────────────────────────────────
            _TimestampReveal(
              time: DateFormatter.messageTime(message.timestamp),
              reveal: timestampReveal,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(
      BuildContext context, WidgetRef ref, String currentUid) {
    final notifier = ref.read(chatControllerProvider.notifier);
    final replyNotifier = ref.read(replyMessageProvider(room.id).notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContextMenu(
        message: message,
        isMe: isMe,
        room: room,
        outerContext: context,
        onReply: () {
          replyNotifier.state = message;
        },
        onEdit: (newText) {
          notifier.editMessage(
            room: room,
            messageId: message.id,
            newText: newText,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static-first-frame avatar — prevents animated GIFs from looping in the list
// ─────────────────────────────────────────────────────────────────────────────

class _FrozenAvatar extends StatefulWidget {
  const _FrozenAvatar({
    required this.avatarUrl,
    required this.name,
    required this.theme,
  });

  final String avatarUrl;
  final String name;
  final ThemeData theme;

  @override
  State<_FrozenAvatar> createState() => _FrozenAvatarState();
}

class _FrozenAvatarState extends State<_FrozenAvatar> {
  ImageInfo? _imageInfo;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  String? _resolvedUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.avatarUrl.isNotEmpty) _resolveImage();
  }

  @override
  void didUpdateWidget(_FrozenAvatar old) {
    super.didUpdateWidget(old);
    if (old.avatarUrl != widget.avatarUrl) {
      _imageInfo = null;
      if (widget.avatarUrl.isNotEmpty) _resolveImage();
    }
  }

  void _resolveImage() {
    if (widget.avatarUrl == _resolvedUrl) return;
    _resolvedUrl = widget.avatarUrl;
    if (_listener != null) {
      try {
        _stream?.removeListener(_listener!);
      } catch (_) {}
    }
    _imageInfo = null;
    final provider = NetworkImage(widget.avatarUrl);
    _listener = ImageStreamListener(_onFirstFrame);
    _stream = provider.resolve(
        createLocalImageConfiguration(context, size: const Size(30, 30)));
    _stream!.addListener(_listener!);
  }

  void _onFirstFrame(ImageInfo info, bool _) {
    if (!mounted) return;
    setState(() => _imageInfo = info);
    // Remove listener after first frame to freeze GIF avatars
    try {
      _stream?.removeListener(_listener!);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_listener != null) {
      try {
        _stream?.removeListener(_listener!);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_imageInfo != null) {
      return CircleAvatar(
        radius: 15,
        child: ClipOval(
          child: RawImage(
            image: _imageInfo!.image,
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    // Initials placeholder while loading or when no URL
    final showInitials = widget.avatarUrl.isEmpty;
    return CircleAvatar(
      radius: 15,
      backgroundColor: showInitials
          ? widget.theme.colorScheme.primary.withValues(alpha: 0.18)
          : widget.theme.colorScheme.surfaceContainerHighest,
      child: Text(
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: showInitials
              ? widget.theme.colorScheme.primary
              : widget.theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Bubble — the actual rounded container
// ─────────────────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMe,
    required this.isEffectivelyDeleted,
    required this.currentUid,
    required this.theme,
    this.onReplyTap,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  final MessageModel message;
  final bool isMe;
  final bool isEffectivelyDeleted;
  final String currentUid;
  final ThemeData theme;
  final void Function(String)? onReplyTap;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    final bubbleColor = isEffectivelyDeleted
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : isMe
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest;

    final textColor = isMe && !isEffectivelyDeleted
        ? Colors.white
        : theme.colorScheme.onSurface;

    final radius = _bubbleRadius(
      isMe: isMe,
      isFirst: isFirstInGroup,
      isLast: isLastInGroup,
    );

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
        child: isEffectivelyDeleted
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block_rounded,
                      size: 13,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Message deleted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply quote
                  if (message.replyTo != null)
                    GestureDetector(
                      onTap: () {
                        final id = message.replyTo!['id'] as String?;
                        if (id != null) onReplyTap?.call(id);
                      },
                      child: _ReplyQuote(
                        replyTo: message.replyTo!,
                        isMe: isMe,
                        theme: theme,
                      ),
                    ),

                  // Content
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      message.replyTo != null ? 8 : 10,
                      12,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image
                        if (message.imageUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 120,
                                maxHeight: 260,
                              ),
                              child: Image.network(
                                message.imageUrl,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    height: 180,
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (message.text.isNotEmpty)
                            const SizedBox(height: 8),
                        ],

                        // Text with mentions and links
                        if (message.text.isNotEmpty)
                          _RichText(
                            text: message.text,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: textColor),
                            mentionColor: isMe
                                ? Colors.white.withValues(alpha: 0.85)
                                : theme.colorScheme.primary,
                            linkColor: isMe
                                ? Colors.white.withValues(alpha: 0.85)
                                : theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reply quote block inside a bubble
// ─────────────────────────────────────────────────────────────────────────────

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    required this.replyTo,
    required this.isMe,
    required this.theme,
  });

  final Map<String, dynamic> replyTo;
  final bool isMe;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final senderUsername = replyTo['senderUsername'] as String? ?? '';
    final senderName = replyTo['senderName'] as String? ?? '';
    final displayName = senderName.isNotEmpty ? senderName : '@$senderUsername';
    final text = replyTo['text'] as String? ?? '';
    final imageUrl = replyTo['imageUrl'] as String? ?? '';
    final hasImage = imageUrl.isNotEmpty;

    final quoteColor = isMe
        ? Colors.white.withValues(alpha: 0.15)
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final accentColor =
        isMe ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.primary;
    final nameColor =
        isMe ? Colors.white.withValues(alpha: 0.85) : theme.colorScheme.primary;
    final textColor = isMe
        ? Colors.white.withValues(alpha: 0.65)
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: quoteColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(imageUrl,
                  width: 40, height: 40, fit: BoxFit.cover),
            ),
          if (hasImage) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: nameColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: textColor, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (hasImage)
                  Text(
                    '📷 Photo',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: textColor, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Read receipt icon
// ─────────────────────────────────────────────────────────────────────────────

class _ReadReceipt extends StatelessWidget {
  const _ReadReceipt({required this.readBy, required this.senderId});

  final List<String> readBy;
  final String senderId;

  @override
  Widget build(BuildContext context) {
    final hasOtherReaders = readBy.any((uid) => uid != senderId);
    return Icon(
      hasOtherReaders ? Icons.done_all_rounded : Icons.done_rounded,
      size: 13,
      color: hasOtherReaders
          ? Colors.lightBlueAccent
          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Emoji reactions strip
// ─────────────────────────────────────────────────────────────────────────────

class _ReactionsRow extends ConsumerWidget {
  const _ReactionsRow({
    required this.message,
    required this.isMe,
    required this.room,
    required this.currentUid,
    required this.theme,
  });

  final MessageModel message;
  final bool isMe;
  final RoomModel room;
  final String currentUid;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible =
        message.reactions.entries.where((e) => e.value.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: isMe ? 0 : 6,
        right: isMe ? 6 : 0,
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
        children: visible.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final hasReacted = users.contains(currentUid);
          return GestureDetector(
            onTap: () =>
                ref.read(chatControllerProvider.notifier).toggleReaction(
                      room: room,
                      message: message,
                      emoji: emoji,
                    ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hasReacted
                    ? theme.colorScheme.primary.withValues(alpha: 0.18)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasReacted
                      ? theme.colorScheme.primary.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                '$emoji ${users.length}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe-to-reveal timestamp overlay
// ─────────────────────────────────────────────────────────────────────────────

class _TimestampReveal extends StatelessWidget {
  const _TimestampReveal({
    required this.time,
    required this.reveal,
    required this.theme,
  });

  final String time;
  final double reveal;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: reveal,
        child: Opacity(
          opacity: reveal.clamp(0.0, 1.0),
          child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              time,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich text: @mentions + URL links
// ─────────────────────────────────────────────────────────────────────────────

enum _SegType { mention, url }

class _Seg {
  const _Seg(this.start, this.end, this.type, this.value);
  final int start;
  final int end;
  final _SegType type;
  final String value; // username for mention, full URL for url
}

class _RichText extends ConsumerStatefulWidget {
  const _RichText({
    required this.text,
    required this.style,
    required this.mentionColor,
    required this.linkColor,
  });

  final String text;
  final TextStyle? style;
  final Color mentionColor;
  final Color linkColor;

  @override
  ConsumerState<_RichText> createState() => _RichTextState();
}

class _RichTextState extends ConsumerState<_RichText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  List<_Seg> _parseSegments(String text) {
    final segs = <_Seg>[];

    for (final m in MentionUtils.findMentions(text)) {
      segs.add(_Seg(m.start, m.end, _SegType.mention, m.username));
    }
    for (final m in _urlRegex.allMatches(text)) {
      final url = m.group(0)!;
      // Skip if this range overlaps an already-found mention
      final overlaps = segs.any((s) => s.start < m.end && s.end > m.start);
      if (!overlaps) {
        segs.add(_Seg(m.start, m.end, _SegType.url, url));
      }
    }

    segs.sort((a, b) => a.start.compareTo(b.start));
    return segs;
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final segs = _parseSegments(widget.text);
    final spans = <InlineSpan>[];
    int last = 0;

    for (final seg in segs) {
      if (seg.start > last) {
        spans.add(TextSpan(
          text: widget.text.substring(last, seg.start),
          style: widget.style,
        ));
      }

      final chunk = widget.text.substring(seg.start, seg.end);

      switch (seg.type) {
        case _SegType.mention:
          final rec = TapGestureRecognizer()
            ..onTap = () async {
              final uid = await ref
                  .read(firestoreServiceProvider)
                  .getUidByUsername(seg.value);
              if (uid != null && context.mounted) {
                showUserProfileModal(context, uid);
              }
            };
          _recognizers.add(rec);
          spans.add(TextSpan(
            text: chunk,
            style: widget.style?.copyWith(
              color: widget.mentionColor,
              fontWeight: FontWeight.w700,
            ),
            recognizer: rec,
          ));

        case _SegType.url:
          // Visually styled as a link.
          // To make URLs tappable, add url_launcher to pubspec and add a
          // TapGestureRecognizer that calls launchUrl(Uri.parse(seg.value)).
          spans.add(TextSpan(
            text: chunk,
            style: widget.style?.copyWith(
              color: widget.linkColor,
              decoration: TextDecoration.underline,
              decorationColor: widget.linkColor,
            ),
          ));
      }

      last = seg.end;
    }

    if (last < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(last),
        style: widget.style,
      ));
    }

    return Text.rich(TextSpan(children: spans));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Long-press context menu
// ─────────────────────────────────────────────────────────────────────────────

class _ContextMenu extends ConsumerWidget {
  const _ContextMenu({
    required this.message,
    required this.isMe,
    required this.room,
    required this.outerContext,
    required this.onReply,
    required this.onEdit,
  });

  final MessageModel message;
  final bool isMe;
  final RoomModel room;
  final BuildContext outerContext;
  final VoidCallback onReply;
  final void Function(String newText) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Emoji picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactionEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(chatControllerProvider.notifier).toggleReaction(
                          room: room,
                          message: message,
                          emoji: emoji,
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          _MenuItem(
            icon: Icons.reply_outlined,
            label: 'Reply',
            onTap: () {
              Navigator.pop(context);
              onReply();
            },
          ),
          if (isMe && !message.isDeleted)
            _MenuItem(
              icon: Icons.edit_outlined,
              label: 'Edit message',
              onTap: () {
                Navigator.pop(context);
                _showEditDialog();
              },
            ),
          if (isMe && !message.isDeleted)
            _MenuItem(
              icon: Icons.delete_forever_outlined,
              label: 'Delete for everyone',
              color: theme.colorScheme.error,
              onTap: () {
                Navigator.pop(context);
                ref.read(chatControllerProvider.notifier).deleteForEveryone(
                      room: room,
                      messageId: message.id,
                    );
              },
            ),
          _MenuItem(
            icon: Icons.delete_sweep_outlined,
            label: 'Delete for me',
            onTap: () {
              Navigator.pop(context);
              ref.read(chatControllerProvider.notifier).deleteForMe(
                    room: room,
                    message: message,
                  );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showEditDialog() {
    if (!outerContext.mounted) return;
    final ctrl = TextEditingController(text: message.text);
    showDialog(
      context: outerContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit message'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: ctrl,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Edit your message…'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ctrl.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newText = ctrl.text.trim();
              if (newText.isNotEmpty && newText != message.text) {
                onEdit(newText);
              }
              ctrl.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: c)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
