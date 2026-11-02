import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  final StatusFilter initialStatus;
  const TaskListScreen({super.key, this.initialStatus = StatusFilter.pending});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late StatusFilter _status = widget.initialStatus;
  int? _subjectKey;
  TaskSort _sort = TaskSort.dueDate;
  final _search = TextEditingController();

  static const _statusLabels = {
    StatusFilter.pending: 'To do',
    StatusFilter.overdue: 'Overdue',
    StatusFilter.done: 'Done',
    StatusFilter.all: 'All',
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<TaskSort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: TaskSort.dueDate,
                child: Text('Sort by due date'),
              ),
              PopupMenuItem(
                value: TaskSort.priority,
                child: Text('Sort by priority'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-task-list',
        onPressed: () => openTaskForm(context, subjectKey: _subjectKey),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: ListenableBuilder(
        listenable: Store.changes,
        builder: (context, _) {
          final subjects = Store.allSubjects();
          if (_subjectKey != null && Store.subjectOf(_subjectKey!) == null) {
            _subjectKey = null;
          }
          final tasks = Store.query(
            status: _status,
            subjectKey: _subjectKey,
            search: _search.text,
            sort: _sort,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search titles and notes',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final entry in _statusLabels.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _status == entry.key,
                          selectedColor: entry.key == StatusFilter.overdue
                              ? AppColors.dangerSoft
                              : AppColors.goldSoft,
                          onSelected: (_) =>
                              setState(() => _status = entry.key),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: DropdownButtonFormField<int?>(
                  initialValue: _subjectKey,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All subjects'),
                    ),
                    for (final s in subjects)
                      DropdownMenuItem<int?>(
                        value: s.key as int,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _subjectKey = v),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _emptyMessage(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96, top: 4),
                        itemCount: tasks.length,
                        itemBuilder: (context, i) {
                          final t = tasks[i];
                          return Dismissible(
                            key: ObjectKey(t),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 28),
                              color: AppColors.danger,
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) async {
                              final messenger = ScaffoldMessenger.of(context);
                              final backup = await Store.deleteTask(t);
                              messenger
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('Deleted "${backup.title}"'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () => Store.addTask(backup),
                                    ),
                                  ),
                                );
                            },
                            child: TaskTile(task: t),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _emptyMessage() {
    if (Store.tasks.isEmpty) {
      return 'No tasks yet.\nTap "Add task" to log your first assignment.';
    }
    if (_search.text.isNotEmpty) return 'No tasks match "${_search.text}".';
    return switch (_status) {
      StatusFilter.overdue => 'Nothing overdue. Nice work.',
      StatusFilter.done => 'No finished tasks here yet.',
      StatusFilter.pending => 'Nothing left to do here.',
      StatusFilter.all => 'No tasks for this subject.',
    };
  }
}
