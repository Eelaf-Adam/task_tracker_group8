import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker_group8/models/app_activity.dart';
import 'package:task_tracker_group8/screens/profile/profile_screen.dart';
import 'package:task_tracker_group8/screens/team/team_members_screen.dart';
import 'package:task_tracker_group8/services/auth_service.dart';
import 'package:task_tracker_group8/services/storage_service.dart';
import 'package:task_tracker_group8/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TeamMember & StorageService Tests', () {
    test('Default members are initialized and loaded correctly', () async {
      final membersList = await StorageService.loadMembers();
      expect(membersList.length, greaterThanOrEqualTo(2));
      expect(membersList.any((m) => m.name == 'Sarah Lee'), isTrue);
      expect(membersList.any((m) => m.name == 'John Doe'), isTrue);
    });

    test('User can add custom team member, initials/color are computed and saved', () async {
      final newMember = TeamMember(
        initials: computeInitials('Alex Rivers'),
        name: 'Alex Rivers',
        role: 'Mobile Developer',
        roleColor: getRoleColor('Mobile Developer'),
      );

      expect(newMember.initials, 'AR');
      await StorageService.addMember(newMember);

      final reloaded = await StorageService.loadMembers();
      expect(reloaded.any((m) => m.name == 'Alex Rivers'), isTrue);

      // Verify activity was automatically logged for the new member
      final activities = await StorageService.loadActivities();
      expect(activities.any((a) => a.action == 'added team member' && a.targetTitle == 'Alex Rivers'), isTrue);
    });

    test('User can delete custom team member', () async {
      final member = TeamMember(
        initials: 'JD',
        name: 'Temporary User',
        role: 'Tester',
        roleColor: getRoleColor('Tester'),
      );
      await StorageService.addMember(member);
      var list = await StorageService.loadMembers();
      expect(list.any((m) => m.name == 'Temporary User'), isTrue);

      await StorageService.deleteMember('Temporary User');
      list = await StorageService.loadMembers();
      expect(list.any((m) => m.name == 'Temporary User'), isFalse);
    });

    test('User can create, update, and delete teams in StorageService', () async {
      final team = const CustomTeam(
        id: 'team_dev_test',
        name: 'Mobile Core',
        memberNames: ['Alex Rivers', 'Sarah Lee'],
      );
      await StorageService.addTeam(team);

      var teams = await StorageService.loadTeams();
      expect(teams.any((t) => t.id == 'team_dev_test' && t.name == 'Mobile Core'), isTrue);

      // Update team
      final updatedTeam = const CustomTeam(
        id: 'team_dev_test',
        name: 'Mobile Core & Web',
        memberNames: ['Alex Rivers', 'Sarah Lee', 'John Doe'],
      );
      await StorageService.updateTeam(updatedTeam);

      teams = await StorageService.loadTeams();
      expect(teams.any((t) => t.id == 'team_dev_test' && t.name == 'Mobile Core & Web'), isTrue);
      expect(teams.firstWhere((t) => t.id == 'team_dev_test').memberNames.length, 3);

      // Delete team
      await StorageService.deleteTeam('team_dev_test');
      teams = await StorageService.loadTeams();
      expect(teams.any((t) => t.id == 'team_dev_test'), isFalse);
    });

    test('Signed in user is automatically included among team members', () async {
      await AuthService.setCurrentUser(const AppUser(
        name: 'Eelaf',
        email: 'eelaf@lead.com',
        password: 'Pass123!',
      ));

      final memberList = await StorageService.loadMembers();
      expect(memberList.any((m) => m.name == 'Eelaf'), isTrue);
      expect(memberList.first.name, 'Eelaf');
      expect(memberList.first.role, 'Project Lead');
    });
  });

  group('AppActivity & Activity Logging Tests', () {
    test('Initial activities are loaded when empty', () async {
      final activities = await StorageService.loadActivities();
      expect(activities.isNotEmpty, isTrue);
      expect(activities.any((a) => a.targetTitle == 'Application Design'), isTrue);
    });

    test('Logging an activity persists and prepends it to the activity list', () async {
      await StorageService.logActivity(
        action: 'completed task',
        targetTitle: 'New Awesome Feature',
        taskId: 'task_99',
        userName: 'Lee',
      );

      final list = await StorageService.loadActivities();
      expect(list.first.action, 'completed task');
      expect(list.first.targetTitle, 'New Awesome Feature');
      expect(list.first.userName, 'Lee');
      expect(list.first.timeAgo, 'Just now');
    });

    test('AppActivity timeAgo handles multiple relative intervals', () {
      final now = DateTime.now();

      final justNow = AppActivity(
        id: '1',
        userName: 'User',
        action: 'did',
        targetTitle: 'Task',
        timestamp: now.subtract(const Duration(seconds: 20)),
      );
      expect(justNow.timeAgo, 'Just now');

      final minutesAgo = AppActivity(
        id: '2',
        userName: 'User',
        action: 'did',
        targetTitle: 'Task',
        timestamp: now.subtract(const Duration(minutes: 15)),
      );
      expect(minutesAgo.timeAgo, '15m ago');

      final hoursAgo = AppActivity(
        id: '3',
        userName: 'User',
        action: 'did',
        targetTitle: 'Task',
        timestamp: now.subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.timeAgo, '3h ago');

      final yesterday = AppActivity(
        id: '4',
        userName: 'User',
        action: 'did',
        targetTitle: 'Task',
        timestamp: now.subtract(const Duration(days: 1)),
      );
      expect(yesterday.timeAgo, 'Yesterday');
    });
  });

  group('TeamMembersScreen Widget Tests', () {
    testWidgets('Displays team members list and opens add member dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TeamMembersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check header title and member count are displayed
      expect(find.text('Team Members'), findsOneWidget);
      expect(find.textContaining('people on this project'), findsOneWidget);
      expect(find.text('Sarah Lee'), findsWidgets);

      // Tap "Add Member" button to open the modal dialog
      await tester.tap(find.text('Add Member').first);
      await tester.pumpAndSettle();

      // Verify the dialog is opened
      expect(find.text('Add Team Member'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Save Member'), findsOneWidget);

      // Enter name and submit
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Alex Rivers'), 'Clara Barton');
      await tester.tap(find.text('Save Member'));
      await tester.pumpAndSettle();

      // Verify member is saved in storage
      final loadedMembers = await StorageService.loadMembers();
      expect(loadedMembers.any((m) => m.name == 'Clara Barton'), isTrue);

      // Drag vertical ListView to bring newly added member into view
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Clara Barton'), findsOneWidget);
    });

    testWidgets('ProfileScreen distinguishes signed-in user from team member', (WidgetTester tester) async {
      await AuthService.setCurrentUser(const AppUser(
        name: 'Eelaf',
        email: 'eelaf@test.com',
        password: 'Pass123!',
      ));

      final member = TeamMember(
        initials: 'SL',
        name: 'Sarah Lee',
        role: 'Product Designer',
        roleColor: RoleColor.designer,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(member: member, isCurrentUser: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Member Profile'), findsOneWidget);
      expect(find.text('Sarah Lee'), findsOneWidget);
      expect(find.textContaining('Assigned Tasks'), findsOneWidget);
      expect(find.text('Application Design'), findsOneWidget);
      expect(find.text('Edit profile'), findsNothing);
      expect(find.text('Log Out'), findsNothing);
    });
  });
}
