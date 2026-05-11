import 'package:flutter/material.dart';

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: theme.colorScheme.outlineVariant,
      ),
      avatar: const CircleAvatar(
        radius: 5,
        backgroundColor: Color(0xFF10B981),
      ),
      label: Text(
        '$count',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
