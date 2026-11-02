import 'package:intl/intl.dart';

const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeek(DateTime d) =>
    dateOnly(d).subtract(Duration(days: d.weekday - DateTime.monday));

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayShort(int weekday) => _dayShort[weekday - 1];

String daysLabel(List<int> days) {
  final sorted = [...days]..sort();
  return sorted.map(dayShort).join(', ');
}

String timeOfMinutes(int minutes) =>
    DateFormat.jm().format(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

String timeRange(int start, int end) =>
    '${timeOfMinutes(start)} – ${timeOfMinutes(end)}';

String shortDate(DateTime d) => DateFormat('EEE, MMM d').format(d);

String clock(DateTime d) => DateFormat.jm().format(d);

/// Human wording for a due date relative to now.
String dueLabel(DateTime due, DateTime now, {bool done = false}) {
  final dayDiff = dateOnly(due).difference(dateOnly(now)).inDays;
  final time = clock(due);
  if (!done && due.isBefore(now)) {
    if (dayDiff == 0) return 'Overdue since $time today';
    if (dayDiff == -1) return 'Overdue since yesterday, $time';
    return 'Overdue since ${shortDate(due)}';
  }
  if (dayDiff == 0) return 'Due today, $time';
  if (dayDiff == 1) return 'Due tomorrow, $time';
  return 'Due ${shortDate(due)}, $time';
}
