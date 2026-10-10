import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String name;
  final String email;
  final String password;

  const AppUser({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );
}

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';

  // In-memory cache for fast access
  static AppUser? _activeUser;

  static AppUser? get currentUser => _activeUser;

  /// Load current active user session if exists
  static Future<AppUser?> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      try {
        _activeUser = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    return _activeUser;
  }

  /// Get all registered users from storage
  static Future<List<AppUser>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_usersKey);
    if (data == null || data.isEmpty) {
      // Seed an initial demo account so test sign-ins work if needed
      final seedUsers = [
        const AppUser(
          name: 'Lee',
          email: 'lee@example.com',
          password: 'Password1!',
        ),
      ];
      await prefs.setString(
        _usersKey,
        jsonEncode(seedUsers.map((u) => u.toJson()).toList()),
      );
      return seedUsers;
    }
    try {
      final list = jsonDecode(data) as List;
      return list.map((item) => AppUser.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Check whether an email is already registered
  static Future<bool> isUserRegistered(String email) async {
    final users = await getRegisteredUsers();
    final normalized = email.trim().toLowerCase();
    return users.any((u) => u.email.trim().toLowerCase() == normalized);
  }

  /// Register a brand new user
  static Future<({bool success, String message, AppUser? user})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getRegisteredUsers();
    final normalizedEmail = email.trim().toLowerCase();

    if (users.any((u) => u.email.trim().toLowerCase() == normalizedEmail)) {
      return (
        success: false,
        message: 'An account with this email already exists. Please sign in.',
        user: null,
      );
    }

    final newUser = AppUser(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
    );
    users.add(newUser);

    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );

    await setCurrentUser(newUser);

    return (
      success: true,
      message: 'Account created successfully!',
      user: newUser,
    );
  }

  /// Sign in an existing user
  static Future<({bool success, String message, AppUser? user})> signIn({
    required String email,
    required String password,
  }) async {
    final users = await getRegisteredUsers();
    final normalizedEmail = email.trim().toLowerCase();

    final found = users.where((u) => u.email.trim().toLowerCase() == normalizedEmail).toList();

    if (found.isEmpty) {
      return (
        success: false,
        message: 'No account found with this email. Please sign up first.',
        user: null,
      );
    }

    final existingUser = found.first;
    if (existingUser.password != password) {
      return (
        success: false,
        message: 'Incorrect password. Please try again.',
        user: null,
      );
    }

    await setCurrentUser(existingUser);

    return (
      success: true,
      message: 'Welcome back, ${existingUser.name}!',
      user: existingUser,
    );
  }

  /// Reset password for an existing local account
  static Future<({bool success, String message})> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getRegisteredUsers();
    final normalizedEmail = email.trim().toLowerCase();

    final index = users.indexWhere((u) => u.email.trim().toLowerCase() == normalizedEmail);
    if (index == -1) {
      return (
        success: false,
        message: 'No registered account found with this email.',
      );
    }

    final existing = users[index];
    final updatedUser = AppUser(
      name: existing.name,
      email: existing.email,
      password: newPassword,
    );
    users[index] = updatedUser;

    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );

    if (_activeUser != null && _activeUser!.email.trim().toLowerCase() == normalizedEmail) {
      await setCurrentUser(updatedUser);
    }

    return (
      success: true,
      message: 'Password has been reset successfully!',
    );
  }

  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  /// Check whether remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? true;
  }

  /// Get the saved email for remember me
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedEmailKey);
  }

  /// Save remember me preference and email
  static Future<void> saveRememberMe({required bool enabled, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, enabled);
    if (enabled) {
      await prefs.setString(_savedEmailKey, email.trim());
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  /// Set the active current user
  static Future<void> setCurrentUser(AppUser user) async {
    _activeUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  /// Log out
  static Future<void> signOut() async {
    _activeUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}
