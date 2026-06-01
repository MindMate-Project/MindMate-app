import 'package:intl/intl.dart';

abstract final class ReminderFormatters {
  static String time12(DateTime time) => DateFormat('hh:mm a').format(time);

  static String dayMonth(DateTime date) => DateFormat('d MMMM').format(date);

  static String dayMonthYear(DateTime date) =>
      DateFormat('d MMMM yyyy').format(date);

  static String listDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd-$mm-${date.year}';
  }

  static String displayLabel(String? value) {
    if (value == null || value.trim().isEmpty) return '—';
    return value
        .split(RegExp(r'[-_\s]+'))
        .where((p) => p.isNotEmpty)
        .map(
          (p) => p.length == 1
              ? p.toUpperCase()
              : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String doctorName(String? name) {
    final n = name?.trim();
    if (n == null || n.isEmpty) return 'Unknown doctor';
    if (n.toLowerCase().startsWith('dr')) return n;
    return 'Dr. $n';
  }
}
