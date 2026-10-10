import 'package:flutter/material.dart';

import '../services/sla_service.dart';

/// Priority colours: High = red, Medium = amber, Low = green.
Color priorityColor(String label) => switch (label.toLowerCase()) {
      'high' => const Color(0xFFE5736B),
      'low' => const Color(0xFF4DB38A),
      _ => const Color(0xFFF5A623),
    };

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