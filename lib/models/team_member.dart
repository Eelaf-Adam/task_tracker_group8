import '../theme/app_theme.dart';

RoleColor getRoleColor(String role) {
  final lower = role.toLowerCase();
  if (lower.contains('manager') || lower.contains('lead') || lower.contains('pm')) {
    return RoleColor.projectManager;
  }
  if (lower.contains('design') || lower.contains('ui') || lower.contains('ux')) {
    return RoleColor.designer;
  }
  if (lower.contains('develop') ||
      lower.contains('engineer') ||
      lower.contains('mobile') ||
      lower.contains('frontend') ||
      lower.contains('backend')) {
    return RoleColor.developer;
  }
  if (lower.contains('qa') || lower.contains('test')) {
    return RoleColor.qa;
  }
  if (lower.contains('doc') || lower.contains('writer') || lower.contains('content')) {
    return RoleColor.docs;
  }
  return RoleColor.developer;
}

String computeInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'TM';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.last.isNotEmpty ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  } else if (trimmed.length >= 2) {
    return trimmed.substring(0, 2).toUpperCase();
  }
  return trimmed.toUpperCase();
}

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

  Map<String, dynamic> toJson() => {
        'initials': initials,
        'name': name,
        'role': role,
      };

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final role = json['role'] as String? ?? 'Contributor';
    final initials = json['initials'] as String? ?? computeInitials(name);
    return TeamMember(
      initials: initials,
      name: name,
      role: role,
      roleColor: getRoleColor(role),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;
}

const defaultMembers = <TeamMember>[
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
];

List<TeamMember> members = List<TeamMember>.from(defaultMembers);
