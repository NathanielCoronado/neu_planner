import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/validators.dart';

class SubjectFormScreen extends StatefulWidget {
  final Subject? subject;
  const SubjectFormScreen({super.key, this.subject});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _room;
  final Set<int> _days = {};
  int? _start;
  int? _end;
  int _color = AppColors.subjectPalette.first;
  String? _scheduleError;

  bool get _editing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    final s = widget.subject;
    _name = TextEditingController(text: s?.name ?? '');
    _code = TextEditingController(text: s?.code ?? '');
    _room = TextEditingController(text: s?.room ?? '');
    if (s != null) {
      _days.addAll(s.days);
      _start = s.startMinutes;
      _end = s.endMinutes;
      _color = s.colorValue;
    } else {
      // Pick the first palette color not already used.
      final used = Store.subjects.values.map((e) => e.colorValue).toSet();
      _color = AppColors.subjectPalette.firstWhere(
        (c) => !used.contains(c),
        orElse: () => AppColors.subjectPalette.first,
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _room.dispose();
    super.dispose();
  }

  Iterable<Subject> get _others =>
      Store.subjects.values.where((s) => s.key != widget.subject?.key);

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _start : _end;
    final initial = current != null
        ? TimeOfDay(hour: current ~/ 60, minute: current % 60)
        : TimeOfDay(hour: isStart ? 7 : 8, minute: isStart ? 30 : 30);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Class starts' : 'Class ends',
    );
    if (picked == null) return;
    setState(() {
      final m = picked.hour * 60 + picked.minute;
      if (isStart) {
        _start = m;
      } else {
        _end = m;
      }
    });
  }

  String? _checkSchedule() {
    final days = _days.toList();
    final e =
        Validators.scheduleDays(days) ?? Validators.scheduleTime(_start, _end);
    if (e != null) return e;
    final clash = Validators.findConflict(
      days: days,
      start: _start!,
      end: _end!,
      others: _others,
    );
    if (clash != null) {
      return 'Overlaps with ${clash.name} '
          '(${daysLabel(clash.days)}, ${timeRange(clash.startMinutes, clash.endMinutes)}).';
    }
    return null;
  }

  Future<void> _save() async {
    final fieldsOk = _formKey.currentState!.validate();
    final scheduleError = _checkSchedule();
    setState(() => _scheduleError = scheduleError);
    if (!fieldsOk || scheduleError != null) return;

    final messenger = ScaffoldMessenger.of(context);
    final days = _days.toList()..sort();
    if (_editing) {
      final s = widget.subject!
        ..name = _name.text.trim()
        ..code = _code.text.trim().toUpperCase()
        ..room = _room.text.trim()
        ..days = days
        ..startMinutes = _start!
        ..endMinutes = _end!
        ..colorValue = _color;
      await s.save();
    } else {
      await Store.addSubject(
        Subject(
          name: _name.text.trim(),
          code: _code.text.trim().toUpperCase(),
          room: _room.text.trim(),
          days: days,
          startMinutes: _start!,
          endMinutes: _end!,
          colorValue: _color,
        ),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(_editing ? 'Subject updated' : 'Subject added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit subject' : 'Add subject')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Subject name',
                hintText: 'e.g. Application Development',
              ),
              validator: (v) => Validators.subjectName(
                v,
                existingNames: _others.map((s) => s.name),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      helperText: 'Optional',
                      hintText: 'IT 312',
                    ),
                    validator: Validators.subjectCode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _room,
                    decoration: const InputDecoration(
                      labelText: 'Room',
                      helperText: 'Optional',
                      hintText: 'CL 2',
                    ),
                    validator: Validators.room,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Class days',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  FilterChip(
                    label: Text(dayShort(d)),
                    selected: _days.contains(d),
                    selectedColor: AppColors.goldSoft,
                    onSelected: (on) =>
                        setState(() => on ? _days.add(d) : _days.remove(d)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.login),
                    label: Text(
                      _start == null ? 'Start time' : timeOfMinutes(_start!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.logout),
                    label: Text(
                      _end == null ? 'End time' : timeOfMinutes(_end!),
                    ),
                  ),
                ),
              ],
            ),
            if (_scheduleError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _scheduleError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.5,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            const Text(
              'Color',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in AppColors.subjectPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(c),
                      child: _color == c
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _save,
              child: Text(_editing ? 'Save changes' : 'Add subject'),
            ),
          ],
        ),
      ),
    );
  }
}
