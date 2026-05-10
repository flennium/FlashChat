import 'package:flutter/material.dart';

/// Shows "@alice is typing…" with three animated bouncing dots.
/// Pass an empty [typingUsers] list to render nothing.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, required this.typingUsers});

  final List<String> typingUsers;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final names = widget.typingUsers;
    final label = names.length == 1
        ? '${names[0]} is typing'
        : names.length == 2
            ? '${names[0]} and ${names[1]} are typing'
            : '${names[0]} and ${names.length - 1} others are typing';

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
        child: Row(
          children: [
            _BouncingDots(controller: _ctrl),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        // Each dot is staggered by 0.15 of the cycle
        final anim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              i * 0.15,
              i * 0.15 + 0.55,
              curve: Curves.easeInOut,
            ),
          ),
        );
        return AnimatedBuilder(
          animation: anim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -5 * anim.value),
            child: Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4 + 0.6 * anim.value),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
