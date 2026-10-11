import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker_group8/models/task.dart';
import 'package:task_tracker_group8/screens/tasks/task_details_screen.dart';
import 'package:task_tracker_group8/screens/tasks/task_status_screen.dart';
import 'package:task_tracker_group8/services/sla_service.dart';
import 'package:task_tracker_group8/services/storage_service.dart';
import 'package:task_tracker_group8/widgets/status_badge.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task Status & Priority Consistency Tests', () {
    testWidgets('TaskStatusScreen shows Monthly and Today in scope selector', (tester) async {
      final now = DateTime.now();
      final task1 = Task(
        id: '101',
        title: 'Review UI Architecture',
        description: 'Verify badge logic flow',
        assignedTo: 'Sarah Lee',
        dueDate: now,
        priority: 'High',
        status: 'In Progress',
        isCompleted: false,
        startTime: '10:00 am',
        endTime: '11:30 am',
      );
      await StorageService.addTask(task1);

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskStatusScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open the scope popup menu
      final scopeButton = find.byTooltip('Select Scope');
      expect(scopeButton, findsOneWidget);
      await tester.tap(scopeButton);
      await tester.pumpAndSettle();

      // Verify ONLY Monthly and Today are present in the menu
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('All time'), findsNothing);

      // Dismiss menu
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
    });

    testWidgets('TaskStatusScreen order: Today Tasks is above SLA, Monthly is after SLA', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final task = Task(
        id: '102',
        title: 'Design Flow Inspection',
        description: 'Confirm section ordering',
        assignedTo: 'David Kim',
        dueDate: now,
        priority: 'Medium',
        status: 'To Do',
        isCompleted: false,
        startTime: '01:00 pm',
        endTime: '02:30 pm',
      );
      await StorageService.addTask(task);

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskStatusScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the position of Today Tasks, SLA Status Metrics, and Monthly/Today Overview
      final todayFinder = find.text('Today Tasks');
      final slaFinder = find.text('SLA Status Metrics');
      final monthlyFinder = find.text('Monthly');

      expect(todayFinder, findsOneWidget);
      expect(slaFinder, findsOneWidget);
      expect(monthlyFinder, findsOneWidget);

      final todayY = tester.getTopLeft(todayFinder).dy;
      final slaY = tester.getTopLeft(slaFinder).dy;
      final monthlyY = tester.getTopLeft(monthlyFinder).dy;

      // Assert that Today Tasks is above SLA, and Monthly is below SLA!
      expect(todayY, lessThan(slaY), reason: 'Today Tasks must appear before SLA Status Metrics');
      expect(slaY, lessThan(monthlyY), reason: 'SLA Status Metrics must appear before Monthly overview');

      // Verify badges rendered in Today task list
      expect(find.byType(PriorityBadge), findsWidgets);
      expect(find.byType(WorkflowStatusBadge), findsWidgets);
      expect(find.byType(StatusBadge), findsWidgets);
    });

    testWidgets('TaskDetailsScreen displays WorkflowStatusBadge, PriorityBadge, and StatusBadge together', (tester) async {
      final now = DateTime.now();
      final task = Task(
        id: '103',
        title: 'Component Review',
        description: 'Check combined badge presentation',
        assignedTo: 'Anna Chen',
        dueDate: now,
        priority: 'High',
        status: 'In Progress',
        isCompleted: false,
        startTime: '09:00 am',
        endTime: '10:30 am',
      );
      await StorageService.addTask(task);

      await tester.pumpWidget(
        MaterialApp(
          home: TaskDetailsScreen(task: task),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the task timeline item to show modal sheet
      final card = find.text('Component Review');
      expect(card, findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Verify badges in modal sheet
      expect(find.text('In Progress'), findsWidgets); // WorkflowStatusBadge + Change Status button
      expect(find.text('High Priority'), findsOneWidget); // PriorityBadge
      expect(find.text(task.sla.status.label), findsWidgets); // StatusBadge
    });
  });
}
