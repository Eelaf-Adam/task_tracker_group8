import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/apptheme.dart';
import '../profile/profile.dart';
import '../tasks/task_form_screen.dart';
import '../tasks/task_list_screen.dart';
import '../team/team_members.dart';


class ProjectCardData {
  final String title;
  final String subtitle;
  final int done;
  final int total;
  final List<TeamMember> team;
  final bool isDark;
  const ProjectCardData({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.total,
    required this.team,
    this.isDark = true,
  });
}

final _projects = <ProjectCardData>[
  ProjectCardData(
    title: 'Application Design',
    subtitle: 'UI Design Kit',
    done: 50,
    total: 80,
    team: members.take(3).toList(),
    isDark: true,
  ),
  ProjectCardData(
    title: 'Overlay Concept',
    subtitle: 'UI Design Kit',
    done: 30,
    total: 60,
    team: members.skip(1).take(2).toList(),
    isDark: false,
  ),
];

class ProgressItem {
  final String category;
  final String title;
  final String when;
  final int percent;
  const ProgressItem(this.category, this.title, this.when, this.percent);
}

const _inProgress = <ProgressItem>[
  ProgressItem('Productivity Mobile App', 'Create Detail Booking', '2 min ago', 60),
  ProgressItem('Banking Mobile App', 'Revision Home Page', '5 min ago', 70),
  ProgressItem('Online Course', 'Working On Landing Page', '7 min ago', 80),
];

class ActivityItem {
  final TeamMember member;
  final String action;
  final String when;
  const ActivityItem(this.member, this.action, this.when);
}

final _activity = <ActivityItem>[
  ActivityItem(members[1], 'updated UI Design', '2 hours ago'),
  ActivityItem(members[2], 'started Local Storage', '5 hours ago'),
  ActivityItem(members[3], 'flagged Create Task Model', 'Yesterday'),
];

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
      pageBuilder: (_, __, ___) => const _CreateMenu(),
    );
    if (!mounted || choice == null) return;

    if (choice == 'Task') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TaskFormScreen()),
      );
      if (mounted) setState(() => _listVersion++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create $choice is coming soon')),
      );
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
          ProfileScreen(member: currentUser),
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
class _HomeDashboardView extends StatelessWidget {
  const _HomeDashboardView();

  @override
  Widget build(BuildContext context) {
    // Dynamic user name from AuthService (e.g., 'Lee')
    final activeUser = AuthService.currentUser;
    final fullName = (activeUser != null && activeUser.name.trim().isNotEmpty)
        ? activeUser.name.trim()
        : currentUser.name;
    final firstName = fullName.split(RegExp(r'\s+')).first;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: grid button, date, bell
            Padding(
              padding: _pad,
              child: Row(
                children: [
                  const RoundIconButton(icon: Icons.grid_view_rounded, label: 'Menu'),
                  Expanded(
                    child: Center(
                      child: Text(_dateLabel(), style: AppText.headSemi.copyWith(fontSize: 16)),
                    ),
                  ),
                  const RoundIconButton(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
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
                      '$firstName, Let’s make a\nhabits together 🙌',
                      style: AppText.head.copyWith(fontSize: 24, height: 1.25, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 60, height: 50, child: _Dots()),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Project cards carousel
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: _pad,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < _projects.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    _ProjectCard(project: _projects[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // In Progress Section
            const _SectionHeader('In Progress'),
            const SizedBox(height: 12),
            Padding(
              padding: _pad,
              child: Column(
                children: [for (final p in _inProgress) _ProgressRow(item: p)],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Activity Section
            const _SectionHeader('Recent Activity'),
            const SizedBox(height: 12),
            Padding(
              padding: _pad,
              child: Column(
                children: [for (final a in _activity) _ActivityRow(item: a)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Bottom Navigation Bar matching Image 2
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pad,
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.headSemi.copyWith(fontSize: 16))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
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

class _ProjectCard extends StatelessWidget {
  final ProjectCardData project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final progress = project.total == 0 ? 0.0 : project.done / project.total;
    final isDark = project.isDark;

    final bgColor = isDark ? const Color(0xFF6356F5) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.ink;
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.75) : AppColors.inkSoft;
    final progressTrack = isDark ? Colors.white.withValues(alpha: 0.25) : AppColors.line;
    final progressFill = isDark ? Colors.white : const Color(0xFF6356F5);

    return Container(
      width: 270,
      height: 154,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? null : Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0xFF6356F5).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
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
              Text(project.title,
                  style: AppText.head.copyWith(fontSize: 17, color: titleColor)),
              const SizedBox(height: 2),
              Text(project.subtitle,
                  style: AppText.bodySoft.copyWith(fontSize: 12, color: subtitleColor)),
            ],
          ),
          Row(
            children: [
              _AvatarStack(team: project.team, borderColor: isDark ? Colors.white : Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Progress',
                        style: AppText.bodySoft.copyWith(fontSize: 11, color: subtitleColor)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 5,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: progressTrack,
                          color: progressFill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('${project.done}/${project.total}',
                  style: AppText.headSemi.copyWith(fontSize: 12, color: titleColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<TeamMember> team;
  final Color borderColor;
  const _AvatarStack({required this.team, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    const size = 30.0;
    const overlap = 18.0;
    return SizedBox(
      width: team.isEmpty ? 0 : size + (team.length - 1) * overlap,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < team.length; i++)
            Positioned(
              left: i * overlap,
              child: MemberAvatar(member: team[i], size: size, borderColor: borderColor),
            ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final ProgressItem item;
  const _ProgressRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecor.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.category, style: AppText.bodySoft.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(item.title, style: AppText.headSemi.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(item.when, style: AppText.caption),
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
                    value: item.percent / 100,
                    strokeWidth: 3.5,
                    backgroundColor: AppColors.primaryTint,
                    color: AppColors.primary,
                  ),
                ),
                Text('${item.percent}%', style: AppText.headSemi.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
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
                          icon: Icons.add_box_outlined,
                          label: 'Create Project',
                          result: 'Project'),
                      const _CreateMenuItem(
                          icon: Icons.groups_outlined,
                          label: 'Create Team',
                          result: 'Team'),
                      const _CreateMenuItem(
                          icon: Icons.schedule,
                          label: 'Create Event',
                          result: 'Event'),
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

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecor.card(),
      child: Row(
        children: [
          MemberAvatar(member: item.member, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppText.body.copyWith(fontSize: 13),
                children: [
                  TextSpan(
                    text: item.member.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' ${item.action}',
                    style: const TextStyle(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(item.when, style: AppText.caption),
        ],
      ),
    );
  }
}