import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../utils/format.dart';

enum StatusFilter { all, pending, done, overdue }

enum TaskSort { dueDate, priority }

/// Single place for every read and write to local storage (Hive).
class Store {
  static late Box<Subject> subjects;
  static late Box<Task> tasks;

  static Future<void> init() async {
    await Hive.initFlutter();
    await openBoxes();
  }

  /// Registers adapters and opens boxes. Tests call this after Hive.init(dir).
  static Future<void> openBoxes() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SubjectAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TaskAdapter());
    subjects = await Hive.openBox<Subject>('subjects');
    tasks = await Hive.openBox<Task>('tasks');
  }

  /// Fires whenever any subject or task changes, so screens rebuild.
  static Listenable get changes =>
      Listenable.merge([subjects.listenable(), tasks.listenable()]);

  // ---------- Subjects ----------

  static List<Subject> allSubjects() =>
      subjects.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  static Subject? subjectOf(int key) => subjects.get(key);

  static List<Subject> classesOn(int weekday) =>
      subjects.values.where((s) => s.meetsOn(weekday)).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  static Future<void> addSubject(Subject s) => subjects.add(s);

  /// Deletes a subject together with all of its tasks.
  static Future<void> deleteSubject(Subject s) async {
    final key = s.key as int;
    final related = tasks.values.where((t) => t.subjectKey == key).toList();
    for (final t in related) {
      await t.delete();
    }
    await s.delete();
  }

  // ---------- Tasks ----------

  static Future<void> addTask(Task t) => tasks.add(t);

  static Future<void> toggleDone(Task t) async {
    t.isDone = !t.isDone;
    t.completedAt = t.isDone ? DateTime.now() : null;
    await t.save();
  }

  /// Deletes a task and returns a copy that can be re-added for "Undo".
  static Future<Task> deleteTask(Task t) async {
    final backup = t.copy();
    await t.delete();
    return backup;
  }

  static List<Task> tasksForSubject(int subjectKey) =>
      _sortByDue(tasks.values.where((t) => t.subjectKey == subjectKey));

  static List<Task> overdue(DateTime now) =>
      _sortByDue(tasks.values.where((t) => t.isOverdue(now)));

  /// Unfinished tasks due in [from, to).
  static List<Task> pendingBetween(DateTime from, DateTime to) => _sortByDue(
    tasks.values.where(
      (t) => !t.isDone && !t.due.isBefore(from) && t.due.isBefore(to),
    ),
  );

  /// All tasks (done or not) due on a calendar day.
  static List<Task> dueOn(DateTime day) =>
      _sortByDue(tasks.values.where((t) => sameDay(t.due, day)));

  static List<Task> query({
    StatusFilter status = StatusFilter.all,
    int? subjectKey,
    String search = '',
    TaskSort sort = TaskSort.dueDate,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final term = search.trim().toLowerCase();
    final result = tasks.values.where((t) {
      final statusOk = switch (status) {
        StatusFilter.all => true,
        StatusFilter.pending => !t.isDone,
        StatusFilter.done => t.isDone,
        StatusFilter.overdue => t.isOverdue(at),
      };
      final subjectOk = subjectKey == null || t.subjectKey == subjectKey;
      final searchOk =
          term.isEmpty ||
          t.title.toLowerCase().contains(term) ||
          t.notes.toLowerCase().contains(term);
      return statusOk && subjectOk && searchOk;
    }).toList();

    if (sort == TaskSort.priority) {
      result.sort((a, b) {
        final p = b.priority.index.compareTo(a.priority.index);
        return p != 0 ? p : a.due.compareTo(b.due);
      });
    } else {
      result.sort((a, b) => a.due.compareTo(b.due));
    }
    return result;
  }

  static List<Task> _sortByDue(Iterable<Task> items) =>
      items.toList()..sort((a, b) => a.due.compareTo(b.due));
}
