import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker_group8/services/sla_service.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);

  SlaResult run({
    required Duration createdAgo,
    required Duration dueIn,
    bool done = false,
    bool started = false,
    String priority = 'medium',
    DateTime? completedAt,
  }) =>
      SlaService.classify(
        createdAt: now.subtract(createdAgo),
        deadline: now.add(dueIn),
        isCompleted: done,
        isStarted: started,
        priority: priority,
        completedAt: completedAt,
        now: now,
      );

  test('done task is Completed even if past deadline', () {
    expect(
        run(createdAgo: const Duration(days: 5), dueIn: const Duration(days: -1), done: true)
            .status,
        SlaStatus.completed);
  });

  test('done without a completion time says "Marked as done"', () {
    final r = run(
        createdAgo: const Duration(days: 5), dueIn: const Duration(days: 1), done: true);
    expect(r.reason, 'Marked as done');
  });

  test('done after the deadline is reported as late', () {
    final r = run(
      createdAgo: const Duration(days: 5),
      dueIn: const Duration(days: -1),
      done: true,
      completedAt: now,
    );
    expect(r.reason, 'Completed after the deadline');
  });

  test('past deadline and not done is Overdue', () {
    expect(
        run(createdAgo: const Duration(days: 5), dueIn: const Duration(hours: -1)).status,
        SlaStatus.overdue);
  });

  test('high priority is At Risk with 40h left', () {
    expect(
        run(createdAgo: const Duration(days: 1), dueIn: const Duration(hours: 40),
                priority: 'high', started: true)
            .status,
        SlaStatus.atRisk);
  });

  test('low priority is On Track with 40h left', () {
    expect(
        run(createdAgo: const Duration(days: 1), dueIn: const Duration(hours: 40),
                priority: 'low', started: true)
            .status,
        SlaStatus.onTrack);
  });

  test('not started with 80% of time used is At Risk', () {
    expect(
        run(createdAgo: const Duration(days: 8), dueIn: const Duration(days: 2), priority: 'low')
            .status,
        SlaStatus.atRisk);
  });

  test('same task but started is On Track', () {
    expect(
        run(createdAgo: const Duration(days: 8), dueIn: const Duration(days: 2),
                priority: 'low', started: true)
            .status,
        SlaStatus.onTrack);
  });
}