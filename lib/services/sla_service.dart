import 'package:flutter/material.dart';

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