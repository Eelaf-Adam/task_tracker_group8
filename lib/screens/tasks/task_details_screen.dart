import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/status_badge.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late Task _task = widget.task;
  bool _saving = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Keeps the "time left" text accurate while the screen is open.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Saves the new status. Mirrors the form: isCompleted == (status is Done).
  Future<void> _changeStatus(String newStatus) async {
    if (newStatus == _task.statusLabel) return;
    setState(() => _saving = true);
    try {
      final updated = Task(
        id: _task.id,
        title: _task.title,
        description: _task.description,
        assignedTo: _task.assignedTo,
        dueDate: _task.dueDate,
        priority: _task.priority,
        status: newStatus,
        isCompleted: newStatus == 'Done',
      );
      await StorageService.updateTask(updated);
      if (!mounted) return;
      setState(() => _task = updated);
      _toast('Status changed to $newStatus');
    } catch (_) {
      if (mounted) _toast('Status not saved. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Opens Member 2's form in edit mode. The form returns nothing, so reload
  /// the task from storage. If it is gone, it was deleted: close this too.
  Future<void> _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: _task)),
    );
    if (!mounted) return;
    try {
      final tasks = await StorageService.loadTasks();
      if (!mounted) return;
      final match = tasks.where((t) => t.id == _task.id);
      if (match.isEmpty) {
        Navigator.pop(context);
      } else {
        setState(() => _task = match.first);
      }
    } catch (_) {
      if (mounted) _toast('Could not refresh the task.');
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final prio = priorityColor(_task.priorityLabel);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Task Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _saving ? null : _edit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            _task.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: _task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TaskChip(label: _task.statusLabel),
              TaskChip(
                label: _task.priorityLabel,
                background: prio.withValues(alpha: 0.15),
                foreground: prio,
              ),
            ],
          ),
          if (_task.details.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _task.details,
              style: theme.textTheme.bodyLarge?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: 20),
          _SlaPanel(sla: _task.sla),
          const SizedBox(height: 16),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(Icons.person_outline, 'Assigned to', _task.assigneeName),
                const _RowDivider(),
                _InfoRow(Icons.event_outlined, 'Due', _task.dueLabel),
                const _RowDivider(),
                _InfoRow(Icons.schedule, 'Created', _task.createdLabel),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Update status',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _StatusSelector(
            current: _task.statusLabel,
            busy: _saving,
            onChanged: _changeStatus,
          ),
          if (_saving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Task'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Explains WHY the task has its SLA status.
class _SlaPanel extends StatelessWidget {
  const _SlaPanel({required this.sla});

  final SlaResult sla;

  @override
  Widget build(BuildContext context) {
    final color = sla.status.color;
    return _WhiteCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(sla.status.icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(status: sla.status),
                const SizedBox(height: 8),
                Text(sla.reason),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One-tap status change. Disabled while saving to prevent double taps.
class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.current,
    required this.onChanged,
    required this.busy,
  });

  final String current;
  final ValueChanged<String> onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        segments: [
          for (final s in kStatuses) ButtonSegment(value: s, label: Text(s)),
        ],
        selected: {current},
        showSelectedIcon: false,
        onSelectionChanged: busy ? null : (set) => onChanged(set.first),
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white,
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          side: const BorderSide(color: Color(0xFFDADCE5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 12),
          SizedBox(width: 96, child: Text(label, style: TextStyle(color: muted))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFEDEEF3));
}