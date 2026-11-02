import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/task_tile.dart';
import 'subject_form_screen.dart';
import 'task_form_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final int subjectKey;
  const SubjectDetailScreen({super.key, required this.subjectKey});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  bool _showDone = false;

  Future<void> _delete(Subject s) async {
    final count = Store.tasksForSubject(widget.subjectKey).length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${s.name}?'),
        content: Text(
          count == 0
              ? 'This subject has no tasks.'
              : 'Its $count task${count == 1 ? '' : 's'} will also be deleted. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete subject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    await Store.deleteSubject(s);
    messenger.showSnackBar(SnackBar(content: Text('${s.name} deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.changes,
      builder: (context, _) {
        final s = Store.subjectOf(widget.subjectKey);
        if (s == null) return const Scaffold();
        final color = Color(s.colorValue);
        final all = Store.tasksForSubject(widget.subjectKey);
        final done = all.where((t) => t.isDone).length;
        final shown = all.where((t) => t.isDone == _showDone).toList();
        final progress = all.isEmpty ? 0.0 : done / all.length;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            titleTextStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            title: Text(s.code.isNotEmpty ? s.code : 'Subject'),
            actions: [
              IconButton(
                tooltip: 'Edit subject',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectFormScreen(subject: s),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete subject',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(s),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'add-task-subject',
            onPressed: () =>
                openTaskForm(context, subjectKey: widget.subjectKey),
            icon: const Icon(Icons.add),
            label: const Text('Add task'),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Container(
                color: color,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoRow(Icons.calendar_today, daysLabel(s.days)),
                    _infoRow(
                      Icons.schedule,
                      timeRange(s.startMinutes, s.endMinutes),
                    ),
                    if (s.room.isNotEmpty)
                      _infoRow(Icons.room_outlined, s.room),
                    const SizedBox(height: 18),
                    Text(
                      all.isEmpty
                          ? 'No tasks yet'
                          : '$done of ${all.length} tasks done',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text('To do (${all.length - done})'),
                    ),
                    ButtonSegment(value: true, label: Text('Done ($done)')),
                  ],
                  selected: {_showDone},
                  onSelectionChanged: (v) =>
                      setState(() => _showDone = v.first),
                ),
              ),
              if (shown.isEmpty)
                EmptyNote(
                  _showDone
                      ? 'Nothing finished yet.'
                      : 'You\'re all caught up in this subject.',
                ),
              for (final t in shown) TaskTile(task: t, showSubject: false),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
