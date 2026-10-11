import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/app_activity.dart';
import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../tasks/task_details_screen.dart';
import '../tasks/task_form_screen.dart';
import '../tasks/task_list_screen.dart';
import '../tasks/task_status_screen.dart';
import '../team/create_team_screen.dart';
import '../team/team_members_screen.dart';

const _pad = EdgeInsets.symmetric(horizontal: 20);

String _dateLabel() {
  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  final now = DateTime.now();
  return '${days[now.weekday - 1]}, ${now.day}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0; // 0: Home, 1: Tasks, 2: Team, 3: Profile
  int _listVersion = 0; // bump to reload the task list

  Future<void> _openCreateMenu() async {
    final choice = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) => const _CreateMenu(),
    );
    if (!mounted || choice == null) return;

    if (choice == 'Task') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TaskFormScreen()),
      );
      if (mounted) setState(() => _listVersion++);
    } else if (choice == 'Team') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
      );
      if (mounted) setState(() => _listVersion++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          const _HomeDashboardView(),
          TaskListScreen(key: ValueKey(_listVersion)),
          const TeamMembersScreen(),
          ProfileScreen(member: currentUser, isCurrentUser: true),
        ],
      ),
      bottomNavigationBar: _BottomNavPottonBar(
        selectedIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 2) {
            // Center plus button: open the Create menu
            _openCreateMenu();
          } else {
            // Map visual slot to tab index:
            // Slot 0 -> Tab 0 (Home)
            // Slot 1 -> Tab 1 (Tasks)
            // Slot 3 -> Tab 2 (Team)
            // Slot 4 -> Tab 3 (Profile)
            final tabIndex = index < 2 ? index : index - 1;
            setState(() => _currentNavIndex = tabIndex);
          }
        },
      ),
    );
  }
}

/// The Main Dashboard Home Screen View
class _HomeDashboardView extends StatefulWidget {
  const _HomeDashboardView();

