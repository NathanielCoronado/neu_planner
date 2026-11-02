import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/store.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/task_tile.dart';
import 'subject_detail_screen.dart';
import 'task_form_screen.dart';

class TodayScreen extends StatelessWidget {
  /// Called when the overdue alert is tapped (opens Tasks filtered to Overdue).
  final VoidCallback onShowOverdue;
  const TodayScreen({super.key, required this.onShowOverdue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-task-today',
        onPressed: () => openTaskForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: ListenableBuilder(
        listenable: Store.changes,
        builder: (context, _) {
          final now = DateTime.now();
          final today = dateOnly(now);
          final tomorrow = today.add(const Duration(days: 1));
          final classes = Store.classesOn(now.weekday);
          final overdue = Store.overdue(now);
          final dueToday = Store.pendingBetween(now, tomorrow);
          final upcoming = Store.pendingBetween(
            tomorrow,
            today.add(const Duration(days: 8)),
          );

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              _Header(
                now: now,
                classCount: classes.length,
                dueCount: dueToday.length,
              ),
              if (overdue.isNotEmpty)
                _OverdueAlert(count: overdue.length, onTap: onShowOverdue),
              const SectionTitle('Classes today'),
              if (classes.isEmpty)
                const EmptyNote('No classes scheduled today.')
              else
                for (final s in classes) _ClassRow(subject: s, now: now),
              const SectionTitle('Due today'),
              if (dueToday.isEmpty)
                const EmptyNote('Nothing else due today.')
              else
                for (final t in dueToday) TaskTile(task: t),
              const SectionTitle('Next 7 days'),
              if (upcoming.isEmpty)
                const EmptyNote('No deadlines in the coming week.')
              else
                for (final t in upcoming) TaskTile(task: t),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime now;
  final int classCount;
  final int dueCount;
  const _Header({
    required this.now,
    required this.classCount,
    required this.dueCount,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 26),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE').format(now),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            DateFormat('MMMM d').format(now),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              height: 1.1,
              letterSpacing: -1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${classCount == 1 ? '1 class' : '$classCount classes'} '
            'and ${plural(dueCount, 'task')} due today',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _OverdueAlert extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _OverdueAlert({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$count overdue task${count == 1 ? '' : 's'}. Tap to review.',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.danger),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One class on today's timeline: time column, color rail, details.
class _ClassRow extends StatelessWidget {
  final Subject subject;
  final DateTime now;
  const _ClassRow({required this.subject, required this.now});

  @override
  Widget build(BuildContext context) {
    final minutesNow = now.hour * 60 + now.minute;
    final ongoing =
        minutesNow >= subject.startMinutes && minutesNow < subject.endMinutes;
    final finished = minutesNow >= subject.endMinutes;
    final color = Color(subject.colorValue);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubjectDetailScreen(subjectKey: subject.key as int),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeOfMinutes(subject.startMinutes),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      timeOfMinutes(subject.endMinutes),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: finished ? AppColors.line : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: finished ? AppColors.muted : AppColors.ink,
                      ),
                    ),
                    Text(
                      [
                        if (subject.code.isNotEmpty) subject.code,
                        if (subject.room.isNotEmpty) subject.room,
                      ].join(', '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (ongoing)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
