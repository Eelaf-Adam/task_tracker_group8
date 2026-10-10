import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/apptheme.dart';
import '../profile/profile.dart';
class TeamMember {
  final String initials;
  final String name;
  final String role;
  final RoleColor roleColor;

  const TeamMember({
    required this.initials,
    required this.name,
    required this.role,
    required this.roleColor,
  });
}

/// Public (no underscore) so dashboard.dart can reuse this same list
/// for stats and recent activity, instead of duplicating data.
const members = <TeamMember>[
  TeamMember(
    initials: 'JD',
    name: 'John Doe',
    role: 'Project Manager',
    roleColor: RoleColor.projectManager,
  ),
  TeamMember(
    initials: 'SL',
    name: 'Sarah Lee',
    role: 'UI/UX Designer',
    roleColor: RoleColor.designer,
  ),
  TeamMember(
    initials: 'MK',
    name: 'Michael Kim',
    role: 'Mobile Developer',
    roleColor: RoleColor.developer,
  ),
  TeamMember(
    initials: 'EW',
    name: 'Emily Wong',
    role: 'QA Tester',
    roleColor: RoleColor.qa,
  ),
  TeamMember(
    initials: 'DL',
    name: 'David Liu',
    role: 'Documentation',
    roleColor: RoleColor.docs,
  ),
];

TeamMember getCurrentTeamMember() {
  final user = AuthService.currentUser;
  if (user != null && user.name.trim().isNotEmpty) {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    final initials = parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (user.name.trim().length >= 2
            ? user.name.trim().substring(0, 2).toUpperCase()
            : user.name.trim().toUpperCase());
    return TeamMember(
      initials: initials,
      name: user.name.trim(),
      role: 'Project Member',
      roleColor: RoleColor.designer,
    );
  }
  return members[0];
}

/// The logged-in user, shown on the Profile tab by default.
TeamMember get currentUser => getCurrentTeamMember();

/// Round, thin-bordered icon button used in screen headers
/// (back button, add button, bell...). Shared by the other screens.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}

/// Round avatar showing a member's initials in their role color.
class MemberAvatar extends StatelessWidget {
  final TeamMember member;
  final double size;
  final Color? borderColor;
  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 44,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: member.roleColor.tint,
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 2),
      ),
      child: Text(
        member.initials,
        style: AppText.headSemi.copyWith(
          color: member.roleColor.color,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class TeamMembersScreen extends StatelessWidget {
  const TeamMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
          children: [
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Center(
                    child: Text('Team Members', style: AppText.headSemi.copyWith(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '${members.length} people on this project',
              style: AppText.bodySoft.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Avatar strip, like the "Team Member" row in the design
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final m in members)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: SizedBox(
                        width: 56,
                        child: Column(
                          children: [
                            MemberAvatar(member: m, size: 52),
                            const SizedBox(height: 6),
                            Text(
                              m.name.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('All members', style: AppText.headSemi.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            for (final m in members) _MemberRow(member: m),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final TeamMember member;
  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => ProfileScreen(member: member)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                MemberAvatar(member: member, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: AppText.headSemi.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        member.role,
                        style: AppText.body.copyWith(
                          color: member.roleColor.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}