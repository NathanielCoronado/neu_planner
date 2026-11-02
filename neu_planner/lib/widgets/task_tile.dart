import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/task.dart';
import '../screens/task_form_screen.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// A task row: subject color stripe, checkbox, title, due wording, priority.
class TaskTile extends StatelessWidget {
  final Task task;
  final bool showSubject;
  const TaskTile({super.key, required this.task, this.showSubject = true});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final subject = Store.subjectOf(task.subjectKey);
    final subjectColor = subject != null
        ? Color(subject.colorValue)
        : AppColors.muted;
    final overdue = task.isOverdue(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: overdue ? AppColors.dangerSoft : Colors.white,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openTaskForm(context, task: task),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: subjectColor),
                Checkbox(
                  value: task.isDone,
                  activeColor: AppColors.success,
                  onChanged: (_) => Store.toggleDone(task),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: task.isDone
                                ? AppColors.muted
                                : AppColors.ink,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (showSubject && subject != null)
                          Text(
                            subject.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: subjectColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(
                          task.isDone
                              ? 'Completed'
                              : dueLabel(task.due, now, done: task.isDone),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: overdue
                                ? AppColors.danger
                                : (task.isDone
                                      ? AppColors.success
                                      : AppColors.muted),
                            fontWeight: overdue
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 8),
                  child: Center(child: PriorityTag(task.priority)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PriorityTag extends StatelessWidget {
  final Priority priority;
  const PriorityTag(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priority(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 11.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
