import 'package:hive/hive.dart';

enum Priority { low, medium, high }

extension PriorityLabel on Priority {
  String get label => switch (this) {
    Priority.low => 'Low',
    Priority.medium => 'Medium',
    Priority.high => 'High',
  };
}

/// An assignment, project, quiz, or any task tied to a subject.
class Task extends HiveObject {
  String title;
  String notes;

  /// Hive key of the Subject this task belongs to.
  int subjectKey;
  DateTime due;
  Priority priority;
  bool isDone;
  DateTime createdAt;
  DateTime? completedAt;

  Task({
    required this.title,
    this.notes = '',
    required this.subjectKey,
    required this.due,
    this.priority = Priority.medium,
    this.isDone = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool isOverdue(DateTime now) => !isDone && due.isBefore(now);

  /// A detached copy, used to restore a task after "Undo" on delete.
  Task copy() => Task(
    title: title,
    notes: notes,
    subjectKey: subjectKey,
    due: due,
    priority: priority,
    isDone: isDone,
    createdAt: createdAt,
    completedAt: completedAt,
  );
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    final title = reader.readString();
    final notes = reader.readString();
    final subjectKey = reader.readInt();
    final due = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final priority = Priority.values[reader.readInt()];
    final isDone = reader.readBool();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final completedMillis = reader.readInt();
    return Task(
      title: title,
      notes: notes,
      subjectKey: subjectKey,
      due: due,
      priority: priority,
      isDone: isDone,
      createdAt: createdAt,
      completedAt: completedMillis < 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(completedMillis),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeString(obj.title)
      ..writeString(obj.notes)
      ..writeInt(obj.subjectKey)
      ..writeInt(obj.due.millisecondsSinceEpoch)
      ..writeInt(obj.priority.index)
      ..writeBool(obj.isDone)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.completedAt?.millisecondsSinceEpoch ?? -1);
  }
}
