import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/mention_utils.dart';
import '../../../models/message_model.dart';
import '../../../models/room_model.dart';
import '../../../models/user_model.dart';
import '../controllers/chat_controller.dart';

class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({super.key, required this.room});

  final RoomModel room;

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _typingTimer;
  ActiveMentionQuery? _activeMention;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateMentionQuery);
    _focusNode.addListener(_updateMentionQuery);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final notEmpty = value.trim().isNotEmpty;
    ref.read(chatControllerProvider.notifier).setTyping(widget.room, notEmpty);
    _typingTimer?.cancel();
    if (notEmpty) {
      // Auto-cancel typing status after 3 s of inactivity
      _typingTimer = Timer(const Duration(seconds: 3), () {
        ref.read(chatControllerProvider.notifier).setTyping(widget.room, false);
      });
    }
  }

  void _updateMentionQuery() {
    final next = _focusNode.hasFocus
        ? MentionUtils.activeQueryAt(
            _controller.text,
            _controller.selection.baseOffset,
          )
        : null;
    if (next?.start != _activeMention?.start ||
        next?.end != _activeMention?.end ||
        next?.query != _activeMention?.query) {
      setState(() => _activeMention = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final replyMessage = ref.watch(replyMessageProvider(widget.room.id));
    final theme = Theme.of(context);
    final mentionQuery = _activeMention?.query;
    final suggestionsAsync = mentionQuery == null
        ? const AsyncValue<List<UserModel>>.data([])
        : ref.watch(mentionSuggestionsProvider(mentionQuery));
    final showSuggestions = mentionQuery != null;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview banner
          if (replyMessage != null)
            _ReplyPreview(
              message: replyMessage,
              onDismiss: () => ref
                  .read(replyMessageProvider(widget.room.id).notifier)
                  .state = null,
              theme: theme,
            ),
          if (showSuggestions)
            _MentionSuggestions(
              theme: theme,
              suggestionsAsync: suggestionsAsync,
              query: mentionQuery,
              onSelected: _insertMention,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: state.isLoading
                      ? null
                      : () => ref
                          .read(chatControllerProvider.notifier)
                          .sendImage(widget.room),
                  icon: const Icon(Icons.image_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autocorrect: false,
                    enableSuggestions: false,
                    minLines: 1,
                    maxLines: 4,
                    onChanged: _onTextChanged,
                    decoration:
                        const InputDecoration(hintText: 'Write a message'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: state.isLoading ? null : _send,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final replyMessage = ref.read(replyMessageProvider(widget.room.id));
    Map<String, dynamic>? replyTo;
    if (replyMessage != null) {
      final snippet = replyMessage.text.length > 80
          ? '${replyMessage.text.substring(0, 80)}…'
          : replyMessage.text;
      replyTo = {
        'id': replyMessage.id,
        'senderId': replyMessage.senderId,
        'senderName': replyMessage.senderName,
        'senderUsername': replyMessage.senderUsername,
        'text': snippet,
        'imageUrl': replyMessage.imageUrl,
      };
    }

    final ok = await ref
        .read(chatControllerProvider.notifier)
        .sendText(widget.room, text, replyTo: replyTo);

    if (ok) {
      _controller.clear();
      _updateMentionQuery();
      _typingTimer?.cancel();
      ref.read(chatControllerProvider.notifier).setTyping(widget.room, false);
      ref.read(replyMessageProvider(widget.room.id).notifier).state = null;
    }
  }

  void _insertMention(UserModel user) {
    final mention = _activeMention;
    if (mention == null) return;

    final before = _controller.text.substring(0, mention.start);
    final after = _controller.text.substring(mention.end);
    final replacement = '@${user.username} ';
    final nextText = '$before$replacement$after';
    final nextOffset = (before + replacement).length;

    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );

    _updateMentionQuery();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({
    required this.message,
    required this.onDismiss,
    required this.theme,
  });

  final MessageModel message;
  final VoidCallback onDismiss;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final displayName = message.senderName.isNotEmpty
        ? message.senderName
        : '@${message.senderUsername}';
    final snippet = message.isDeleted
        ? 'Message deleted'
        : message.imageUrl.isNotEmpty && message.text.isEmpty
            ? '📷 Photo'
            : message.text.length > 60
                ? '${message.text.substring(0, 60)}…'
                : message.text;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  snippet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MentionSuggestions extends StatelessWidget {
  const _MentionSuggestions({
    required this.theme,
    required this.suggestionsAsync,
    required this.query,
    required this.onSelected,
  });

  final ThemeData theme;
  final AsyncValue<List<UserModel>> suggestionsAsync;
  final String query;
  final ValueChanged<UserModel> onSelected;

  @override
  Widget build(BuildContext context) {
    final suggestions = suggestionsAsync.valueOrNull ?? const <UserModel>[];
    final showEmpty =
        !suggestionsAsync.isLoading && suggestions.isEmpty && query.isNotEmpty;
    if (!suggestionsAsync.isLoading && suggestions.isEmpty && !showEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: suggestionsAsync.when(
        data: (items) {
          final visibleItems = items.take(4).toList();
          if (visibleItems.isEmpty) {
            return ListTile(
              dense: true,
              title: Text(
                'No usernames found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: visibleItems.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final user = visibleItems[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  backgroundImage: user.avatarUrl.isNotEmpty
                      ? NetworkImage(user.avatarUrl)
                      : null,
                  child: user.avatarUrl.isEmpty
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  user.name.isNotEmpty ? user.name : user.username,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text('@${user.username}'),
                onTap: () => onSelected(user),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => ListTile(
          dense: true,
          title: Text(
            'Could not load usernames',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
