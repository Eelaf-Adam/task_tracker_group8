import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../tasks/task_form_screen.dart';
import '../tasks/task_list_screen.dart';
import '../tasks/task_status_screen.dart';
import '../team/team_members_screen.dart';

/// Profile screen with complete working business logic:
/// - Real live user statistics from StorageService (Total Tasks, On Track, Completed)
/// - Correctly distinguishes the logged-in user profile from other team members
/// - For team members: displays their actual name, role, assigned tasks, and '+ Assign Task'
/// - For self (Tab 4): displays account name, 'Edit Profile', settings, and 'Log Out'
class ProfileScreen extends StatefulWidget {
  final TeamMember member;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    required this.member,
    this.isCurrentUser = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _displayName;
  late String _role;
  List<Task> _tasks = [];

  bool get _isSelf {
    if (widget.isCurrentUser) return true;
    final authUser = AuthService.currentUser;
    if (authUser != null && authUser.name.trim().isNotEmpty) {
      return authUser.name.trim().toLowerCase() == widget.member.name.trim().toLowerCase();
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    final authUser = AuthService.currentUser;
    _displayName = (_isSelf && authUser != null && authUser.name.trim().isNotEmpty)
        ? authUser.name.trim()
        : widget.member.name;
    _role = widget.member.role;
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final tasks = await StorageService.loadTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
      });
    } catch (_) {}
  }

  void _onMenuTap(String label) {
    if (label == 'My Task') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TaskListScreen()),
      ).then((_) => _loadStats());
    } else if (label == 'My Projects') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TaskStatusScreen()),
      ).then((_) => _loadStats());
    } else if (label == 'Join a Team') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeamMembersScreen()),
      );
    } else if (label == 'Settings') {
      _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Get notified when tasks are near SLA deadline'),
              value: true,
              onChanged: (_) {},
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Text('v1.0.0 (Group 8)', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    if (!_isSelf) return;
    final nameCtrl = TextEditingController(text: _displayName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && nameCtrl.text.trim().isNotEmpty) {
      final newName = nameCtrl.text.trim();
      setState(() => _displayName = newName);
      await AuthService.updateCurrentUserProfile(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    // Compute live business metrics:
    // If viewing own account, show all tasks
    // If viewing a member, show only tasks assigned to that member
    final displayedTasks = _isSelf
        ? _tasks
        : _tasks
            .where((t) =>
                t.assignedTo.trim().toLowerCase() ==
                widget.member.name.trim().toLowerCase())
            .toList();

    final totalTasks = displayedTasks.length;
    final onTrackTasks = displayedTasks.where((t) => t.sla.status == SlaStatus.onTrack).length;
    final completedTasks = displayedTasks.where((t) => t.isDone || t.statusLabel == 'Done').length;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
            children: [
              Row(
                children: [
                  if (canGoBack)
                    RoundIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Text(
                        _isSelf ? 'Profile' : 'Member Profile',
                        style: AppText.headSemi.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),

              // Hero section with member/user name
              _Hero(
                name: _displayName,
                role: _role,
                initials: widget.member.initials.isNotEmpty
                    ? widget.member.initials
                    : (_displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U'),
                roleColor: widget.member.roleColor.color,
                isSelf: _isSelf,
                onEdit: _editProfile,
              ),
              const SizedBox(height: 24),

              // Dynamic Live Stats Row (Total, On Track, Completed)
              _StatsRow(
                totalCount: '$totalTasks',
                onTrackCount: '$onTrackTasks',
                completedCount: '$completedTasks',
              ),
              const SizedBox(height: 24),

              if (_isSelf) ...[
                // Working Menu Items for Current User
                for (final label in ['My Task', 'My Projects', 'Join a Team', 'Settings'])
                  _MenuRow(
                    label: label,
                    onTap: () => _onMenuTap(label),
                  ),
                const SizedBox(height: 16),

                // Logout Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppDecor.glow,
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthService.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signin, (route) => false);
                      }
                    },
                    child: const Text('Log Out'),
                  ),
                ),
              ] else ...[
                // Member-specific assigned tasks section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assigned Tasks (${displayedTasks.length})',
                      style: AppText.headSemi.copyWith(fontSize: 16),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskFormScreen(initialAssignee: widget.member.name),
                          ),
                        ).then((_) => _loadStats());
                      },
                      icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                      label: const Text(
                        'Assign Task',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (displayedTasks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 36, color: AppColors.inkMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks assigned to ${widget.member.name} yet',
                          style: AppText.caption.copyWith(color: AppColors.inkMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  for (final task in displayedTasks)
                    _MemberTaskTile(
                      task: task,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
                        ).then((_) => _loadStats());
                      },
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String name;
  final String role;
  final String initials;
  final Color roleColor;
  final bool isSelf;
  final VoidCallback onEdit;

  const _Hero({
    required this.name,
    required this.role,
    required this.initials,
    required this.roleColor,
    required this.isSelf,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const Positioned(left: 40, top: 0, child: _Dot(AppColors.amber, 6)),
          const Positioned(right: 36, top: 6, child: _Dot(AppColors.primary, 10)),
          const Positioned(right: 70, top: 70, child: _Dot(AppColors.coral, 5)),
          Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: roleColor,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppText.head.copyWith(color: Colors.white, fontSize: 32),
                ),
              ),
              const SizedBox(height: 14),
              Text(name, style: AppText.head.copyWith(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                role,
                style: AppText.body.copyWith(color: roleColor, fontSize: 12),
              ),
              if (isSelf) ...[
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Edit profile',
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        'Edit',
                        style: AppText.body.copyWith(color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot(this.color, this.size);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String totalCount;
  final String onTrackCount;
  final String completedCount;

  const _StatsRow({
    required this.totalCount,
    required this.onTrackCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(icon: Icons.schedule_rounded, value: onTrackCount, label: 'On track'),
        ),
        Container(width: 1, height: 44, color: AppColors.line),
        Expanded(
          child: _StatItem(icon: Icons.check_circle_outline, value: completedCount, label: 'Completed'),
        ),
        Container(width: 1, height: 44, color: AppColors.line),
        Expanded(
          child: _StatItem(icon: Icons.assignment_outlined, value: totalCount, label: 'Total tasks'),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(value, style: AppText.head.copyWith(fontSize: 18)),
        Text(label, style: AppText.caption),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(child: Text(label, style: AppText.body.copyWith(fontSize: 14))),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberTaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _MemberTaskTile({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 38,
                  decoration: BoxDecoration(
                    color: task.isDone
                        ? AppColors.green
                        : (task.sla.status == SlaStatus.overdue
                            ? AppColors.coral
                            : AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppText.headSemi.copyWith(
                          fontSize: 14,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.inkMuted),
                          const SizedBox(width: 4),
                          Text(
                            task.dueLabel,
                            style: AppText.caption.copyWith(color: AppColors.inkMuted, fontSize: 11),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.isDone
                                  ? AppColors.greenTint
                                  : AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: task.isDone ? AppColors.green : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}