import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/roadmap_card.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, required this.state});

  final AppState state;

  Future<void> _addTask(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.trim().isNotEmpty) state.addTask(title.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskly'),
        actions: [
          // Example: the board as a bottom sheet.
          IconButton(
            tooltip: 'Ideas',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => Fewchurs.showBoardSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<List<Task>>(
        valueListenable: state.tasks,
        builder: (context, tasks, _) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const RoadmapCard(),
            for (final task in tasks)
              CheckboxListTile(
                value: task.done,
                onChanged: (_) => state.toggleTask(task),
                title: Text(
                  task.title,
                  style: task.done
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
