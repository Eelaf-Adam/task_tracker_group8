import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/sla_service.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// Card widget displaying task summary, assignee, workflow status, and SLA progress bar.
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

  double get _progressValue => task.progressFraction;

  Color get _progressBarColor {
    return switch (sla.status) {
      SlaStatus.completed => const Color(0xFF10B981),
      SlaStatus.onTrack => const Color(0xFF6B60F5),
      SlaStatus.atRisk => const Color(0xFFF59E0B),
      SlaStatus.overdue => const Color(0xFFEF4444),
    };
  }

  @override
  Widget build(BuildContext context) {
    final prio = priorityColor(task.priorityLabel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title and SLA Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: prio, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          if (task.details.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              task.details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(status: sla.status, compact: true),
                        const SizedBox(height: 4),
                        WorkflowStatusBadge(status: task.statusLabel, compact: true),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    minHeight: 4.5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: _progressBarColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom row: Assignee avatar & info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.primaryTint,
                          child: Text(
                            task.assigneeName.isNotEmpty
                                ? task.assigneeName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.assigneeName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: _progressBarColor),
                        const SizedBox(width: 4),
                        Text(
                          _shortDate(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _progressBarColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}