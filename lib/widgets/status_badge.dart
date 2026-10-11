import 'package:flutter/material.dart';

import '../services/sla_service.dart';

/// Priority colours: High = red, Medium = amber, Low = green.
Color priorityColor(String label) => switch (label.toLowerCase()) {
      'high' => const Color(0xFFEF4444),
      'low' => const Color(0xFF10B981),
      _ => const Color(0xFFF59E0B),
    };

/// Workflow status colors: To Do = sage green, In Progress = soft orange, Done = brand purple.
Color workflowStatusColor(String status) => switch (status.toLowerCase()) {
      'done' || 'completed' => const Color(0xFF6B60F5),
      'in progress' || 'inprogress' => const Color(0xFFFFAA5B),
      _ => const Color(0xFFA9CE9B),
    };

/// Pill showing the task's workflow status (To Do / In Progress / Done).
class WorkflowStatusBadge extends StatelessWidget {
  const WorkflowStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = workflowStatusColor(status);
    final icon = switch (status.toLowerCase()) {
      'done' || 'completed' => Icons.check_circle_rounded,
      'in progress' || 'inprogress' => Icons.timelapse_rounded,
      _ => Icons.radio_button_unchecked_rounded,
    };

    return Semantics(
      label: 'Workflow status: $status',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 12 : 14, color: color),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill showing task priority (High = red, Medium = amber, Low = green).
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
    this.showSuffix = true,
  });

  final String priority;
  final bool compact;
  final bool showSuffix;

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    final label = showSuffix ? '$priority Priority' : priority;

    return Semantics(
      label: 'Priority: $priority',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 11,
          vertical: compact ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small rounded label used on task cards and the details screen.
/// Default look = grey status chip; pass colours for priority chips,
/// or [outlined] for the "Assignee • date" chip.
class TaskChip extends StatelessWidget {
  const TaskChip({
    super.key,
    required this.label,
    this.background = const Color(0xFFEDEEF6),
    this.foreground = const Color(0xFF6B7194),
    this.outlined = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : background,
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: const Color(0xFFDADCE5)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Coloured pill showing a task's SLA status (On Track / At Risk / Overdue /
/// Completed). Used on task cards and in the Task Details header.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final SlaStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Semantics(
      label: 'SLA status: ${status.label}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: compact ? 14 : 16, color: color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}