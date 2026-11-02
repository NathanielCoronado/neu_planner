import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/task_tile.dart';

/// Weekly calendar and summary: classes and deadlines for each day.
class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  DateTime _weekStart = startOfWeek(DateTime.now());

  void _shift(int weeks) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final isThisWeek = sameDay(_weekStart, startOfWeek(DateTime.now()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Week'),
        actions: [
          if (!isThisWeek)
            TextButton(
              onPressed: () =>
                  setState(() => _weekStart = startOfWeek(DateTime.now())),
              child: const Text('This week'),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Store.changes,
        builder: (context, _) {
          final now = DateTime.now();
          final weekTasks = Store.tasks.values
              .where(
                (t) =>
                    !t.due.isBefore(_weekStart) &&
                    t.due.isBefore(weekEnd.add(const Duration(days: 1))),
              )
              .toList();
          final done = weekTasks.where((t) => t.isDone).length;
          final overdue = weekTasks.where((t) => t.isOverdue(now)).length;
          final percent = weekTasks.isEmpty
              ? 0
              : (done * 100 / weekTasks.length).round();

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous week',
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${DateFormat('MMM d').format(_weekStart)} – ${DateFormat('MMM d').format(weekEnd)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next week',
                      onPressed: () => _shift(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _Stat(value: '${weekTasks.length}', label: 'Due'),
                    _Stat(value: '$done', label: 'Done'),
                    _Stat(
                      value: '$overdue',
                      label: 'Overdue',
                      color: overdue > 0 ? AppColors.danger : null,
                    ),
                    _Stat(value: '$percent%', label: 'Complete'),
                  ],
                ),
              ),
              for (var i = 0; i < 7; i++)
                _DaySection(
                  day: _weekStart.add(Duration(days: i)),
                  now: now,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const _Stat({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color ?? AppColors.navy,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final DateTime now;
  const _DaySection({required this.day, required this.now});

  @override
  Widget build(BuildContext context) {
    final isToday = sameDay(day, now);
    final classes = Store.classesOn(day.weekday);
    final tasks = Store.dueOn(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE').format(day),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isToday ? AppColors.navy : AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM d').format(day),
                style: const TextStyle(color: AppColors.muted),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (classes.isEmpty && tasks.isEmpty) const EmptyNote('Free day'),
        if (classes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in classes)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Color(s.colorValue).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${timeOfMinutes(s.startMinutes)}  ${s.code.isNotEmpty ? s.code : s.name}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(s.colorValue),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        for (final t in tasks) TaskTile(task: t),
      ],
    );
  }
}
