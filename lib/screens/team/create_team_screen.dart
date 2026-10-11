import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import 'team_members_screen.dart';

/// Screen for creating or editing a team:
/// - Team Name input
/// - Team Member avatar picker with selection checkmarks and '+' button
/// - Supports team creation, editing existing teams, and deleting teams
class CreateTeamScreen extends StatefulWidget {
  final CustomTeam? team;
  const CreateTeamScreen({super.key, this.team});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _teamNameController;
  late final Set<String> _selectedMembers;
  List<TeamMember> _availableMembers = [];
  bool _isSaving = false;

  bool get _isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(text: widget.team?.name ?? 'Team Align');
    _selectedMembers = widget.team != null
        ? widget.team!.memberNames.toSet()
        : {'Sarah Lee', 'John Doe'};
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final list = await StorageService.loadMembers();
    if (mounted) {
      setState(() {
        _availableMembers = list;
        // If creating a new team and user is signed in, select user by default
        final user = AuthService.currentUser;
        if (!_isEditing && user != null && user.name.trim().isNotEmpty) {
          _selectedMembers.add(user.name.trim());
        }
      });
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  void _toggleMember(String name) {
    setState(() {
      if (_selectedMembers.contains(name)) {
        if (_selectedMembers.length > 1) {
          _selectedMembers.remove(name);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A team must have at least one member')),
          );
        }
      } else {
        _selectedMembers.add(name);
      }
    });
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one team member')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final team = CustomTeam(
        id: widget.team?.id ?? 'team_${DateTime.now().millisecondsSinceEpoch}',
        name: _teamNameController.text.trim(),
        memberNames: _selectedMembers.toList(),
      );

      if (_isEditing) {
        await StorageService.updateTeam(team);
      } else {
        await StorageService.addTeam(team);
        await StorageService.logActivity(
          action: 'created team',
          targetTitle: team.name,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Team "${team.name}" updated!' : 'Team "${team.name}" created!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save team. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTeam() async {
    if (!_isEditing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team?'),
        content: Text('Are you sure you want to delete "${widget.team!.name}"?'),
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
      await StorageService.deleteTeam(widget.team!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "${widget.team!.name}" deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUserName = AuthService.currentUser?.name.trim().toLowerCase() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.ink),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          _isEditing ? 'Edit Team' : 'Create Team',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Delete team',
              onPressed: _deleteTeam,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Team Name Label
                const Text(
                  'Team Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),

                // Team Name Input
                TextFormField(
                  controller: _teamNameController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter team name',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF6B60F5), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Team name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Team Member Label
                const Text(
                  'Team Members',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),

                // Horizontal Team Member Picker
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableMembers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _availableMembers.length) {
                        // Trailing '+' button to quickly add a new collaborator
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(26),
                                onTap: () async {
                                  final added = await showAddTeamMemberDialog(context);
                                  if (added != null && mounted) {
                                    setState(() {
                                      if (!_availableMembers.any((m) => m.name.toLowerCase() == added.name.toLowerCase())) {
                                        _availableMembers.add(added);
                                      }
                                      _selectedMembers.add(added.name);
                                    });
                                  }
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF6B60F5),
                                      width: 1.5,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Color(0xFF6B60F5),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final m = _availableMembers[index];
                      final isSelected = _selectedMembers.contains(m.name);
                      final isSelf = activeUserName.isNotEmpty && m.name.trim().toLowerCase() == activeUserName;

                      return Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(26),
                          onTap: () => _toggleMember(m.name),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF6B60F5) : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: MemberAvatar(member: m, size: 48),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF6B60F5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isSelf ? 'You' : m.name.split(' ').first,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? const Color(0xFF6B60F5) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 48),

                // Action Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6356F5),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF6356F5).withValues(alpha: 0.4),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveTeam,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Team',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
