import 'package:flutter/material.dart';
import '../../models/team_member.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import 'create_team_screen.dart';

export '../../models/team_member.dart';

TeamMember getCurrentTeamMember() {
  final user = AuthService.currentUser;
  if (user != null && user.name.trim().isNotEmpty) {
    final initials = computeInitials(user.name.trim());
    return TeamMember(
      initials: initials,
      name: user.name.trim(),
      role: 'Project Member',
      roleColor: RoleColor.designer,
    );
  }
  return members.isNotEmpty ? members[0] : defaultMembers[0];
}

/// The logged-in user, shown on the Profile tab by default.
TeamMember get currentUser => getCurrentTeamMember();

/// Round, thin-bordered icon button used in screen headers
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

/// Reusable modal dialog to add and save a custom team member.
Future<TeamMember?> showAddTeamMemberDialog(
  BuildContext context, {
  ValueChanged<TeamMember>? onMemberAdded,
}) async {
  final nameController = TextEditingController();
  final roleController = TextEditingController(text: 'UI/UX Designer');
  final formKey = GlobalKey<FormState>();

  const roles = [
    'UI/UX Designer',
    'Mobile Developer',
    'Project Manager',
    'QA Tester',
    'Backend Engineer',
    'Documentation',
    'Product Owner',
  ];

  return showDialog<TeamMember>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final currentName = nameController.text.trim();
          final previewInitials = computeInitials(currentName);
          final currentRole = roleController.text.trim();
          final previewColor = getRoleColor(currentRole);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Team Member',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Live Avatar Preview
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: previewColor.tint,
                              border: Border.all(color: previewColor.color, width: 2),
                            ),
                            child: Text(
                              previewInitials,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: previewColor.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentName.isNotEmpty ? currentName : 'New Member',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            currentRole,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: previewColor.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Full Name Field
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. Alex Rivers',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6B60F5), width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter the member name';
                        }
                        if (val.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Role Field
                    const Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: roleController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Select or type role',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6B60F5), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Role quick suggestions
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final r in roles)
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                roleController.text = r;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentRole == r
                                    ? AppColors.primaryTint
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: currentRole == r
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                r,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: currentRole == r ? FontWeight.w600 : FontWeight.w400,
                                  color: currentRole == r ? AppColors.primary : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final name = nameController.text.trim();
                  final role = roleController.text.trim().isNotEmpty
                      ? roleController.text.trim()
                      : 'Team Member';
                  final initials = computeInitials(name);
                  final roleColor = getRoleColor(role);

                  final newMember = TeamMember(
                    initials: initials,
                    name: name,
                    role: role,
                    roleColor: roleColor,
                  );

                  await StorageService.addMember(newMember);
                  if (onMemberAdded != null) {
                    onMemberAdded(newMember);
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx, newMember);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Team member "$name" added successfully!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Save Member', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );
}

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  List<CustomTeam> _teams = [];
  List<TeamMember> _memberList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final teams = await StorageService.loadTeams();
    final memberList = await StorageService.loadMembers();
    if (mounted) {
      setState(() {
        _teams = teams;
        _memberList = memberList;
      });
    }
  }

  Future<void> _openCreateTeam() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
    );
    if (created == true) _loadData();
  }

  Future<void> _openAddMember() async {
    final newMember = await showAddTeamMemberDialog(context);
    if (newMember != null) {
      _loadData();
    }
  }

  Future<void> _editTeam(CustomTeam team) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateTeamScreen(team: team)),
    );
    if (updated == true) _loadData();
  }

  Future<void> _deleteTeam(CustomTeam team) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team?'),
        content: Text('Are you sure you want to delete "${team.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.deleteTeam(team.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team "${team.name}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteMember(TeamMember m) async {
    final currentUser = AuthService.currentUser;
    if (currentUser != null && m.name.trim().toLowerCase() == currentUser.name.trim().toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account owner cannot be removed from the project.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove "${m.name}" from team members?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.deleteMember(m.name);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'team_members_add_fab',
        onPressed: _openAddMember,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              // Header
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('Team Members', style: AppText.headSemi.copyWith(fontSize: 17)),
                ),
              ),
              const SizedBox(height: 20),

              // Teams Section with Full Create, Edit, and Delete Support
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Teams (${_teams.length})', style: AppText.headSemi.copyWith(fontSize: 16)),
                  TextButton.icon(
                    onPressed: _openCreateTeam,
                    icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Create Team',
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_teams.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Center(
                    child: Text(
                      'No teams created yet. Tap "Create Team" to form one.',
                      style: AppText.caption.copyWith(color: AppColors.inkMuted),
                    ),
                  ),
                )
              else
                for (final t in _teams)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: AppDecor.card(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _editTeam(t),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.name, style: AppText.headSemi.copyWith(fontSize: 15)),
                                      Text('${t.memberNames.length} members', style: AppText.bodySoft.copyWith(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkMuted, size: 20),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _editTeam(t);
                                    } else if (val == 'delete') {
                                      _deleteTeam(t);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18, color: AppColors.ink),
                                          SizedBox(width: 10),
                                          Text('Edit Team'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                          SizedBox(width: 10),
                                          Text('Delete Team', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final name in t.memberNames)
                                  Chip(
                                    label: Text(name, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 16),

              Text(
                '${_memberList.length} people on this project',
                style: AppText.bodySoft.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Avatar strip with '+' add member card
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Plus Add Member avatar card
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: InkWell(
                        onTap: _openAddMember,
                        borderRadius: BorderRadius.circular(26),
                        child: SizedBox(
                          width: 56,
                          child: Column(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 1.5),
                                  color: AppColors.primaryTint,
                                ),
                                child: const Icon(Icons.add, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (final m in _memberList)
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: InkWell(
                          onTap: () {
                            final activeUserName = AuthService.currentUser?.name.trim().toLowerCase() ?? '';
                            final isSelf = activeUserName.isNotEmpty && m.name.trim().toLowerCase() == activeUserName;
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => ProfileScreen(member: m, isCurrentUser: isSelf)),
                            );
                          },
                          borderRadius: BorderRadius.circular(26),
                          child: SizedBox(
                            width: 56,
                            child: Column(
                              children: [
                                MemberAvatar(member: m, size: 52),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    final activeUserName = AuthService.currentUser?.name.trim().toLowerCase() ?? '';
                                    final isSelf = activeUserName.isNotEmpty && m.name.trim().toLowerCase() == activeUserName;
                                    return Text(
                                      isSelf ? 'You' : m.name.split(' ').first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.caption.copyWith(
                                        fontWeight: isSelf ? FontWeight.w700 : FontWeight.w400,
                                        color: isSelf ? AppColors.primary : null,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All members (${_memberList.length})', style: AppText.headSemi.copyWith(fontSize: 16)),
                  TextButton.icon(
                    onPressed: _openAddMember,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Add Member',
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final activeUserName = AuthService.currentUser?.name.trim().toLowerCase() ?? '';
                  return Column(
                    children: [
                      for (final m in _memberList)
                        _MemberRow(
                          member: m,
                          isCurrentUser: activeUserName.isNotEmpty && m.name.trim().toLowerCase() == activeUserName,
                          onDelete: () => _deleteMember(m),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final TeamMember member;
  final bool isCurrentUser;
  final VoidCallback? onDelete;
  const _MemberRow({
    required this.member,
    this.isCurrentUser = false,
    this.onDelete,
  });

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
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  member: member,
                  isCurrentUser: isCurrentUser,
                ),
              ),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              style: AppText.headSemi.copyWith(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkMuted, size: 20),
                  onSelected: (val) {
                    if (val == 'view') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            member: member,
                            isCurrentUser: isCurrentUser,
                          ),
                        ),
                      );
                    } else if (val == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 18, color: AppColors.ink),
                          SizedBox(width: 10),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    if (!isCurrentUser)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Remove Member', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}