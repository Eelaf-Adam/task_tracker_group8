import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/storage_service.dart';

/// Create/Edit form for tasks.
/// - TaskFormScreen()            -> create a new task
/// - TaskFormScreen(task: task)  -> edit an existing task
class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  // Placeholder list until Member 4's real Team Members data is wired in
  final List<String> _teamMembers = ['Alice', 'Benjamin', 'Chidi', 'Diane'];
  final List<String> _statuses = ['To Do', 'In Progress', 'Done'];

  String? _assignedTo;
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
    _assignedTo = task?.assignedTo;
    _dueDate = task?.dueDate;
    _priority = task?.priority ?? 'Medium';
    _status = task?.status ?? 'To Do';

    // Avoid a dropdown error if the saved person is not in the list
    if (_assignedTo != null && !_teamMembers.contains(_assignedTo)) {
      _teamMembers.add(_assignedTo!);
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
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_assignedTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign this task to someone')),
      );
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assignedTo: _assignedTo!,
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
              DropdownButtonFormField<String>(
                initialValue: _assignedTo,
                decoration: const InputDecoration(labelText: 'Assign To'),
                items: _teamMembers
                    .map((name) =>
                        DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _assignedTo = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dueDate == null
                        ? 'No due date selected'
                        : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  ),
                  TextButton(
                    onPressed: _pickDueDate,
                    child: const Text('Pick Due Date'),
                  ),
                ],
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