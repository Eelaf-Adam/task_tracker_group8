import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/sla_service.dart';
import 'status_badge.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "16 Oct"
String _shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// One task in the list: priority dot + title, description, chips
/// (status, priority, assignee • due date) and the SLA badge and reason.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.sla,
    required this.onTap,
  });

  final Task task;
  final SlaResult sla;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final prio = priorityColor(task.priorityLabel);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: prio, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: sla.status, compact: true),
                ],
              ),
              if (task.details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontSize: 15, color: muted),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TaskChip(label: task.statusLabel),
                  TaskChip(
                    label: task.priorityLabel,
                    background: prio.withValues(alpha: 0.15),
                    foreground: prio,
                  ),
                  TaskChip(
                    label: '${task.assigneeName} • ${_shortDate(task.dueDate)}',
                    outlined: true,
                    foreground: const Color(0xFF3D3F4D),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sla.reason,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: sla.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}