import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(
    "2iTJEwyajCoC6MJX8kAOdSDDpX3vS5W6e3NHAPId",
    'https://parseapi.back4app.com',
    clientKey: 'GacXUvGbgKW39wUUAjX1ZFnI4d4GHLpvUwfIvfki',
    autoSendSessionId: true,
    debug: false,
  );
  runApp(const MyApp());
}

class Task {
  String? objectId;
  String title;
  String description;
  bool completed;
  bool isExpanded; // Add an 'isExpanded' property

  Task({
    this.objectId,
    required this.title,
    required this.description,
    required this.completed,
    this.isExpanded = false, // Initialize isExpanded to false
  });

  Task copyWith(
      {String? objectId, String? title, String? description, bool? completed}) {
    return Task(
      objectId: objectId ?? this.objectId,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }
}

class TaskService {
  Future<Task> createTask(Task task) async {
    final taskObject = ParseObject('Task')
      ..set('title', task.title)
      ..set('description', task.description)
      ..set('completed', task.completed);

    final response = await taskObject.save();
    if (response.success) {
      final objectId = response.result.objectId;
      return task.copyWith(objectId: objectId);
    } else {
      throw Exception('Failed to create task');
    }
  }

  Future<List<Task>?> getTasks() async {
    final queryBuilder = QueryBuilder(ParseObject('Task'));
    final response = await queryBuilder.query();

    if (response.success) {
      final tasks = <Task>[];
      for (final object in response.results as List<dynamic>) {
        tasks.add(Task(
          objectId: object.objectId,
          title: object['title'],
          description: object['description'],
          completed: object['completed'] ?? false,
        ));
      }
      return tasks;
    } else {
      throw Exception('Failed to retrieve tasks');
    }
  }

  Future<void> deleteTask(Task task) async {
    final taskObject = ParseObject('Task')..set('objectId', task.objectId);
    final response = await taskObject.delete();
    if (!response.success) {
      throw Exception('Failed to delete task');
    }
  }

  Future<Task> updateTask(Task task) async {
    final taskObject = ParseObject('Task')
      ..set('objectId', task.objectId)
      ..set('title', task.title)
      ..set('description', task.description)
      ..set('completed', task.completed);

    final response = await taskObject.save();
    if (response.success) {
      return task;
    } else {
      throw Exception('Failed to update task');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'To-Do List App',
      home: TaskListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  TaskListScreenState createState() => TaskListScreenState();
}

class TaskListScreenState extends State<TaskListScreen> {
  final TaskService taskService = TaskService();
  List<Task> tasks = [];
  TextEditingController taskController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController editTaskController = TextEditingController();
  TextEditingController editDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final taskList = await taskService.getTasks();
    setState(() {
      tasks = taskList ?? [];
    });

    if (tasks.isEmpty) {
      _createDefaultTask();
    }
  }

  Future<void> _createDefaultTask() async {
    const newTaskTitle = 'Welcome to the To-Do List';
    const newTaskDescription =
        'Tap to edit or delete this task. Add new tasks below.';
    final newTask = Task(
      title: newTaskTitle,
      description: newTaskDescription,
      completed: false,
    );

    final createdTask = await taskService.createTask(newTask);

    setState(() {
      tasks.add(createdTask);
    });
  }

  void _editTask(Task task) {
    editTaskController.text = task.title;
    editDescriptionController.text = task.description;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: editTaskController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                controller: editDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: null, // Make it multiline
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                editTaskController.clear();
                editDescriptionController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedTitle = editTaskController.text;
                final updatedDescription = editDescriptionController.text;
                if (updatedTitle.isNotEmpty) {
                  final updatedTask = task.copyWith(
                    title: updatedTitle,
                    description: updatedDescription,
                  );
                  taskService.updateTask(updatedTask).then((_) {
                    setState(() {
                      task.title = updatedTitle;
                      task.description = updatedDescription;
                    });
                    Navigator.of(context).pop();
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                taskService.deleteTask(task).then((_) {
                  setState(() {
                    tasks.remove(task);
                  });
                  Navigator.of(context).pop();
                });
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _addTask() {
    taskController.clear();
    descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: taskController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: null, // Make it multiline
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                taskController.clear();
                descriptionController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTaskTitle = taskController.text;
                final newTaskDescription = descriptionController.text;
                if (newTaskTitle.isNotEmpty) {
                  taskService
                      .createTask(Task(
                    title: newTaskTitle,
                    description: newTaskDescription,
                    completed: false,
                  ))
                      .then((newTask) {
                    setState(() {
                      tasks.add(newTask);
                    });
                    Navigator.of(context).pop();
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Todo-List',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              Text(
                'Cross Platform Application Assignment 1',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ExpansionTile(
                  title: Text(task.title),
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      task.isExpanded = isExpanded;
                    });
                  },
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        task.isExpanded
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                      ),
                      Checkbox(
                        value: task.completed,
                        onChanged: (value) {
                          taskService
                              .updateTask(task.copyWith(completed: value))
                              .then((updatedTask) {
                            setState(() {
                              tasks[index] = updatedTask;
                            });
                          });
                        },
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editTask(task);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteTask(task);
                        },
                      ),
                    ],
                  ),
                  children: <Widget>[
                    ListTile(
                      title: Text(task.description),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Transform(
        transform: Matrix4.translationValues(0.0, 0.0, 0.0),
        // Adjust values for the 3D effect
        child: FloatingActionButton(
          onPressed: _addTask,
          tooltip: 'Create Task',
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Adjust if needed
      // Add a bottom navigation bar for the footer
      bottomNavigationBar: const BottomAppBar(
        color: Colors.blueGrey, // Set the background color
        child: SizedBox(
          height: 50, // Set the desired height
          child: Center(
            child: Text(
              "Assignment Submitted by: Raghavendra Raj  \t 2022mt93541 \nAssignment Submitted to: Prof. Chandan R N ",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
