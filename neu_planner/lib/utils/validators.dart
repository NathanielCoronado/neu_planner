import '../models/subject.dart';

/// All input rules live here so they can be unit-tested without the UI.
/// Each method returns an error message, or null when the input is valid.
class Validators {
  static String? taskTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a task title.';
    if (v.length < 3) return 'Title must be at least 3 characters.';
    if (v.length > 80) return 'Title must be 80 characters or fewer.';
    return null;
  }

  static String? notes(String? value) {
    if ((value?.trim().length ?? 0) > 300) {
      return 'Notes must be 300 characters or fewer.';
    }
    return null;
  }

  static String? subjectChoice(int? key) =>
      key == null ? 'Choose a subject.' : null;

  /// New due dates must be in the future and within one year.
  /// When editing, an unchanged (possibly already past) due date is allowed.
  static String? dueDate(
    DateTime? due, {
    required DateTime now,
    DateTime? original,
  }) {
    if (due == null) return 'Pick a due date and time.';
    if (original != null && due.isAtSameMomentAs(original)) return null;
    if (!due.isAfter(now)) return 'Due date and time can\'t be in the past.';
    if (due.isAfter(now.add(const Duration(days: 366)))) {
      return 'Due date must be within one year from today.';
    }
    return null;
  }

  static String? subjectName(
    String? value, {
    required Iterable<String> existingNames,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a subject name.';
    if (v.length > 60) return 'Subject name must be 60 characters or fewer.';
    final taken = existingNames.any(
      (n) => n.trim().toLowerCase() == v.toLowerCase(),
    );
    if (taken) return 'You already have a subject named "$v".';
    return null;
  }

  static String? subjectCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > 12) return 'Code must be 12 characters or fewer.';
    if (v.isNotEmpty && !RegExp(r'^[A-Za-z0-9 \-]+$').hasMatch(v)) {
      return 'Use letters, numbers, spaces, or hyphens only.';
    }
    return null;
  }

  static String? room(String? value) {
    if ((value?.trim().length ?? 0) > 30) {
      return 'Room must be 30 characters or fewer.';
    }
    return null;
  }

  static String? scheduleDays(List<int> days) =>
      days.isEmpty ? 'Pick at least one class day.' : null;

  static String? scheduleTime(int? start, int? end) {
    if (start == null || end == null) return 'Set both start and end times.';
    if (end <= start) return 'End time must be after start time.';
    if (end - start < 30) return 'A class must be at least 30 minutes long.';
    return null;
  }

  /// Returns the first subject whose schedule overlaps the given one, if any.
  static Subject? findConflict({
    required List<int> days,
    required int start,
    required int end,
    required Iterable<Subject> others,
  }) {
    for (final s in others) {
      final sharesDay = s.days.any(days.contains);
      final overlaps = start < s.endMinutes && s.startMinutes < end;
      if (sharesDay && overlaps) return s;
    }
    return null;
  }
}
