import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../theme/apptheme.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _filter = 'All'; // 'All', 'To Do', 'In Progress', 'Done'

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await StorageService.loadTasks();

    // If no tasks exist yet, seed some initial sample tasks
    if (tasks.isEmpty) {
      final now = DateTime.now();
      final sampleTasks = [
        Task(
          id: '1',
          title: 'Create Detail Booking',
          description: 'Design and implement detailed booking flow for productivity app',
          assignedTo: 'Lee',
          dueDate: now.add(const Duration(days: 2)),
          priority: 'High',
          status: 'In Progress',
        ),
        Task(
          id: '2',
          title: 'Revision Home Page',
          description: 'Refactor home page widgets according to client feedback',
          assignedTo: 'Sarah Lee',
          dueDate: now.add(const Duration(days: 3)),
          priority: 'Medium',
          status: 'In Progress',
        ),
        Task(
          id: '3',
          title: 'Working On Landing Page',
          description: 'Complete hero section and feature grid for online course',
          assignedTo: 'Michael Kim',
          dueDate: now.add(const Duration(days: 5)),
          priority: 'Low',
          status: 'In Progress',
        ),
      ];
      await StorageService.saveTasks(sampleTasks);
      _tasks = sampleTasks;
    } else {
      _tasks = tasks;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Task> get _filteredTasks {
    if (_filter == 'All') return _tasks;
    return _tasks.where((t) => t.status == _filter).toList();
  }

  Future<void> _openCreateTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    _loadTasks();
  }

  Future<void> _openEditTask(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Text('My Tasks', style: AppText.headSemi.copyWith(fontSize: 18)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openCreateTask,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppColors.primary, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: ['All', 'To Do', 'In Progress', 'Done'].map((status) {
                  final isSelected = _filter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = status),
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.inkSoft,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.line,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Task List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.checklist_rounded, size: 64, color: AppColors.inkSoft.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text('No tasks in this category', style: AppText.headSemi.copyWith(fontSize: 15)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _openCreateTask,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Task'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTasks,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
                            itemCount: _filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = _filteredTasks[index];
                              final isDone = task.status == 'Done' || task.isCompleted;
                              final sla = SlaService.classify(
                                createdAt: DateTime.now().subtract(const Duration(days: 1)),
                                deadline: task.dueDate,
                                isCompleted: isDone,
                                isStarted: task.status == 'In Progress',
                                priority: task.priority,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: AppDecor.card(),
                                child: InkWell(
                                  onTap: () => _openEditTask(task),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: sla.status.color.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(sla.status.icon, size: 13, color: sla.status.color),
                                                const SizedBox(width: 4),
                                                Text(
                                                  sla.status.label,
                                                  style: TextStyle(
                                                    color: sla.status.color,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            task.priority,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: task.priority == 'High'
                                                  ? Colors.redAccent
                                                  : (task.priority == 'Medium' ? Colors.orange : Colors.blueGrey),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        task.title,
                                        style: AppText.headSemi.copyWith(
                                          fontSize: 15,
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      if (task.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          task.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.bodySoft.copyWith(fontSize: 12),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 14, color: AppColors.inkSoft),
                                          const SizedBox(width: 4),
                                          Text(task.assignedTo, style: AppText.caption),
                                          const Spacer(),
                                          const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.inkSoft),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Due: ${task.dueDate.day}/${task.dueDate.month}',
                                            style: AppText.caption,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
