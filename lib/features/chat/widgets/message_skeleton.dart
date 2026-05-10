import 'package:flutter/material.dart';

/// Shimmer-style placeholder shown while messages are loading.
class MessageSkeleton extends StatefulWidget {
  const MessageSkeleton({super.key});

  @override
  State<MessageSkeleton> createState() => _MessageSkeletonState();
}

class _MessageSkeletonState extends State<MessageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _widths = [200.0, 150.0, 240.0, 130.0, 210.0, 160.0];
  static const _isLeft = [true, false, true, true, false, true];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = base.withValues(alpha: _anim.value);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: _widths.length,
          itemBuilder: (_, i) => _SkeletonBubble(
            isLeft: _isLeft[i],
            width: _widths[i],
            color: color,
          ),
        );
      },
    );
  }
}

class _SkeletonBubble extends StatelessWidget {
  const _SkeletonBubble({
    required this.isLeft,
    required this.width,
    required this.color,
  });

  final bool isLeft;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isLeft) ...[
            // Avatar placeholder
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Align(
              alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: width,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isLeft ? 4 : 18),
                    bottomRight: Radius.circular(isLeft ? 18 : 4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
