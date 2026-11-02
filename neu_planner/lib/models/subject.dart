import 'package:hive/hive.dart';

/// A class the student is enrolled in, with its weekly meeting schedule.
class Subject extends HiveObject {
  String name;
  String code;
  String room;

  /// Days the class meets: DateTime.monday (1) ... DateTime.sunday (7).
  List<int> days;

  /// Start and end time stored as minutes after midnight (e.g. 10:30 AM = 630).
  int startMinutes;
  int endMinutes;

  /// ARGB color used to tag this subject across the app.
  int colorValue;

  Subject({
    required this.name,
    this.code = '',
    this.room = '',
    required this.days,
    required this.startMinutes,
    required this.endMinutes,
    required this.colorValue,
  });

  bool meetsOn(int weekday) => days.contains(weekday);
}

/// Hand-written Hive adapter (no code generation needed).
/// The field order in read() must match the order in write().
class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 0;

  @override
  Subject read(BinaryReader reader) {
    return Subject(
      name: reader.readString(),
      code: reader.readString(),
      room: reader.readString(),
      days: reader.readIntList(),
      startMinutes: reader.readInt(),
      endMinutes: reader.readInt(),
      colorValue: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer
      ..writeString(obj.name)
      ..writeString(obj.code)
      ..writeString(obj.room)
      ..writeIntList(obj.days)
      ..writeInt(obj.startMinutes)
      ..writeInt(obj.endMinutes)
      ..writeInt(obj.colorValue);
  }
}
