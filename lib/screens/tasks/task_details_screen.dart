import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/status_badge.dart';
import 'task_form_screen.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Detailed view for inspecting task metadata, timeline scheduling, and updating workflow status.
class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late DateTime _selectedDate;
  late Task _selectedTask;
  List<Task> _allTasks = [];
  bool _loading = true;
  Timer? _ticker;

  final List<Color> _cardColors = const [
    Color(0xFF60A5FA), // Blue
    Color(0xFF34D399), // Emerald
    Color(0xFFFB923C), // Amber/Orange
    Color(0xFFA78BFA), // Purple
    Color(0xFFF472B6), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _selectedTask = widget.task;
    _selectedDate = DateTime(widget.task.due.year, widget.task.due.month, widget.task.due.day);
    _loadAllTasks();

    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadAllTasks() async {
    try {
      final tasks = await StorageService.loadTasks();
      if (!mounted) return;
      setState(() {
        _allTasks = tasks;
        _loading = false;
        // Keep _selectedTask fresh from storage
        final match = tasks.where((t) => t.id == _selectedTask.id);
        if (match.isNotEmpty) {
          _selectedTask = match.first;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Task> get _tasksForSelectedDate {
    return _allTasks.where((t) {
      final d = t.due;
      return d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day;
    }).toList();
  }

  Future<void> _changeStatus(String newStatus) async {
    if (newStatus == _selectedTask.statusLabel) return;
    try {
      final updated = Task(
        id: _selectedTask.id,
        title: _selectedTask.title,
        description: _selectedTask.description,
        assignedTo: _selectedTask.assignedTo,
        dueDate: _selectedTask.dueDate,
        priority: _selectedTask.priority,
        status: newStatus,
        isCompleted: newStatus == 'Done',
        startTime: _selectedTask.startTime,
        endTime: _selectedTask.endTime,
      );
      await StorageService.updateTask(updated);
      final action = newStatus == 'Done' ? 'completed task' : 'marked as $newStatus';
      await StorageService.logActivity(
        action: action,
        targetTitle: updated.title,
        taskId: updated.id,
      );
      if (!mounted) return;
      setState(() => _selectedTask = updated);
      await _loadAllTasks();
      _toast('Status changed to $newStatus');
    } catch (_) {
      if (mounted) _toast('Status not saved. Try again.');
    }
  }

  Future<void> _editTask(Task taskToEdit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: taskToEdit)),
    );
    if (!mounted) return;
    await _loadAllTasks();
  }

  Future<void> _deleteTask(Task taskToDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${taskToDelete.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await StorageService.deleteTask(taskToDelete.id);
      await StorageService.logActivity(
        action: 'deleted task',
        targetTitle: taskToDelete.title,
      );
      if (!mounted) return;
      _toast('Task deleted');
      await _loadAllTasks();
      if (_selectedTask.id == taskToDelete.id) {
        if (_tasksForSelectedDate.isNotEmpty) {
          setState(() => _selectedTask = _tasksForSelectedDate.first);
        } else {
          if (mounted) Navigator.pop(context);
        }
      }
    } catch (_) {
      if (mounted) _toast('Could not delete task.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showTaskDetailsSheet(Task task) {
    setState(() => _selectedTask = task);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaskDetailModalSheet(
        task: _selectedTask,
        onStatusChanged: _changeStatus,
        onEdit: () {
          Navigator.pop(ctx);
          _editTask(_selectedTask);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteTask(_selectedTask);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _monthNames[_selectedDate.month - 1];
    final dayTasks = _tasksForSelectedDate;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Today Task',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22, color: Color(0xFF0F172A)),
            tooltip: 'Edit Current Task',
            onPressed: () => _editTask(_selectedTask),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Subtitle Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthName, ${_selectedDate.day}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dayTasks.length} task${dayTasks.length == 1 ? '' : 's'} today',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF6B60F5), size: 22),
                      ),
                    ],
                  ),
                ),

                // Horizontal Calendar Strip
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: 14, // 7 days before, 7 days after
                    itemBuilder: (context, index) {
                      final dayOffset = index - 3;
                      final date = DateTime.now().add(Duration(days: dayOffset));
                      final isSelected = date.year == _selectedDate.year &&
                          date.month == _selectedDate.month &&
                          date.day == _selectedDate.day;
                      final dayWeekday = _weekDays[date.weekday - 1];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(date.year, date.month, date.day);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 62,
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6B60F5) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6B60F5) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6B60F5).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dayWeekday,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Timeline View
                Expanded(
                  child: dayTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_available_rounded, size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'No tasks scheduled for this day',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                                  );
                                  _loadAllTasks();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Task'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B60F5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: 8, // hours from 9 am to 5 pm
                          itemBuilder: (context, hourIdx) {
                            final hour = 9 + hourIdx;
                            final hourLabel = hour > 12
                                ? '${hour - 12 < 10 ? '0' : ''}${hour - 12} pm'
                                : hour == 12
                                    ? '12 pm'
                                    : '${hour < 10 ? '0' : ''}$hour am';

                            // Tasks scheduled for this hour slot
                            final slotTasks = <Task>[];
                            for (var i = 0; i < dayTasks.length; i++) {
                              if (i % 8 == hourIdx || (dayTasks[i].startTime != null && dayTasks[i].startTime!.startsWith('${hour > 12 ? hour - 12 : hour}'))) {
                                slotTasks.add(dayTasks[i]);
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time label on left
                                  SizedBox(
                                    width: 58,
                                    child: Text(
                                      hourLabel,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),

                                  // Task Cards on right
                                  Expanded(
                                    child: slotTasks.isEmpty
                                        ? Container(
                                            height: 1,
                                            margin: const EdgeInsets.only(top: 10),
                                            color: const Color(0xFFE2E8F0),
                                          )
                                        : Column(
                                            children: slotTasks.map((t) {
                                              final cIdx = t.title.hashCode.abs() % _cardColors.length;
                                              final cardColor = _cardColors[cIdx];
                                              final isSelected = t.id == _selectedTask.id;

                                              return GestureDetector(
                                                onTap: () => _showTaskDetailsSheet(t),
                                                child: Container(
                                                  margin: const EdgeInsets.only(bottom: 10),
                                                  padding: const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(
                                                    color: cardColor,
                                                    borderRadius: BorderRadius.circular(18),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: cardColor.withValues(alpha: 0.3),
                                                        blurRadius: 10,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                    border: isSelected
                                                        ? Border.all(color: Colors.white, width: 2)
                                                        : null,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              t.title,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight: FontWeight.w700,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withValues(alpha: 0.25),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Text(
                                                              t.statusLabel,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              CircleAvatar(
                                                                radius: 12,
                                                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                                                child: Text(
                                                                  t.assigneeName.isNotEmpty
                                                                      ? t.assigneeName[0].toUpperCase()
                                                                      : 'U',
                                                                  style: const TextStyle(
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Text(
                                                                t.assigneeName,
                                                                style: TextStyle(
                                                                  color: Colors.white.withValues(alpha: 0.9),
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Text(
                                                            '${t.startTime ?? '09:30 am'} - ${t.endTime ?? '11:00 am'}',
                                                            style: TextStyle(
                                                              color: Colors.white.withValues(alpha: 0.85),
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// Modal Bottom Sheet that displays full task details, description, SLA status,
/// priority badge, and quick action buttons when tapped on the calendar!
class _TaskDetailModalSheet extends StatelessWidget {
  const _TaskDetailModalSheet({
    required this.task,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sla = task.sla;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Title & Edit Action
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF6B60F5)),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status & Priority Badges (Workflow Status, Priority, SLA Health)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                WorkflowStatusBadge(status: task.statusLabel),
                PriorityBadge(priority: task.priorityLabel),
                StatusBadge(status: sla.status),
              ],
            ),
            const SizedBox(height: 16),

            // Task Description
            const Text(
              'Description',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                task.details.isNotEmpty ? task.details : 'No description provided for this task.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),

            // Meta Info: Assignee, Due, Times
            Row(
              children: [
                Expanded(
                  child: _MetaItem(
                    label: 'Assignee',
                    value: task.assigneeName,
                    icon: Icons.person_outline,
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    label: 'Schedule',
                    value: '${task.startTime ?? '09:30 am'} - ${task.endTime ?? '11:00 am'}',
                    icon: Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SLA Explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sla.status.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sla.status.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(sla.status.icon, color: sla.status.color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sla.reason,
                      style: TextStyle(color: sla.status.color, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Quick Status Changer with workflow status colors
            const Text(
              'Change Status',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final s in ['To Do', 'In Progress', 'Done']) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () {
                          onStatusChanged(s);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: task.statusLabel == s
                              ? workflowStatusColor(s)
                              : Colors.white,
                          foregroundColor: task.statusLabel == s
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          side: BorderSide(
                            color: task.statusLabel == s
                                ? workflowStatusColor(s)
                                : const Color(0xFFE2E8F0),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}