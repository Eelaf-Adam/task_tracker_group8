import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TaskkeyApp());
}

class TaskkeyApp extends StatelessWidget {
  const TaskkeyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskkey - Project & SLA Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}