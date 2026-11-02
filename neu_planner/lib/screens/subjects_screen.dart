import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'subject_detail_screen.dart';
import 'subject_form_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-subject',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubjectFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add subject'),
      ),
      body: ListenableBuilder(
        listenable: Store.changes,
        builder: (context, _) {
          final subjects = Store.allSubjects();
          if (subjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No subjects yet.\nAdd your classes and their schedules so you can file assignments under them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            itemCount: subjects.length,
            itemBuilder: (context, i) {
              final s = subjects[i];
              final tasks = Store.tasksForSubject(s.key as int);
              final pending = tasks.where((t) => !t.isDone).length;
              final color = Color(s.colorValue);
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SubjectDetailScreen(subjectKey: s.key as int),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 6, color: color),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (s.code.isNotEmpty)
                                    Text(
                                      s.code,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${daysLabel(s.days)}\n${timeRange(s.startMinutes, s.endMinutes)}'
                                    '${s.room.isNotEmpty ? ', ${s.room}' : ''}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$pending',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const Text(
                                  'to do',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
