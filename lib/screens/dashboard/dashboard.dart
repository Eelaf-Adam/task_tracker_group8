import 'package:flutter/material.dart';
import '../../theme/apptheme.dart';
import '../team/team_members.dart';

class TaskStat {
  final String label;
  final int count;
  final Color color;
  const TaskStat(this.label, this.count, this.color);
}

const _stats = <TaskStat>[
  TaskStat('On track', 5, AppColors.green),
  TaskStat('At risk', 3, AppColors.amber),
  TaskStat('Overdue', 2, AppColors.coral),
  TaskStat('Completed', 2, AppColors.slate),
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

class ProjectCardData {
  final String title;
  final String subtitle;
  final int done;
  final int total;
  final List<TeamMember> team;
  const ProjectCardData(this.title, this.subtitle, this.done, this.total, this.team);
}

final _projects = <ProjectCardData>[
  ProjectCardData('UI Design', 'Mobile App', 50, 80, members.take(3).toList()),
  ProjectCardData('Local Storage', 'Data Layer', 30, 60, members.skip(1).take(3).toList()),
];

class ProgressItem {
  final String category;
  final String title;
  final String when;
  final int percent;
  const ProgressItem(this.category, this.title, this.when, this.percent);
}

const _inProgress = <ProgressItem>[
  ProgressItem('Task Tracker App', 'Create Task Model', '2 min ago', 80),
  ProgressItem('Task Tracker App', 'Revise Home Page', '5 min ago', 70),
  ProgressItem('Task Tracker App', 'Set Up Local Storage', '7 min ago', 40),
];

const _pad = EdgeInsets.symmetric(horizontal: 20);

String _dateLabel() {
  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  final now = DateTime.now();
  return '${days[now.weekday - 1]}, ${now.day}';
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = _stats.fold<int>(0, (sum, s) => sum + s.count);
    final firstName = currentUser.name.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12, bottom: 88),
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
                        child: Text(_dateLabel(), style: AppText.headSemi.copyWith(fontSize: 15)),
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

              // Greeting with decorative dots
              Padding(
                padding: _pad,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${_greeting()},\n$firstName 👋',
                        style: AppText.head.copyWith(fontSize: 24, height: 1.3),
                      ),
                    ),
                    const SizedBox(width: 90, height: 64, child: _Dots()),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: _pad,
                child: Text(
                  "Here's what's happening with your project.",
                  style: AppText.bodySoft.copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Stat cards (2 x 2)
              Padding(
                padding: _pad,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total tasks',
                            value: '$total',
                            icon: Icons.checklist_rounded,
                            color: AppColors.primary,
                            tint: AppColors.primaryTint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'On track',
                            value: '${_stats[0].count}',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.green,
                            tint: AppColors.greenTint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'At risk',
                            value: '${_stats[1].count}',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.amber,
                            tint: AppColors.amberTint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Overdue',
                            value: '${_stats[2].count}',
                            icon: Icons.schedule_rounded,
                            color: AppColors.coral,
                            tint: AppColors.coralTint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Project cards: a plain horizontal scroller with fixed-size cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: _pad,
                child: Row(
                  children: [
                    for (var i = 0; i < _projects.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      _ProjectCard(project: _projects[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Task overview donut + legend
              Padding(
                padding: _pad,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppDecor.card(radius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Task Overview', style: AppText.headSemi.copyWith(fontSize: 15)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CustomPaint(
                              painter: _DonutPainter(_stats, total),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$total', style: AppText.head.copyWith(fontSize: 24)),
                                    Text('Tasks', style: AppText.caption),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                for (final s in _stats) _LegendRow(stat: s),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // In Progress (cards with percentage rings, like the Home design)
              const _SectionHeader('In Progress'),
              const SizedBox(height: 12),
              Padding(
                padding: _pad,
                child: Column(
                  children: [for (final p in _inProgress) _ProgressRow(item: p)],
                ),
              ),
              const SizedBox(height: 12),

              // Recent activity
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

/// Small decorative dots next to the greeting (fixed-size, so always safe).
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
        Positioned(right: 40, top: 0, child: dot(AppColors.amber, 6)),
        Positioned(right: 4, top: 16, child: dot(AppColors.primary, 10)),
        Positioned(right: 56, top: 42, child: dot(AppColors.coral, 5)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(value, style: AppText.head.copyWith(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: AppText.bodySoft.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectCardData project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final progress = project.total == 0 ? 0.0 : project.done / project.total;
    final softWhite = Colors.white.withValues(alpha: 0.75);

    return Container(
      width: 270,
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.title,
                  style: AppText.head.copyWith(fontSize: 17, color: Colors.white)),
              const SizedBox(height: 2),
              Text(project.subtitle,
                  style: AppText.bodySoft.copyWith(fontSize: 12, color: softWhite)),
            ],
          ),
          Row(
            children: [
              _AvatarStack(team: project.team),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Progress',
                        style: AppText.bodySoft.copyWith(fontSize: 11, color: softWhite)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 5,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('${project.done}/${project.total}',
                  style: AppText.headSemi.copyWith(fontSize: 12, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<TeamMember> team;
  const _AvatarStack({required this.team});

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
              child: MemberAvatar(member: team[i], size: size, borderColor: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final TaskStat stat;
  const _LegendRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: stat.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(stat.label, style: AppText.bodySoft.copyWith(fontSize: 13))),
          Text('${stat.count}', style: AppText.headSemi.copyWith(fontSize: 13)),
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

/// Simple donut chart drawn with arcs, no chart package required.
class _DonutPainter extends CustomPainter {
  final List<TaskStat> stats;
  final int total;
  _DonutPainter(this.stats, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    const gap = 0.05; // small gap between segments, in radians
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    double startAngle = -1.5708; // start at the top
    for (final s in stats) {
      final sweep = total == 0 ? 0.0 : (s.count / total) * 6.28319;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      final drawSweep = sweep > gap ? sweep - gap : sweep;
      canvas.drawArc(rect, startAngle + gap / 2, drawSweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.stats != stats;
}