  @override
  State<_HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<_HomeDashboardView> {
  List<Task> _tasks = [];
  List<AppActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await StorageService.loadTasks();
      final activities = await StorageService.loadActivities();
      await StorageService.loadMembers();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _activities = activities;
        });
      }
    } catch (_) {}
  }

  void _openTaskStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskStatusScreen()),
    ).then((_) => _loadTasks());
  }

  void _openTask(Task t) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: t)),
    ).then((_) => _loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = AuthService.currentUser;
    final fullName = (activeUser != null && activeUser.name.trim().isNotEmpty)
        ? activeUser.name.trim()
        : currentUser.name;
    final firstName = fullName.split(RegExp(r'\s+')).first;

    final inProgressLive = _tasks.length > 1
        ? _tasks.where((t) => t.id != _tasks.firstOrNull?.id).toList()
        : _tasks;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTasks,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Date on left, Status button on right (top-left menu removed)
              Padding(
                padding: _pad,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateLabel(),
                      style: AppText.headSemi.copyWith(fontSize: 16, color: AppColors.ink),
                    ),
                    RoundIconButton(
                      icon: Icons.pie_chart_outline_rounded,
                      label: 'Status',
                      onTap: _openTaskStatus,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Greeting with dynamic user name and decorative dots
              Padding(
                padding: _pad,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '$firstName, Let’s build\nhabits together',
                        style: AppText.head.copyWith(fontSize: 24, height: 1.25, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 60, height: 50, child: _Dots()),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Task cards carousel (responsive width displaying actual tasks)
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth * 0.78).clamp(275.0, 380.0);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: _pad,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        if (_tasks.isNotEmpty)
                          for (var i = 0; i < _tasks.length; i++) ...[
                            if (i > 0) const SizedBox(width: 14),
                            _TaskHeroCard(
                              task: _tasks[i],
                              isDark: (i % 2 == 0),
                              width: cardWidth,
                              onTap: () => _openTask(_tasks[i]),
                            ),
                          ]
                        else
                          _EmptyTaskCard(
                            width: cardWidth,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                              ).then((_) => _loadTasks());
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Task Overview Section
              Padding(
                padding: _pad,
                child: InkWell(
                  onTap: _openTaskStatus,
                  child: Row(
                    children: [
                      Expanded(child: Text('Task Overview', style: AppText.headSemi.copyWith(fontSize: 16))),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: _pad,
                child: Column(
                  children: [
                    if (inProgressLive.isNotEmpty)
                      for (final t in inProgressLive.take(3))
                        InkWell(
                          onTap: () => _openTask(t),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: AppDecor.card(),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.details.isNotEmpty ? t.details : 'Task Assignment',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.bodySoft.copyWith(fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.headSemi.copyWith(fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Due ${t.due.day}/${t.due.month} • ${t.sla.status.label}',
                                        style: AppText.caption.copyWith(
                                          color: t.sla.status == SlaStatus.overdue
                                              ? const Color(0xFFEF4444)
                                              : t.sla.status == SlaStatus.atRisk
                                                  ? const Color(0xFFF59E0B)
                                                  : AppColors.inkSoft,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox.expand(
                                        child: CircularProgressIndicator(
                                          value: t.progressFraction,
                                          strokeWidth: 3.5,
                                          backgroundColor: AppColors.primaryTint,
                                          color: (t.isDone || t.statusLabel == 'Done')
                                              ? const Color(0xFF10B981)
                                              : AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        '${t.progressPercent}%',
                                        style: AppText.headSemi.copyWith(
                                          fontSize: 11,
                                          color: (t.isDone || t.statusLabel == 'Done')
                                              ? const Color(0xFF10B981)
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: AppDecor.card(),
                        child: Center(
                          child: Text(
                            'No tasks to display yet. Tap + to add one!',
                            style: AppText.bodySoft.copyWith(fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Recent Activity Section
              Padding(
                padding: _pad,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: AppText.headSemi.copyWith(fontSize: 16)),
                    if (_activities.isNotEmpty)
                      Text(
                        '${_activities.length} updates',
                        style: AppText.caption.copyWith(color: AppColors.inkSoft),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: _pad,
                child: Column(
                  children: [
                    if (_activities.isNotEmpty)
                      for (final a in _activities.take(5))
                        _LiveActivityRow(
                          activity: a,
                          onTap: () {
                            if (a.taskId != null) {
                              final match = _tasks.where((t) => t.id == a.taskId);
                              if (match.isNotEmpty) {
                                _openTask(match.first);
                                return;
                              }
                            }
                            if (a.action.contains('team') || a.action.contains('member')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TeamMembersScreen()),
                              ).then((_) => _loadTasks());
                            }
                          },
                        )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: AppDecor.card(),
                        child: Center(
                          child: Text(
                            'No recent activity yet',
                            style: AppText.bodySoft.copyWith(fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom bottom navigation bar with centered action button
class _BottomNavPottonBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavPottonBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Map internal tab index to 5-slot bottom bar index:
    // Tab 0 -> slot 0 (Home)
    // Tab 1 -> slot 1 (Tasks)
    // (slot 2 is Center Plus Button)
    // Tab 2 -> slot 3 (Team)
    // Tab 3 -> slot 4 (Profile)
    int activeSlot = selectedIndex;
    if (selectedIndex >= 2) activeSlot = selectedIndex + 1;

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.12), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 0: Home
            _navIconButton(
              icon: activeSlot == 0 ? Icons.home_rounded : Icons.home_outlined,
              isSelected: activeSlot == 0,
              onTap: () => onTap(0),
              label: 'Home',
            ),

            // 1: Tasks (Clipboard Task Icon)
            _navIconButton(
              icon: activeSlot == 1 ? Icons.assignment_rounded : Icons.assignment_outlined,
              isSelected: activeSlot == 1,
              onTap: () => onTap(1),
              label: 'Tasks',
            ),

            // 2: Center Plus Button (Add Task)
            GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B60F5), Color(0xFF5548EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B60F5).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // 3: Team (Team / Group Members Icon)
            _navIconButton(
              icon: activeSlot == 3 ? Icons.groups_rounded : Icons.groups_outlined,
              isSelected: activeSlot == 3,
              onTap: () => onTap(3),
              label: 'Team',
            ),

            // 4: Profile
            _navIconButton(
              icon: activeSlot == 4 ? Icons.person_rounded : Icons.person_outline_rounded,
              isSelected: activeSlot == 4,
              onTap: () => onTap(4),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIconButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String label,
  }) {
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Icon(
            icon,
            size: 26,
            color: isSelected ? const Color(0xFF5B51DD) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

/// Small decorative dots next to the greeting
class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color, double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );

    return Stack(
      children: [
        Positioned(right: 28, top: 2, child: dot(AppColors.amber, 7)),
        Positioned(right: 0, top: 12, child: dot(AppColors.primary, 10)),
        Positioned(right: 38, top: 28, child: dot(AppColors.coral, 6)),
      ],
    );
  }
}

class _TaskHeroCard extends StatelessWidget {
  final Task task;
  final bool isDark;
  final double? width;
  final VoidCallback? onTap;

  const _TaskHeroCard({
    required this.task,
    this.isDark = true,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = task.progressFraction;
    final percentStr = '${task.progressPercent}%';

    final bgColor = isDark ? const Color(0xFF6356F5) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.ink;
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.8) : AppColors.inkSoft;
    final progressTrack = isDark ? Colors.white.withValues(alpha: 0.25) : AppColors.line;
    final progressFill = isDark ? Colors.white : const Color(0xFF6356F5);

    // Find assigned member or create default avatar
    final match = members.where((m) => m.name.toLowerCase() == task.assigneeName.toLowerCase());
    final member = match.isNotEmpty
        ? match.first
        : TeamMember(
            initials: computeInitials(task.assigneeName),
            name: task.assigneeName.isNotEmpty ? task.assigneeName : 'Team Member',
            role: 'Contributor',
            roleColor: getRoleColor('Contributor'),
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: width ?? 280,
          height: 154,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: isDark ? null : Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xFF6356F5).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.head.copyWith(fontSize: 17, color: titleColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : (task.sla.status == SlaStatus.atRisk
                                  ? const Color(0xFFFFFBEB)
                                  : task.sla.status == SlaStatus.overdue
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFF0FDF4)),
                          borderRadius: BorderRadius.circular(10),
                          border: isDark
                              ? null
                              : Border.all(
                                  color: task.sla.status == SlaStatus.atRisk
                                      ? const Color(0xFFF59E0B)
                                      : task.sla.status == SlaStatus.overdue
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                  width: 0.8,
                                ),
                        ),
                        child: Text(
                          task.sla.status.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : (task.sla.status == SlaStatus.atRisk
                                    ? const Color(0xFFD97706)
                                    : task.sla.status == SlaStatus.overdue
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF059669)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.details.isNotEmpty ? task.details : 'Task Assignment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySoft.copyWith(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
              Row(
                children: [
                  MemberAvatar(
                    member: member,
                    size: 30,
                    borderColor: isDark ? Colors.white : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            color: isDark ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 5,
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: progressTrack,
                              color: progressFill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    percentStr,
                    style: AppText.headSemi.copyWith(fontSize: 12, color: titleColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTaskCard extends StatelessWidget {
  final double? width;
  final VoidCallback? onTap;

  const _EmptyTaskCard({this.width, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: width ?? 280,
          height: 154,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 10),
              Text('No tasks yet', style: AppText.headSemi.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text('Tap to create your first task', style: AppText.bodySoft.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}


/// Blurred "Create" menu opened by the center + button.
class _CreateMenu extends StatelessWidget {
  const _CreateMenu();

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Blurred background; tap anywhere outside to close
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.white.withValues(alpha: 0.35)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _CreateMenuItem(
                          icon: Icons.edit_outlined,
                          label: 'Create Task',
                          result: 'Task'),
                      const _CreateMenuItem(
                          icon: Icons.groups_outlined,
                          label: 'Create Team',
                          result: 'Team'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateMenuItem extends StatelessWidget {
  const _CreateMenuItem({
    required this.icon,
    required this.label,
    required this.result,
  });

  final IconData icon;
  final String label;
  final String result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pop(context, result),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.ink),
              const SizedBox(width: 14),
              Text(label, style: AppText.headSemi.copyWith(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveActivityRow extends StatelessWidget {
  final AppActivity activity;
  final VoidCallback? onTap;

  const _LiveActivityRow({required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final match = members.where((m) => m.name.toLowerCase() == activity.userName.toLowerCase());
    final member = match.isNotEmpty
        ? match.first
        : TeamMember(
            initials: computeInitials(activity.userName),
            name: activity.userName,
            role: 'Contributor',
            roleColor: getRoleColor('Contributor'),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                MemberAvatar(member: member, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppText.body.copyWith(fontSize: 13, color: AppColors.ink),
                          children: [
                            TextSpan(
                              text: '${activity.userName} ',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: '${activity.action} ',
                              style: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.9)),
                            ),
                            TextSpan(
                              text: '"${activity.targetTitle}"',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppColors.inkMuted),
                          const SizedBox(width: 4),
                          Text(
                            activity.timeAgo,
                            style: AppText.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (activity.taskId != null)
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
