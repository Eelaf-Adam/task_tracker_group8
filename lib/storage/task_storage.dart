import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskStorage {
  static const _key = 'tasks';

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((j) => Task.fromJson(j)).toList();
  }

  static Future<void> addTask(Task task) async {
    final tasks = await loadTasks();
    tasks.add(task);
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
}