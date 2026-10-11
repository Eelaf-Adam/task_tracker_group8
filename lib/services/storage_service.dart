import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_activity.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../theme/app_theme.dart';
import 'auth_service.dart';

class CustomTeam {
  final String id;
  final String name;
  final List<String> memberNames;

  const CustomTeam({
    required this.id,
    required this.name,
    required this.memberNames,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberNames': memberNames,
      };

  factory CustomTeam.fromJson(Map<String, dynamic> json) => CustomTeam(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        memberNames: (json['memberNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class StorageService {
  static const _tasksKey = 'tasks';
  static const _teamsKey = 'custom_teams';
  static const _membersKey = 'team_members';
  static const _activitiesKey = 'app_activities';

  /// Initial sample tasks: limited to 3 tasks covering In Progress, To Do, and Done.
  static List<Task> _getInitialSeedTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: 'task_1',
        title: 'Application Design',
        description: 'UI Design Kit & interactive Figma screens for SLA Task Tracker.',
        assignedTo: 'Sarah Lee',
        dueDate: now.add(const Duration(days: 4)),
        priority: 'High',
        status: 'In Progress',
        isCompleted: false,
        startTime: '9:30 am',
        endTime: '3:30 pm',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 'task_2',
        title: 'Overlay Concept',
        description: 'Wireframe elements and high-fidelity overlay modal components.',
        assignedTo: 'John Doe',
        dueDate: now.add(const Duration(hours: 18)), // At Risk (within 48h risk window)
        priority: 'Medium',
        status: 'To Do',
        isCompleted: false,
        startTime: '10:00 am',
        endTime: '11:00 am',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'task_3',
        title: 'Create Task Model & Storage',
        description: 'Build backend model schemas and SLA status business logic.',
        assignedTo: 'Sarah Lee',
        dueDate: now.subtract(const Duration(days: 1)),
        priority: 'Low',
        status: 'Done',
        isCompleted: true,
        startTime: '1:00 pm',
        endTime: '2:30 pm',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(jsonList));
  }

  static Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_tasksKey);
      if (jsonString == null || jsonString.isEmpty) {
        final seed = _getInitialSeedTasks();
        await saveTasks(seed);
        return seed;
      }
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getInitialSeedTasks();
    }
  }

  static Future<void> addTask(Task task) async {
    final tasks = await loadTasks();
    tasks.insert(0, task);
    await saveTasks(tasks);
  }

  static Future<void> updateTask(Task updatedTask) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
  }

  static Future<void> deleteTask(String id) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == id);
    await saveTasks(tasks);
  }

  // --- Team Persistence ---

  static Future<List<CustomTeam>> loadTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_teamsKey);
      if (data == null || data.isEmpty) {
        final defaultTeam = [
          const CustomTeam(
            id: 'team_default',
            name: 'Team Align',
            memberNames: ['Sarah Lee', 'John Doe'],
          ),
        ];
        await saveTeams(defaultTeam);
        return defaultTeam;
      }
      final list = jsonDecode(data) as List;
      return list.map((j) => CustomTeam.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTeams(List<CustomTeam> teams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _teamsKey,
      jsonEncode(teams.map((t) => t.toJson()).toList()),
    );
  }

  static Future<void> addTeam(CustomTeam team) async {
    final teams = await loadTeams();
    teams.add(team);
    await saveTeams(teams);
  }

  static Future<void> updateTeam(CustomTeam updated) async {
    final teams = await loadTeams();
    final index = teams.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      teams[index] = updated;
      await saveTeams(teams);
      await logActivity(
        action: 'updated team',
        targetTitle: updated.name,
      );
    }
  }

  static Future<void> deleteTeam(String teamId) async {
    final teams = await loadTeams();
    final target = teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => const CustomTeam(id: '', name: '', memberNames: []),
    );
    teams.removeWhere((t) => t.id == teamId);
    await saveTeams(teams);
    if (target.name.isNotEmpty) {
      await logActivity(
        action: 'deleted team',
        targetTitle: target.name,
      );
    }
  }

  // --- Team Member Persistence ---

  static Future<List<TeamMember>> loadMembers() async {
    List<TeamMember> loaded;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_membersKey);
      if (data == null || data.isEmpty) {
        loaded = List<TeamMember>.from(defaultMembers);
        await saveMembers(loaded);
      } else {
        final list = jsonDecode(data) as List;
        loaded = list.map((j) => TeamMember.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      loaded = List<TeamMember>.from(defaultMembers);
    }

    // Ensure the signed-in user account is always among team members
    final activeUser = AuthService.currentUser;
    if (activeUser != null && activeUser.name.trim().isNotEmpty) {
      final userName = activeUser.name.trim();
      final exists = loaded.any((m) => m.name.toLowerCase() == userName.toLowerCase());
      if (!exists) {
        loaded.insert(
          0,
          TeamMember(
            initials: computeInitials(userName),
            name: userName,
            role: 'Project Lead',
            roleColor: RoleColor.projectManager,
          ),
        );
      }
    }

    members = List<TeamMember>.from(loaded);
    return loaded;
  }

  static Future<void> saveMembers(List<TeamMember> memberList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _membersKey,
      jsonEncode(memberList.map((m) => m.toJson()).toList()),
    );
    members = List<TeamMember>.from(memberList);
  }

  static Future<void> addMember(TeamMember member) async {
    final list = List<TeamMember>.from(await loadMembers());
    final existingIndex = list.indexWhere((m) => m.name.toLowerCase() == member.name.toLowerCase());
    if (existingIndex >= 0) {
      list[existingIndex] = member;
    } else {
      list.add(member);
    }
    await saveMembers(list);
    await logActivity(
      action: 'added team member',
      targetTitle: member.name,
    );
  }

  static Future<void> deleteMember(String name) async {
    final list = List<TeamMember>.from(await loadMembers());
    list.removeWhere((m) => m.name.toLowerCase() == name.toLowerCase());
    await saveMembers(list);
  }

  // --- App Activity Persistence ---

  static List<AppActivity> _getInitialSeedActivities() {
    final now = DateTime.now();
    return [
      AppActivity(
        id: 'act_1',
        userName: 'Sarah Lee',
        action: 'updated task',
        targetTitle: 'Application Design',
        timestamp: now.subtract(const Duration(minutes: 25)),
        taskId: 'task_1',
      ),
      AppActivity(
        id: 'act_2',
        userName: 'John Doe',
        action: 'created task',
        targetTitle: 'Overlay Concept',
        timestamp: now.subtract(const Duration(hours: 2)),
        taskId: 'task_2',
      ),
      AppActivity(
        id: 'act_3',
        userName: 'Sarah Lee',
        action: 'completed task',
        targetTitle: 'Create Task Model & Storage',
        timestamp: now.subtract(const Duration(hours: 5)),
        taskId: 'task_3',
      ),
    ];
  }

  static Future<List<AppActivity>> loadActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_activitiesKey);
      if (data == null || data.isEmpty) {
        final seed = _getInitialSeedActivities();
        await saveActivities(seed);
        return seed;
      }
      final list = jsonDecode(data) as List;
      return list.map((j) => AppActivity.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getInitialSeedActivities();
    }
  }

  static Future<void> saveActivities(List<AppActivity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activitiesKey,
      jsonEncode(activities.map((a) => a.toJson()).toList()),
    );
  }

  static Future<void> logActivity({
    required String action,
    required String targetTitle,
    String? taskId,
    String? userName,
  }) async {
    try {
      final activities = await loadActivities();
      final activeUser = AuthService.currentUser;
      final resolvedName = userName ??
          ((activeUser != null && activeUser.name.trim().isNotEmpty)
              ? activeUser.name.trim()
              : 'You');

      final newActivity = AppActivity(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        userName: resolvedName,
        action: action,
        targetTitle: targetTitle,
        timestamp: DateTime.now(),
        taskId: taskId,
      );
      activities.insert(0, newActivity);
      if (activities.length > 30) {
        activities.removeRange(30, activities.length);
      }
      await saveActivities(activities);
    } catch (_) {}
  }
}