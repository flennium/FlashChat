import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String messageTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  static String memberSince(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }

  static String relativeDay(DateTime dateTime) {
    final now = DateTime.now();
    final difference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dateTime.year, dateTime.month, dateTime.day))
        .inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dateTime);
  }
}
