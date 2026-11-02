import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neu_planner/data/store.dart';
import 'package:neu_planner/main.dart';
import 'package:neu_planner/models/subject.dart';
import 'package:neu_planner/models/task.dart';

void main() {
  testWidgets('TC-18 all screens open and show saved data', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    final now = DateTime.now();
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('smoke');
      Hive.init(dir.path);
      await Store.openBoxes();
      await Store.addSubject(
        Subject(
          name: 'Application Development',
          code: 'IT 312',
          room: 'CL 2',
          days: [now.weekday],
          startMinutes: 0,
          endMinutes: 1439,
          colorValue: 0xFF12357A,
        ),
      );
      final key = Store.subjects.keys.first as int;
      await Store.addTask(
        Task(
          title: 'Wireframes in Figma',
          subjectKey: key,
          due: now.add(const Duration(hours: 3)),
          priority: Priority.high,
        ),
      );
      await Store.addTask(
        Task(
          title: 'Late quiz reviewer',
          subjectKey: key,
          due: now.subtract(const Duration(days: 1)),
        ),
      );
    });

    await tester.pumpWidget(const PlannerApp());
    await tester.pumpAndSettle();
    expect(find.text('Application Development'), findsWidgets);
    expect(find.textContaining('overdue task'), findsOneWidget);

    await tester.tap(find.textContaining('overdue task'));
    await tester.pumpAndSettle();
    expect(find.text('Late quiz reviewer'), findsOneWidget);

    await tester.tap(find.text('Subjects'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Application Development'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tasks done'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('Complete'), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a task title.'), findsOneWidget);
    expect(find.text('Choose a subject.'), findsOneWidget);
    expect(find.text('Pick a due date and time.'), findsOneWidget);

    await tester.runAsync(() async {
      await Hive.deleteFromDisk();
    });
    tester.view.reset();
  });
}
