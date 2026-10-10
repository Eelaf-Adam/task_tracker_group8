import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';

const _todoColor = Color(0xFFA9CE9B);
const _progressColor = Color(0xFFFFAA5B);
const _border = Color(0xFFDADCE5);

enum _Scope { allTime, thisMonth }

/// Task Status: donut chart of To Do / In Progress / Completed, the
/// completion percentage, and a card per status. "Needs attention" counts
/// tasks the SLA marks as Overdue or At Risk.
class TaskStatusScreen extends StatefulWidget {
  const TaskStatusScreen({super.key});

  @override
  State<TaskStatusScreen> createState() => _TaskStatusScreenState();
}

class _TaskStatusScreenState extends State<TaskStatusScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  _Scope _scope = _Scope.allTime;
  String _selected = 'Done';

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
    if (_scope == _Scope.allTime) return true;
    final now = DateTime.now();
    return t.dueDate.year == now.year && t.dueDate.month == now.month;
  }

  int _attention(List<Task> list) => list.where((t) {
        final s = t.sla.status;
        return s == SlaStatus.overdue || s == SlaStatus.atRisk;
      }).length;

  String _count(int n) => n == 1 ? '1 task' : '$n tasks';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final scoped = _tasks.where(_inScope).toList();
    List<Task> byStatus(String s) =>
        scoped.where((t) => t.statusLabel == s).toList();
    final todo = byStatus('To Do');
    final progress = byStatus('In Progress');
    final done = byStatus('Done');
    final total = scoped.length;
    final percent = total == 0 ? 0 : (done.length / total * 100).round();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _CircleButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
              )
            : null,
        title: const Text(
          'Task Status',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: PopupMenuButton<_Scope>(
              tooltip: 'Filter',
              onSelected: (s) => setState(() => _scope = s),
              itemBuilder: (_) => const [
                PopupMenuItem(value: _Scope.allTime, child: Text('All time')),
                PopupMenuItem(value: _Scope.thisMonth, child: Text('This month')),
              ],
              child: const _CircleButton(icon: Icons.tune),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    children: [
                      Center(
                        child: SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(240, 240),
                                painter: _DonutPainter([
                                  (value: todo.length.toDouble(), color: _todoColor),
                                  (value: progress.length.toDouble(), color: _progressColor),
                                  (value: done.length.toDouble(), color: scheme.primary),
                                ]),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$percent%',
                                    style: const TextStyle(
                                        fontSize: 40, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'Complete',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _LegendItem(color: _todoColor, label: 'To Do'),
                          const SizedBox(width: 20),
                          const _LegendItem(
                              color: _progressColor, label: 'In Progress'),
                          const SizedBox(width: 20),
                          _LegendItem(color: scheme.primary, label: 'Completed'),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _scope == _Scope.thisMonth ? 'This month' : 'All time',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      _StatusCard(
                        title: 'Completed',
                        subtitle: '${_count(done.length)} · $percent% of all tasks',
                        selected: _selected == 'Done',
                        onTap: () => setState(() => _selected = 'Done'),
                      ),
                      const SizedBox(height: 12),
                      _StatusCard(
                        title: 'In Progress',
                        subtitle:
                            '${_count(progress.length)} · ${_attention(progress)} need attention',
                        selected: _selected == 'In Progress',
                        onTap: () => setState(() => _selected = 'In Progress'),
                      ),
                      const SizedBox(height: 12),
                      _StatusCard(
                        title: 'To Do',
                        subtitle:
                            '${_count(todo.length)} · ${_attention(todo)} need attention',
                        selected: _selected == 'To Do',
                        onTap: () => setState(() => _selected = 'To Do'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 24),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: selected ? scheme.primary : _border),
    );
    return Material(
      color: Colors.white,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the donut: rounded segments with small gaps. One segment alone
/// becomes a full ring; no tasks gives a grey ring.
class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments);

  final List<({double value, Color color})> segments;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 30.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final active = segments.where((s) => s.value > 0).toList();
    final total = active.fold<double>(0, (sum, s) => sum + s.value);

    if (active.isEmpty) {
      paint.color = const Color(0xFFE6E8F0);
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }
    if (active.length == 1) {
      paint.color = active.first.color;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, paint);
      return;
    }

    paint.strokeCap = StrokeCap.round;
    final capAngle = (stroke / 2) / (rect.width / 2); // round cap adds length
    const gap = 0.10;
    var start = -math.pi / 2;
    for (final s in active) {
      final sweep = s.value / total * 2 * math.pi;
      final drawn = sweep - 2 * capAngle - gap;
      paint.color = s.color;
      if (drawn > 0) {
        canvas.drawArc(rect, start + capAngle + gap / 2, drawn, false, paint);
      } else {
        // Very small slice: show it as a dot.
        canvas.drawArc(rect, start + sweep / 2, 0.001, false, paint);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}