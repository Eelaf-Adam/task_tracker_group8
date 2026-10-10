import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/filter_pills.dart';
import '../../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

/// Task List sorted by urgency: Overdue → At Risk → On Track → Completed,
/// then by nearest deadline. Search, plus filters for SLA status, task
/// status and priority (they combine).
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
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    // SLA is computed once per build, then filtered and sorted.
    final entries = [
      for (final t in _tasks)
        if (_matches(t)) (task: t, sla: t.sla),
    ];
    int count(SlaStatus? s) => s == null
        ? entries.length
        : entries.where((e) => e.sla.status == s).length;
    final visible = entries
        .where((e) => _sla == null || e.sla.status == _sla)
        .toList()
      ..sort((a, b) {
        final byUrgency = SlaService.urgencyRank(a.sla.status)
            .compareTo(SlaService.urgencyRank(b.sla.status));
        return byUrgency != 0 ? byUrgency : a.task.due.compareTo(b.task.due);
      });

    final slaPills = [
      FilterPillData('All (${count(null)})', _sla == null,
          () => setState(() => _sla = null)),
      for (final s in [
        SlaStatus.overdue,
        SlaStatus.atRisk,
        SlaStatus.onTrack,
        SlaStatus.completed,
      ])
        FilterPillData('${s.label} (${count(s)})', _sla == s,
            () => setState(() => _sla = s),
            dot: s.color),
    ];
    final statusPills = [
      for (final s in ['All', ...kStatuses])
        FilterPillData(s, _status == s, () => setState(() => _status = s)),
    ];
    final priorityPills = [
      for (final p in ['All', 'Low', 'Medium', 'High'])
        FilterPillData(p, _priority == p, () => setState(() => _priority = p)),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 72,
        titleSpacing: 24,
        title: const Text(
          'My Tasks',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Center(
              child: Text(
                _tasks.length == 1 ? '1 task' : '${_tasks.length} tasks',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: muted),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Task',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          if (_tasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TaskSearchField(
                controller: _search,
                hasText: _query.isNotEmpty,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            const SizedBox(height: 12),
            FilterPillRow(pills: slaPills),
            const SizedBox(height: 10),
            FilterPillRow(pills: statusPills),
            const SizedBox(height: 10),
            FilterPillRow(pills: priorityPills),
            const SizedBox(height: 12),
          ],
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
      separatorBuilder: (_, __) => const SizedBox(height: 14),
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