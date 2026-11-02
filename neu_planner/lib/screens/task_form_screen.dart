import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/validators.dart';
import 'subject_form_screen.dart';

/// Opens the add/edit task screen. If there are no subjects yet,
/// the student is asked to add one first (a task must belong to a subject).
Future<void> openTaskForm(
  BuildContext context, {
  Task? task,
  int? subjectKey,
}) async {
  if (Store.subjects.isEmpty) {
    final addNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a subject first'),
        content: const Text(
          'Every task belongs to a subject. Add one of your classes, then come back to add the task.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add subject'),
          ),
        ],
      ),
    );
    if (addNow == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubjectFormScreen()),
      );
    }
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TaskFormScreen(task: task, presetSubjectKey: subjectKey),
    ),
  );
}

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final int? presetSubjectKey;
  const TaskFormScreen({super.key, this.task, this.presetSubjectKey});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  int? _subjectKey;
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 23, minute: 59);
  Priority _priority = Priority.medium;
  bool _isDone = false;
  String? _dueError;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    if (t != null) {
      _subjectKey = t.subjectKey;
      _date = dateOnly(t.due);
      _time = TimeOfDay.fromDateTime(t.due);
      _priority = t.priority;
      _isDone = t.isDone;
    } else {
      _subjectKey = widget.presetSubjectKey;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime? get _due => _date == null
      ? null
      : DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time.hour,
          _time.minute,
        );

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final original = widget.task?.due;
    final first = (original != null && original.isBefore(today))
        ? dateOnly(original)
        : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: first,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Due date',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Due time',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final fieldsOk = _formKey.currentState!.validate();
    final dueError = Validators.dueDate(
      _due,
      now: DateTime.now(),
      original: widget.task?.due,
    );
    setState(() => _dueError = dueError);
    if (!fieldsOk || dueError != null) return;

    final messenger = ScaffoldMessenger.of(context);
    if (_editing) {
      final t = widget.task!;
      final wasDone = t.isDone;
      t
        ..title = _title.text.trim()
        ..notes = _notes.text.trim()
        ..subjectKey = _subjectKey!
        ..due = _due!
        ..priority = _priority
        ..isDone = _isDone;
      if (_isDone && !wasDone) t.completedAt = DateTime.now();
      if (!_isDone) t.completedAt = null;
      await t.save();
    } else {
      await Store.addTask(
        Task(
          title: _title.text.trim(),
          notes: _notes.text.trim(),
          subjectKey: _subjectKey!,
          due: _due!,
          priority: _priority,
        ),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(_editing ? 'Task updated' : 'Task added')),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text('"${widget.task!.title}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await Store.deleteTask(widget.task!);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Task deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final subjects = Store.allSubjects();
    // Guard against a preset key that no longer exists.
    if (_subjectKey != null && Store.subjectOf(_subjectKey!) == null) {
      _subjectKey = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit task' : 'Add task'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Delete task',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Lab report 3: Sorting algorithms',
              ),
              validator: Validators.taskTitle,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _subjectKey,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                for (final s in subjects)
                  DropdownMenuItem(
                    value: s.key as int,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: Color(s.colorValue),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _subjectKey = v),
              validator: Validators.subjectChoice,
            ),
            const SizedBox(height: 20),
            const Text(
              'Due',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _date == null ? 'Pick date' : shortDate(_date!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            if (_dueError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _dueError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.5,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Priority',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<Priority>(
              segments: [
                for (final p in Priority.values)
                  ButtonSegment(value: p, label: Text(p.label)),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notes,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Instructions, group mates, submission link…',
                alignLabelWithHint: true,
              ),
              validator: Validators.notes,
            ),
            if (_editing)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as done'),
                value: _isDone,
                onChanged: (v) => setState(() => _isDone = v),
              ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _save,
              child: Text(_editing ? 'Save changes' : 'Add task'),
            ),
          ],
        ),
      ),
    );
  }
}
