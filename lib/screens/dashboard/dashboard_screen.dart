import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'In Progress', 'High SLA', 'Completed'];

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Design System Refinement',
      'category': 'UI/UX Design',
      'priority': 'Urgent',
      'sla': 'Due in 2h',
      'slaColor': const Color(0xFFEF4444),
      'progress': 0.85,
      'completed': false,
    },
    {
      'title': 'API SLA Performance Audit',
      'category': 'Backend Service',
      'priority': 'High',
      'sla': 'Due today 5:00 PM',
      'slaColor': const Color(0xFFF59E0B),
      'progress': 0.60,
      'completed': false,
    },
    {
      'title': 'Mobile Responsive QA Testing',
      'category': 'Quality Assurance',
      'priority': 'Medium',
      'sla': 'Due tomorrow',
      'slaColor': const Color(0xFF10B981),
      'progress': 0.40,
      'completed': false,
    },
    {
      'title': 'Onboarding Screen Polish & Review',
      'category': 'Frontend',
      'priority': 'Low',
      'sla': 'Completed',
      'slaColor': const Color(0xFF6B7280),
      'progress': 1.0,
      'completed': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.task_alt, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Tasky',
              style: TextStyle(
                color: AppTheme.darkText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.darkText),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out of Tasky?'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        minimumSize: const Size(100, 42),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signin, (r) => false);
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header greeting
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      child: const Text(
                        'AA',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Albert!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Track tasks & meet all SLAs effortlessly',
                          style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        title: 'In Progress',
                        value: '3',
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricCard(
                        title: 'SLA Score',
                        value: '98%',
                        icon: Icons.verified_outlined,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricCard(
                        title: 'Completed',
                        value: '28',
                        icon: Icons.check_circle_outline,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // SLA Alert Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.timer_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority Sprint SLA Target',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '3 critical tasks must be closed within next 4 hours',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section Title & Filters
                const Text(
                  'My Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final isSelected = _selectedFilterIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(_filters[index]),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.darkText,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedFilterIndex = index);
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Tasks List
                ..._tasks.map((task) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: task['completed'],
                          activeColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (val) {
                            setState(() {
                              task['completed'] = val ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: task['completed'] ? AppTheme.greyText : AppTheme.darkText,
                                  decoration: task['completed'] ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                task['category'],
                                style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (task['slaColor'] as Color).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task['sla'],
                                      style: TextStyle(
                                        color: task['slaColor'],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task['priority'],
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          _showAddTaskDialog(context);
        },
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Task'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Task description / title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 42)),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  _tasks.insert(0, {
                    'title': titleController.text.trim(),
                    'category': 'General Task',
                    'priority': 'Medium',
                    'sla': 'Due tomorrow',
                    'slaColor': const Color(0xFF10B981),
                    'progress': 0.0,
                    'completed': false,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task added successfully!')),
                );
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}
