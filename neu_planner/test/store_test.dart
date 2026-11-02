import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neu_planner/data/store.dart';
import 'package:neu_planner/models/subject.dart';
import 'package:neu_planner/models/task.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('planner_test');
    Hive.init(dir.path);
    await Store.openBoxes();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Future<int> addSubject() async {
    await Store.addSubject(
      Subject(
        name: 'App Dev',
        days: [1],
        startMinutes: 480,
        endMinutes: 600,
        colorValue: 0xFF12357A,
      ),
    );
    return Store.subjects.keys.first as int;
  }

  test('TC-14 tasks are saved and read back from Hive', () async {
    final key = await addSubject();
    await Store.addTask(
      Task(
        title: 'Final project',
        subjectKey: key,
        due: DateTime(2026, 12, 1, 17),
        priority: Priority.high,
      ),
    );
    await Hive.close();
    Hive.init(dir.path);
    await Store.openBoxes();
    final t = Store.tasks.values.single;
    expect(t.title, 'Final project');
    expect(t.priority, Priority.high);
    expect(t.due, DateTime(2026, 12, 1, 17));
  });

  test('TC-15 marking done and filtering by status', () async {
    final key = await addSubject();
    final now = DateTime(2026, 11, 2, 12);
    await Store.addTask(
      Task(title: 'Old quiz', subjectKey: key, due: DateTime(2026, 11, 1)),
    );
    await Store.addTask(
      Task(title: 'Essay', subjectKey: key, due: DateTime(2026, 11, 9)),
    );
    expect(Store.query(status: StatusFilter.overdue, now: now).length, 1);

    final essay = Store.tasks.values.firstWhere((t) => t.title == 'Essay');
    await Store.toggleDone(essay);
    expect(essay.completedAt, isNotNull);
    expect(
      Store.query(status: StatusFilter.done, now: now).single.title,
      'Essay',
    );
    expect(
      Store.query(status: StatusFilter.pending, now: now).single.title,
      'Old quiz',
    );
  });

  test('TC-16 search and priority sort', () async {
    final key = await addSubject();
    await Store.addTask(
      Task(
        title: 'Read chapter 4',
        subjectKey: key,
        due: DateTime(2026, 11, 3),
        priority: Priority.low,
      ),
    );
    await Store.addTask(
      Task(
        title: 'Lab exercise',
        subjectKey: key,
        due: DateTime(2026, 11, 10),
        priority: Priority.high,
      ),
    );
    expect(Store.query(search: 'chapter').single.title, 'Read chapter 4');
    expect(Store.query(sort: TaskSort.priority).first.title, 'Lab exercise');
  });

  test('TC-17 deleting a subject also deletes its tasks', () async {
    final key = await addSubject();
    await Store.addTask(
      Task(title: 'Essay', subjectKey: key, due: DateTime(2026, 11, 9)),
    );
    await Store.deleteSubject(Store.subjectOf(key)!);
    expect(Store.subjects.isEmpty, true);
    expect(Store.tasks.isEmpty, true);
  });
}
