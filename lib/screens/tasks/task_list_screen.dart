import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

/// Task List sorted by urgency: Overdue → At Risk → On Track → Completed,
/// then by nearest deadline. Search, plus dropdown filters for SLA status,
/// task status and priority (they combine).
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _search = TextEditingController();
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  SlaStatus? _sla; // null = All
  String _status = 'All';
  String _priority = 'All';
  Timer? _ticker;

  static const _slaOptions = [
    SlaStatus.overdue,
    SlaStatus.atRisk,
    SlaStatus.onTrack,
    SlaStatus.completed,
  ];

  @override
  void initState() {
    super.initState();
    _load();
    // SLA depends on the clock, so re-check every minute.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _search.dispose();
    super.dispose();
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
        _error = 'Tasks could not be loaded';
        _loading = false;
      });
    }
  }

  Future<void> _openDetails(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
    );
    _load(); // refresh after status changes, edits or deletes
  }

  Future<void> _createTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    _load();
  }

  /// Search (title, description, assignee) + Status + Priority filters.
  bool _matches(Task t) {
    if (_status != 'All' && t.statusLabel != _status) return false;
    if (_priority != 'All' && t.priorityLabel != _priority) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return t.title.toLowerCase().contains(q) ||
        t.details.toLowerCase().contains(q) ||
        t.assigneeName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    // SLA is computed once per build, then filtered and sorted.
    final entries = [
      for (final t in _tasks)
        if (_matches(t)) (task: t, sla: t.sla),
    ];
    final visible = entries
        .where((e) => _sla == null || e.sla.status == _sla)
        .toList()
      ..sort((a, b) {
        final byUrgency = SlaService.urgencyRank(a.sla.status)
            .compareTo(SlaService.urgencyRank(b.sla.status));
        return byUrgency != 0 ? byUrgency : a.task.due.compareTo(b.task.due);
      });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Tasks',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 26, color: Color(0xFF0F172A)),
            onPressed: _createTask,
            tooltip: 'Add Task',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        backgroundColor: const Color(0xFF6B60F5),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 22),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Horizontal Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterPill(
                    label: 'All',
                    isSelected: _sla == null && _status == 'All',
                    onTap: () => setState(() {
                      _sla = null;
                      _status = 'All';
                    }),
                  ),
                  const SizedBox(width: 8),
                  for (final s in _slaOptions) ...[
                    _filterPill(
                      label: s.label,
                      isSelected: _sla == s,
                      onTap: () => setState(() {
                        _sla = _sla == s ? null : s;
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Priority popup filter button
                  PopupMenuButton<String>(
                    tooltip: 'Filter by priority',
                    onSelected: (p) => setState(() => _priority = p),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'All', child: Text('Priority: All')),
                      PopupMenuItem(value: 'Low', child: Text('Priority: Low')),
                      PopupMenuItem(value: 'Medium', child: Text('Priority: Medium')),
                      PopupMenuItem(value: 'High', child: Text('Priority: High')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _priority != 'All' ? const Color(0xFF6B60F5) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _priority != 'All' ? const Color(0xFF6B60F5) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: _priority != 'All' ? Colors.white : const Color(0xFF64748B),
                          ),
                          if (_priority != 'All') ...[
                            const SizedBox(width: 4),
                            Text(
                              _priority,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(visible),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B60F5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B60F5) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B60F5).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<({Task task, SlaResult sla})> visible) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _message(Icons.cloud_off, _error!, 'Pull down to try again');
    }
    if (_tasks.isEmpty) {
      return _message(
          Icons.inbox_outlined, 'No tasks yet', 'Tap + to add your first task');
    }
    if (visible.isEmpty) {
      return _query.trim().isNotEmpty
          ? _message(Icons.search_off, 'No tasks match "${_query.trim()}"',
              'Try a different search or filter')
          : _message(Icons.filter_alt_off_outlined, 'No tasks here',
              'Try a different filter');
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // room for the FAB
      itemCount: visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (_, i) => TaskCard(
        task: visible[i].task,
        sla: visible[i].sla,
        onTap: () => _openDetails(visible[i].task),
      ),
    );
  }

  /// Uses a ListView so pull-to-refresh still works on empty/error states.
  Widget _message(IconData icon, String title, String subtitle) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 64, color: muted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center, style: TextStyle(color: muted)),
      ],
    );
  }
}