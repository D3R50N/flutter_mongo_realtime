import 'package:flutter/material.dart';
import 'package:flutter_mongo_realtime/flutter_mongo_realtime.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to the MongoRealtime backend.
  // In Flutter, this automatically sets up:
  // 1. Offline disk cache (persisted to Documents directory).
  // 2. App lifecycle monitoring (pauses socket in background).
  await MongoRealtime.connect(
    'ws://localhost:3000',
    persistToDisk: true,
    autoLifecycle: true,
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MongoRealtime Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00ED64), // MongoDB green
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const TasksPage(),
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TextEditingController _textController = TextEditingController();

  RealtimeCollectionReference get _tasksCol =>
      MongoRealtime.client.collection('tasks');

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addTask() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Task description...'),
          onSubmitted: (_) {
            _submitTask();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _submitTask();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _submitTask() {
    final title = _textController.text.trim();
    if (title.isEmpty) return;

    _tasksCol.insert({
      'title': title,
      'completed': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!MongoRealtime.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('MongoRealtime Tasks')),
        body: const Center(child: Text('Connecting to MongoRealtime...')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MongoRealtime Tasks'),
        actions: [
          // Connection Status indicator using RealtimeStatusBuilder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RealtimeStatusBuilder(
              builder: (context, status) {
                final color = switch (status) {
                  RealtimeConnectionStatus.connected => Colors.green,
                  RealtimeConnectionStatus.reconnecting => Colors.orange,
                  RealtimeConnectionStatus.paused => Colors.amber,
                  RealtimeConnectionStatus.disconnected => Colors.red,
                };

                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: color),
                        const SizedBox(width: 6),
                        Text(
                          status.name.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: RealtimeBuilder.queryValues(
        query: _tasksCol.where('completed', isEqualTo: false).limit(50),
        loadingBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        emptyBuilder: (context) => const Center(
          child: Text(
            'No active tasks. Tap + to add one!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        errorBuilder: (context, error, stack) => Center(
          child: Text(
            'Error: $error stack $stack',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        builder: (context, tasks) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final id = task['_id']?.toString() ?? '';
              final title = task['title']?.toString() ?? '';
              final isDone = task['completed'] == true;

              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: Checkbox(
                    value: isDone,
                    onChanged: (checked) {
                      _tasksCol
                          .doc(id)
                          .update($set: {'completed': checked ?? false});
                    },
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _tasksCol.doc(id).delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
