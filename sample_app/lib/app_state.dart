import 'package:flutter/material.dart';

class Task {
  Task(this.title, {this.done = false});

  final String title;
  bool done;
}

class AppState {
  final themeMode = ValueNotifier(ThemeMode.system);
  final isPro = ValueNotifier(false);
  final email = ValueNotifier<String?>(null);
  final tasks = ValueNotifier<List<Task>>([
    Task('Plan the week'),
    Task('Reply to design feedback'),
    Task('Book dentist', done: true),
  ]);

  void addTask(String title) => tasks.value = [...tasks.value, Task(title)];

  void toggleTask(Task task) {
    task.done = !task.done;
    tasks.value = [...tasks.value];
  }
}
