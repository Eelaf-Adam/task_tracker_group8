import 'package:flutter/material.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/dashboard.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case signin:
        return MaterialPageRoute(builder: (_) => const SigninScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}