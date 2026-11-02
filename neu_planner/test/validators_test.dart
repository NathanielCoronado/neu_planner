import 'package:flutter_test/flutter_test.dart';
import 'package:neu_planner/models/subject.dart';
import 'package:neu_planner/utils/validators.dart';

void main() {
  final now = DateTime(2026, 11, 2, 10, 0);

  group('Task title', () {
    test('TC-01 empty title is rejected', () {
      expect(Validators.taskTitle(''), 'Enter a task title.');
      expect(Validators.taskTitle('   '), 'Enter a task title.');
    });
    test('TC-02 too short / too long', () {
      expect(Validators.taskTitle('ab'), isNotNull);
      expect(Validators.taskTitle('x' * 81), isNotNull);
    });
    test('TC-03 valid title passes', () {
      expect(Validators.taskTitle('Lab report 3'), isNull);
    });
  });

  group('Due date', () {
    test('TC-04 missing due date is rejected', () {
      expect(Validators.dueDate(null, now: now), isNotNull);
    });
    test('TC-05 past due date is rejected', () {
      expect(
        Validators.dueDate(DateTime(2026, 11, 1), now: now),
        'Due date and time can\'t be in the past.',
      );
    });
    test('TC-06 future due date passes', () {
      expect(
        Validators.dueDate(DateTime(2026, 11, 5, 23, 59), now: now),
        isNull,
      );
    });
    test('TC-07 more than a year ahead is rejected', () {
      expect(Validators.dueDate(DateTime(2028, 1, 1), now: now), isNotNull);
    });
    test('TC-08 unchanged past due date is allowed when editing', () {
      final old = DateTime(2026, 10, 30, 17);
      expect(Validators.dueDate(old, now: now, original: old), isNull);
    });
  });

  group('Subject', () {
    test('TC-09 empty and duplicate names are rejected', () {
      expect(Validators.subjectName('', existingNames: []), isNotNull);
      expect(
        Validators.subjectName('app dev', existingNames: ['App Dev']),
        isNotNull,
      );
      expect(
        Validators.subjectName('Networking', existingNames: ['App Dev']),
        isNull,
      );
    });
    test('TC-10 code allows only letters, numbers, spaces, hyphens', () {
      expect(Validators.subjectCode('IT-312'), isNull);
      expect(Validators.subjectCode('IT@312'), isNotNull);
    });
    test('TC-11 at least one class day is required', () {
      expect(Validators.scheduleDays([]), isNotNull);
      expect(Validators.scheduleDays([1, 3]), isNull);
    });
    test('TC-12 end time must be after start time', () {
      expect(Validators.scheduleTime(600, 540), isNotNull);
      expect(Validators.scheduleTime(600, 610), isNotNull); // < 30 min
      expect(Validators.scheduleTime(600, 690), isNull);
    });
    test('TC-13 overlapping schedules are detected', () {
      final existing = Subject(
        name: 'Networking',
        days: [1, 3],
        startMinutes: 600, // 10:00
        endMinutes: 690, // 11:30
        colorValue: 0xFF12357A,
      );
      final clash = Validators.findConflict(
        days: [3],
        start: 660,
        end: 750,
        others: [existing],
      );
      expect(clash?.name, 'Networking');
      final ok = Validators.findConflict(
        days: [2],
        start: 660,
        end: 750,
        others: [existing],
      );
      expect(ok, isNull);
      final backToBack = Validators.findConflict(
        days: [1],
        start: 690,
        end: 780,
        others: [existing],
      );
      expect(backToBack, isNull);
    });
  });
}
