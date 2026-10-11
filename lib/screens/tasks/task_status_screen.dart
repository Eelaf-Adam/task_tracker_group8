import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/status_badge.dart';
import 'task_details_screen.dart';

const _todoColor = Color(0xFFA9CE9B);
const _progressColor = Color(0xFFFFAA5B);
const _completedColor = Color(0xFF6B60F5);

enum _Scope { today, thisMonth }

/// Displays completion rate donut chart, today's schedule, SLA breakdown, and status summaries.
class TaskStatusScreen extends StatefulWidget {
  const TaskStatusScreen({super.key});

  @override
  State<TaskStatusScreen> createState() => _TaskStatusScreenState();
}

class _TaskStatusScreenState extends State<TaskStatusScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  _Scope _scope = _Scope.thisMonth;
  String _selectedStatus = 'Done';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tasks = await StorageService.loadTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Statistics could not be loaded';
        _loading = false;
      });
    }
  }

  bool _inScope(Task t) {
    final now = DateTime.now();
    if (_scope == _Scope.today) {
      return t.due.year == now.year && t.due.month == now.month && t.due.day == now.day;
    }
    return t.dueDate.year == now.year && t.dueDate.month == now.month;
  }

  List<Task> get _todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      return t.due.year == now.year && t.due.month == now.month && t.due.day == now.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scoped = _tasks.where(_inScope).toList();
    final todoTasks = scoped.where((t) => t.statusLabel == 'To Do').toList();
    final inProgressTasks = scoped.where((t) => t.statusLabel == 'In Progress').toList();
    final doneTasks = scoped.where((t) => t.statusLabel == 'Done' || t.isDone).toList();

    final total = scoped.length;
    final percent = total == 0 ? 0 : ((doneTasks.length / total) * 100).round();

    // SLA breakdown
    final onTrackCount = scoped.where((t) => t.sla.status == SlaStatus.onTrack).length;
    final atRiskCount = scoped.where((t) => t.sla.status == SlaStatus.atRisk).length;
    final overdueCount = scoped.where((t) => t.sla.status == SlaStatus.overdue).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Task Status',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        actions: [
          PopupMenuButton<_Scope>(
            tooltip: 'Select Scope',
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A)),
            onSelected: (s) => setState(() => _scope = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Scope.thisMonth, child: Text('Monthly')),
              PopupMenuItem(value: _Scope.today, child: Text('Today')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
                    children: [
                      // Donut Chart Container
                      Center(
                        child: SizedBox(
                          width: 210,
                          height: 210,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(210, 210),
                                painter: _DonutChartPainter(
                                  todoValue: todoTasks.length.toDouble(),
                                  inProgressValue: inProgressTasks.length.toDouble(),
                                  doneValue: doneTasks.length.toDouble(),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$percent%',
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    _scope == _Scope.today ? 'Complete Today' : 'Complete',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Chart Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _LegendDot(color: _todoColor, label: 'To Do'),
                          SizedBox(width: 18),
                          _LegendDot(color: _progressColor, label: 'In Progress'),
                          SizedBox(width: 18),
                          _LegendDot(color: _completedColor, label: 'Completed'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 1. Today's Tasks Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today Tasks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${_todayTasks.length} task${_todayTasks.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_todayTasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'No tasks scheduled for today. Great job!',
                            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                          ),
                        )
                      else
                        for (final t in _todayTasks) ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: t)),
                              ).then((_) => _load());
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  PriorityBadge(
                                    priority: t.priorityLabel,
                                    compact: true,
                                    showSuffix: false,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${t.startTime ?? '09:30 am'} - ${t.endTime ?? '11:00 am'} • ${t.assigneeName}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusBadge(status: t.sla.status, compact: true),
                                      const SizedBox(height: 4),
                                      WorkflowStatusBadge(status: t.statusLabel, compact: true),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      const SizedBox(height: 26),

                      // 2. SLA Status Breakdown
                      const Text(
                        'SLA Status Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SlaMetricCard(
                              label: 'On Track',
                              count: onTrackCount,
                              color: const Color(0xFF10B981),
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SlaMetricCard(
                              label: 'At Risk',
                              count: atRiskCount,
                              color: const Color(0xFFF59E0B),
                              icon: Icons.warning_amber_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SlaMetricCard(
                              label: 'Overdue',
                              count: overdueCount,
                              color: const Color(0xFFEF4444),
                              icon: Icons.error_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // 3. Status Overview Section
                      Text(
                        _scope == _Scope.today ? 'Today Status Overview' : 'Monthly',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status Summary Cards
                      _StatusSummaryCard(
                        title: 'Completed',
                        subtitle: '${doneTasks.length} Task now • ${doneTasks.length} Task Completed',
                        isSelected: _selectedStatus == 'Done',
                        color: _completedColor,
                        onTap: () => setState(() => _selectedStatus = 'Done'),
                      ),
                      const SizedBox(height: 10),

                      _StatusSummaryCard(
                        title: 'In Progress',
                        subtitle: '${inProgressTasks.length} Task now • ${inProgressTasks.isNotEmpty ? '1' : '0'} started',
                        isSelected: _selectedStatus == 'In Progress',
                        color: _progressColor,
                        onTap: () => setState(() => _selectedStatus = 'In Progress'),
                      ),
                      const SizedBox(height: 10),

                      _StatusSummaryCard(
                        title: 'To Do',
                        subtitle: '${todoTasks.length} Task now • ${todoTasks.isNotEmpty ? '1' : '0'} Upcoming',
                        isSelected: _selectedStatus == 'To Do',
                        color: _todoColor,
                        onTap: () => setState(() => _selectedStatus = 'To Do'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlaMetricCard extends StatelessWidget {
  const _SlaMetricCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.todoValue,
    required this.inProgressValue,
    required this.doneValue,
  });

  final double todoValue;
  final double inProgressValue;
  final double doneValue;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 18.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = todoValue + inProgressValue + doneValue;
    if (total == 0) {
      final basePaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, basePaint);
      return;
    }

    final segments = [
      (value: todoValue, color: _todoColor),
      (value: inProgressValue, color: _progressColor),
      (value: doneValue, color: _completedColor),
    ];

    var startAngle = -math.pi / 2;
    const gap = 0.06; // gap between segments

    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweepAngle = (seg.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle + gap, sweepAngle - gap, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.todoValue != todoValue ||
      old.inProgressValue != inProgressValue ||
      old.doneValue != doneValue;
}