import 'package:flutter/material.dart';

import '../models/task.dart';

/// The four SLA states required by the brief.
enum SlaStatus { onTrack, atRisk, overdue, completed }

/// Result of classifying a task: the status plus a human-readable reason.
class SlaResult {
  final SlaStatus status;
  final String reason;
  const SlaResult(this.status, this.reason);
}

/// SLA rules (evaluated in this order):
/// 1. Completed: the task is marked Done.
/// 2. Overdue: not done and the deadline has passed.
/// 3. At Risk (time left): remaining time is inside the priority's risk window
///    (High = 48h, Medium = 24h, Low = 12h).
/// 4. At Risk (not started): 75% or more of the time between creation and
///    deadline has passed and the task is still "To Do".
/// 5. On Track: none of the above.
class SlaService {
  static const Map<String, Duration> riskWindows = {
    'high': Duration(hours: 48),
    'medium': Duration(hours: 24),
    'low': Duration(hours: 12),
  };
  static const double notStartedThreshold = 0.75;

  /// [now] is injectable so the rules can be unit-tested.
  static SlaResult classify({
    required DateTime createdAt,
    required DateTime deadline,
    required bool isCompleted,
    required bool isStarted,
    required String priority,
    DateTime? completedAt,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    if (isCompleted) {
      // Without a completion time we cannot claim "on time".
      if (completedAt == null) {
        return const SlaResult(SlaStatus.completed, 'Marked as done');
      }
      final late = completedAt.isAfter(deadline);
      return SlaResult(SlaStatus.completed,
          late ? 'Completed after the deadline' : 'Completed on time');
    }

    if (current.isAfter(deadline)) {
      return SlaResult(SlaStatus.overdue,
          'Deadline passed ${_fmt(current.difference(deadline))} ago');
    }

    final remaining = deadline.difference(current);
    final window =
        riskWindows[priority.toLowerCase()] ?? const Duration(hours: 24);
    if (remaining <= window) {
      return SlaResult(SlaStatus.atRisk,
          'Only ${_fmt(remaining)} left for a $priority-priority task');
    }

    final total = deadline.difference(createdAt);
    if (!isStarted && total.inSeconds > 0) {
      final used = current.difference(createdAt).inSeconds / total.inSeconds;
      if (used >= notStartedThreshold) {
        return SlaResult(SlaStatus.atRisk,
            '${(used * 100).round()}% of the time used and not started yet');
      }
    }

    return SlaResult(SlaStatus.onTrack, '${_fmt(remaining)} remaining');
  }

  /// Lower rank = more urgent. Used to sort the Task List.
  static int urgencyRank(SlaStatus s) => switch (s) {
        SlaStatus.overdue => 0,
        SlaStatus.atRisk => 1,
        SlaStatus.onTrack => 2,
        SlaStatus.completed => 3,
      };

  static String _fmt(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}

/// UI helpers so every screen shows the same label, colour and icon.
extension SlaStatusUi on SlaStatus {
  String get label => switch (this) {
        SlaStatus.onTrack => 'On Track',
        SlaStatus.atRisk => 'At Risk',
        SlaStatus.overdue => 'Overdue',
        SlaStatus.completed => 'Completed',
      };

  Color get color => switch (this) {
        SlaStatus.onTrack => Colors.green,
        SlaStatus.atRisk => Colors.orange,
        SlaStatus.overdue => Colors.red,
        SlaStatus.completed => Colors.blueGrey,
      };

  IconData get icon => switch (this) {
        SlaStatus.onTrack => Icons.check_circle_outline,
        SlaStatus.atRisk => Icons.warning_amber_rounded,
        SlaStatus.overdue => Icons.error_outline,
        SlaStatus.completed => Icons.task_alt,
      };
}


// ---------------------------------------------------------------------------
// Task helpers used by the Task List, Task Details and task widgets.
// ---------------------------------------------------------------------------

/// Status options. Must match the Status dropdown on the Edit Task form.
const List<String> kStatuses = ['To Do', 'In Progress', 'Done'];

extension TaskSla on Task {
  // Field mapping: the ONLY place that adapts the Task model to the SLA logic.

  /// The date picker has no time, so a task is due at the END of its due date.
  DateTime get due =>
      DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);

  /// Task has no createdAt field, but Create Task uses the creation time in
  /// milliseconds as the id. Falls back to 7 days before the deadline.
  DateTime get created {
    final ms = int.tryParse(id);
    if (ms == null) return due.subtract(const Duration(days: 7));
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Task has no completedAt field.
  DateTime? get finished => null;

  String get assigneeName => assignedTo.isEmpty ? 'Unassigned' : assignedTo;
  String get details => description;

  String get _statusKey => _normalise(status);
  bool get isDone => isCompleted || _statusKey == 'done';
  bool get isStarted => _statusKey != 'todo';

  String get statusLabel => switch (_statusKey) {
        'inprogress' => 'In Progress',
        'done' || 'completed' => 'Done',
        _ => 'To Do',
      };

  String get priorityLabel {
    final p = _normalise(priority);
    return p.isEmpty ? 'Medium' : p[0].toUpperCase() + p.substring(1);
  }

  String get dueLabel => formatDate(dueDate);
  String get createdLabel => formatDateTime(created);
  String? get finishedLabel => finished == null ? null : formatDateTime(finished!);

  SlaResult get sla => SlaService.classify(
        createdAt: created,
        deadline: due,
        isCompleted: isDone,
        isStarted: isStarted,
        priority: _normalise(priority),
        completedAt: finished,
      );
}

/// Works for Strings ("In Progress") and enums (TaskStatus.inProgress).
String _normalise(Object? value) => value
    .toString()
    .split('.')
    .last
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z]'), '');

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Thu, 8 Oct 2026": no day/month ambiguity.
String formatDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

/// "8 Oct 2026, 14:05"
String formatDateTime(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}, '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';