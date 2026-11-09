import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// "Just now", "5 min ago", "2 hours ago", "3 days ago", then a date.
  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays < 7) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    }
    return DateFormat('d MMM yyyy').format(time);
  }

  /// "Oct 15, 2026 at 10:24 AM"
  static String dateTime(DateTime time) =>
      DateFormat("MMM d, yyyy 'at' h:mm a").format(time);

  /// "Oct 15, 10:24 AM"
  static String shortDateTime(DateTime time) => DateFormat('MMM d, h:mm a').format(time);

  /// "Amina Hassan" -> "AH"
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// "Amina Hassan" -> "Amina"
  static String firstName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '' : trimmed.split(RegExp(r'\s+')).first;
  }
}
