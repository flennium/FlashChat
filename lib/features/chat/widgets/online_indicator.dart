import 'package:flutter/material.dart';

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const CircleAvatar(radius: 5, backgroundColor: Color(0xFF10B981)),
      label: Text('$count'),
    );
  }
}
