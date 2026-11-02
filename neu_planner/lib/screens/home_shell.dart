import 'package:flutter/material.dart';

import '../data/store.dart';
import 'subjects_screen.dart';
import 'task_list_screen.dart';
import 'today_screen.dart';
import 'week_screen.dart';

/// Bottom navigation that holds the four main tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StatusFilter _taskFilter = StatusFilter.pending;
  int _taskListVersion = 0; // forces the Tasks tab to reset its filter

  void _openOverdue() => setState(() {
    _taskFilter = StatusFilter.overdue;
    _taskListVersion++;
    _index = 1;
  });

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(onShowOverdue: _openOverdue),
      TaskListScreen(
        key: ValueKey(_taskListVersion),
        initialStatus: _taskFilter,
      ),
      const SubjectsScreen(),
      const WeekScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: ListenableBuilder(
        listenable: Store.changes,
        builder: (context, _) {
          final overdue = Store.overdue(DateTime.now()).length;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() {
              if (i == 1 && _index != 1) {
                _taskFilter = StatusFilter.pending;
                _taskListVersion++;
              }
              _index = i;
            }),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined),
                selectedIcon: Icon(Icons.wb_sunny),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: overdue > 0,
                  label: Text('$overdue'),
                  child: const Icon(Icons.checklist_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: overdue > 0,
                  label: Text('$overdue'),
                  child: const Icon(Icons.checklist),
                ),
                label: 'Tasks',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Subjects',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_view_week_outlined),
                selectedIcon: Icon(Icons.calendar_view_week),
                label: 'Week',
              ),
            ],
          );
        },
      ),
    );
  }
}
