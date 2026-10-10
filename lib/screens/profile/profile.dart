import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../theme/apptheme.dart';
import '../team/team_members.dart';

const _menuItems = ['My Projects', 'Join a Team', 'Settings', 'My Task'];

void _soon(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$what is coming soon'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  final TeamMember member;

  const ProfileScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    // The Profile tab is a root screen, so only show "back" when it was pushed
    // from another screen (e.g. tapping a member in the Team list).
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
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
                    child: Text('Profile', style: AppText.headSemi.copyWith(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 20),
            _Hero(member: member),
            const SizedBox(height: 24),
            const _StatsRow(),
            const SizedBox(height: 24),
            for (final label in _menuItems) _MenuRow(label: label),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final TeamMember member;
  const _Hero({required this.member});

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
                  color: member.roleColor.color,
                ),
                alignment: Alignment.center,
                child: Text(
                  member.initials,
                  style: AppText.head.copyWith(color: Colors.white, fontSize: 32),
                ),
              ),
              const SizedBox(height: 14),
              Text(member.name, style: AppText.head.copyWith(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                member.role,
                style: AppText.body.copyWith(color: member.roleColor.color, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Edit profile',
                child: GestureDetector(
                  onTap: () => _soon(context, 'Edit profile'),
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
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _StatItem(icon: Icons.schedule_rounded, value: '5', label: 'On track'),
        ),
        Container(width: 1, height: 44, color: AppColors.line),
        const Expanded(
          child: _StatItem(icon: Icons.check_rounded, value: '12', label: 'Total tasks'),
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
  const _MenuRow({required this.label});

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
          onTap: () => _soon(context, label),
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