import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../team/team_members_screen.dart';

/// Form screen for creating and editing tasks with validation, date picking, and member assignment.
class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final String? initialAssignee;

  const TaskFormScreen({super.key, this.task, this.initialAssignee});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatFullDate(DateTime d) =>
    '${_monthNames[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late String _assignedTo;
  DateTime? _dueDate;
  String _startTime = '9:30 am';
  String _endTime = '3:30 pm';
  late String _priority;
  late String _status;
  List<TeamMember> _memberList = [];
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _assignedTo = task?.assignedTo.isNotEmpty == true
        ? task!.assignedTo
        : (widget.initialAssignee?.trim().isNotEmpty == true
            ? widget.initialAssignee!.trim()
            : (members.isNotEmpty ? members.first.name : 'Team Member'));
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 3));
    _startTime = task?.startTime ?? '9:30 am';
    _endTime = task?.endTime ?? '3:30 pm';
    _priority = task?.priority ?? 'Medium';
    _status = task?.status ?? 'To Do';
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final list = await StorageService.loadMembers();
    if (mounted) {
      setState(() {
        _memberList = list;
        if ((_assignedTo.isEmpty || _assignedTo == 'Team Member') && list.isNotEmpty) {
          _assignedTo = widget.initialAssignee?.trim().isNotEmpty == true
              ? widget.initialAssignee!.trim()
              : list.first.name;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: _isEditing ? DateTime(2020) : today,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 9, minute: 30)
          : const TimeOfDay(hour: 15, minute: 30),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'am' : 'pm';
      setState(() {
        if (isStart) {
          _startTime = '$hour:$minute $period';
        } else {
          _endTime = '$hour:$minute $period';
        }
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedTo: _assignedTo.trim(),
        dueDate: _dueDate!,
        priority: _priority,
        status: _status,
        isCompleted: _status == 'Done',
        startTime: _startTime,
        endTime: _endTime,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await StorageService.updateTask(task);
        await StorageService.logActivity(
          action: 'updated task',
          targetTitle: task.title,
          taskId: task.id,
        );
      } else {
        await StorageService.addTask(task);
        await StorageService.logActivity(
          action: 'created task',
          targetTitle: task.title,
          taskId: task.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Task updated successfully' : 'Task created successfully'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving task. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.inkSoft)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await StorageService.deleteTask(widget.task!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete task. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.ink),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'Add Task',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              onPressed: _deleteTask,
              tooltip: 'Delete task',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Task Name
                const Text(
                  'Task Name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Mobile Application design',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF6B60F5), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Task name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Task Description
                const Text(
                  'Task Description',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Describe requirements, scope, and deliverables...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF6B60F5), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Description is required';
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // 3. Team Member Horizontal Picker
                const Text(
                  'Team Member',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 82,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _memberList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _memberList.length) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 14.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              final added = await showAddTeamMemberDialog(context);
                              if (added != null && mounted) {
                                setState(() {
                                  if (!_memberList.any((m) => m.name.toLowerCase() == added.name.toLowerCase())) {
                                    _memberList.add(added);
                                  }
                                  _assignedTo = added.name;
                                });
                              }
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF6B60F5), width: 1.5),
                                    color: Colors.white,
                                  ),
                                  child: const Icon(Icons.add, color: Color(0xFF6B60F5), size: 22),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final m = _memberList[index];
                      final isSelected = _assignedTo == m.name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => setState(() => _assignedTo = m.name),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF6B60F5) : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: MemberAvatar(member: m, size: 46),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF6B60F5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                m.name.split(' ').first,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? const Color(0xFF6B60F5) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Date Picker Box
                const Text(
                  'Date',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickDueDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dueDate == null ? 'Select date' : _formatFullDate(_dueDate!),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF6B60F5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Start Time & End Time Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start Time',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _pickTime(isStart: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _startTime,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                                  ),
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Time',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _pickTime(isStart: false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endTime,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                                  ),
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 6. Priority Pills (Low, Medium, High) with semantic colors
                const Text(
                  'Priority',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    {'label': 'Low', 'color': const Color(0xFF10B981)},
                    {'label': 'Medium', 'color': const Color(0xFFF59E0B)},
                    {'label': 'High', 'color': const Color(0xFFEF4444)},
                  ].map((item) {
                    final p = item['label'] as String;
                    final color = item['color'] as Color;
                    final isSelected = _priority == p;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _priority = p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isSelected ? color : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  p,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // 7. Status Pills (To Do, In Progress, Done) with workflow colors
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    {'label': 'To Do', 'color': const Color(0xFFA9CE9B)},
                    {'label': 'In Progress', 'color': const Color(0xFFFFAA5B)},
                    {'label': 'Done', 'color': const Color(0xFF6B60F5)},
                  ].map((item) {
                    final s = item['label'] as String;
                    final color = item['color'] as Color;
                    final isSelected = _status == s;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _status = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isSelected ? color : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 13,
                                  color: isSelected ? Colors.white : color,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                // Save / Update Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6356F5),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF6356F5).withValues(alpha: 0.4),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveTask,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? 'Update Task' : 'Save',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}