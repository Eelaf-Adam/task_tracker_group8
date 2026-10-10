import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker_group8/models/task.dart';
import 'package:task_tracker_group8/services/sla_service.dart';

void main() {
  final createdAt = DateTime(2026, 10, 8, 9);

  Task makeTask({
    String? id,
    String status = 'To Do',
    String priority = 'Medium',
    String assignedTo = 'Diane',
    bool isCompleted = false,
    DateTime? dueDate,
  }) =>
      Task(
        id: id ?? createdAt.millisecondsSinceEpoch.toString(),
        title: 'Test task',
        description: 'Test description',
        assignedTo: assignedTo,
        dueDate: dueDate ?? DateTime(2026, 10, 10),
        priority: priority,
        status: status,
        isCompleted: isCompleted,
      );

  test('a task is due at the end of its due date', () {
    expect(makeTask().due, DateTime(2026, 10, 10, 23, 59, 59));
  });

  test('created time is read from the id', () {
    expect(makeTask().created, createdAt);
  });

  test('non-numeric id falls back to 7 days before the deadline', () {
    final t = makeTask(id: 'abc');
    expect(t.created, t.due.subtract(const Duration(days: 7)));
  });

  test('status helpers', () {
    expect(makeTask(status: 'To Do').isStarted, false);
    expect(makeTask(status: 'In Progress').isStarted, true);
    expect(makeTask(status: 'Done').isDone, true);
    expect(makeTask(isCompleted: true).isDone, true);
    expect(makeTask(status: 'In Progress').statusLabel, 'In Progress');
  });

  test('empty assignee shows Unassigned', () {
    expect(makeTask(assignedTo: '').assigneeName, 'Unassigned');
  });

  test('task due today is At Risk, not Overdue, at 10:00', () {
    final t = makeTask(priority: 'Medium');
    final r = SlaService.classify(
      createdAt: t.created,
      deadline: t.due,
      isCompleted: t.isDone,
      isStarted: t.isStarted,
      priority: 'medium',
      now: DateTime(2026, 10, 10, 10),
    );
    expect(r.status, SlaStatus.atRisk);
  });

  test('task due today is not Overdue at 00:01', () {
    final t = makeTask(priority: 'Low');
    final r = SlaService.classify(
      createdAt: t.created,
      deadline: t.due,
      isCompleted: t.isDone,
      isStarted: t.isStarted,
      priority: 'low',
      now: DateTime(2026, 10, 10, 0, 1),
    );
    expect(r.status, SlaStatus.onTrack);
  });
}