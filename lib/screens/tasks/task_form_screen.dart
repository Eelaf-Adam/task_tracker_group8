import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/storage_service.dart';
import '../team/team_members.dart' show members;

/// Create/Edit form for tasks.
/// - TaskFormScreen()            -> create a new task
/// - TaskFormScreen(task: task)  -> edit an existing task
class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "16 Oct 2026"
String _formatDate(DateTime d) => '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dueDateController;

  final List<String> _statuses = ['To Do', 'In Progress', 'Done'];

  // Names of the real team members (from the Team screen)
  List<String> get _teamNames => members.map((m) => m.name).toList();

  late String _assignedTo; // picked from the list OR typed manually
  DateTime? _dueDate;
  late String _priority;
  late String _status;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _assignedTo = task?.assignedTo ?? '';
    _dueDate = task?.dueDate;
    _dueDateController =
        TextEditingController(text: _dueDate == null ? '' : _formatDate(_dueDate!));
    _priority = task?.priority ?? 'Medium';
    _status = task?.status ?? 'To Do';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
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
      setState(() {
        _dueDate = picked;
        _dueDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveTask() async {
    // Runs every validator (title, description, assignee, due date)
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assignedTo: _assignedTo.trim(),
      dueDate: _dueDate!,
      priority: _priority,
      status: _status,
      isCompleted: _status == 'Done',
    );

    if (_isEditing) {
      await StorageService.updateTask(task);
    } else {
      await StorageService.addTask(task);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Task updated successfully' : 'Task created successfully',
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await StorageService.deleteTask(widget.task!.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTask,
              tooltip: 'Delete task',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Assign To: pick a team member OR type any name
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _assignedTo),
                optionsBuilder: (TextEditingValue value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return _teamNames;
                  return _teamNames
                      .where((name) => name.toLowerCase().contains(query));
                },
                onSelected: (String name) => _assignedTo = name,
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Assign To',
                      hintText: 'Pick a team member or type a name',
                      prefixIcon: Icon(Icons.person_outline),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onChanged: (value) => _assignedTo = value,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please assign this task to someone';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Due date: looks like an input, opens the calendar when tapped
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                onTap: _pickDueDate,
                decoration: const InputDecoration(
                  labelText: 'Due date',
                  hintText: 'Select due date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                validator: (_) =>
                    _dueDate == null ? 'Please select a due date' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Low', 'Medium', 'High']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              // Status only matters when editing; new tasks start as 'To Do'
              if (_isEditing) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTask,
                child: Text(_isEditing ? 'Update Task' : 'Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}