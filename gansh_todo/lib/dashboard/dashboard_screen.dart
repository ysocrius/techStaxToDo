import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_service.dart';
import '../dashboard/task_model.dart';
import '../dashboard/task_tile.dart';
import '../services/supabase_service.dart';
import '../utils/validators.dart';
import '../app/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isSubscribed = false;
  String? _error;
  RealtimeChannel? _tasksChannel;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid blocking UI
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    // Use a microtask to ensure it runs after the frame is rendered
    Future.microtask(() {
      _loadTasks();
      // Don't subscribe immediately - wait for tasks to load first
    });
  }

  @override
  void dispose() {
    _unsubscribeFromTasksChanges();
    super.dispose();
  }
  
  void _subscribeToTasksChanges() {
    if (_isSubscribed) return;
    
    try {
      _tasksChannel = _supabaseService.subscribeToTasks((updatedTasks) {
        if (mounted) {
          setState(() {
            _tasks = updatedTasks;
          });
        }
      });
      _isSubscribed = true;
    } catch (e) {
      print("Error subscribing to tasks: $e");
      // Will try again on refresh
    }
  }

  void _unsubscribeFromTasksChanges() {
    if (_tasksChannel != null) {
      try {
        _supabaseService.unsubscribeFromTasks(_tasksChannel!);
        _isSubscribed = false;
      } catch (e) {
        print("Error unsubscribing from tasks: $e");
      }
    }
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _supabaseService.getTasks();
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
        
        // Now that tasks are loaded, subscribe to changes
        if (!_isSubscribed) {
          _subscribeToTasksChanges();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    // Optimistic update
    final originalTask = task;
    final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
    
    if (currentIndex != -1) {
      setState(() {
        _tasks[currentIndex] = task.copyWith(isCompleted: !task.isCompleted);
      });
    }
    
    try {
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      final success = await _supabaseService.updateTask(updatedTask);
      
      if (!success && mounted) {
        // Revert on failure
        setState(() {
          if (currentIndex != -1) {
            _tasks[currentIndex] = originalTask;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert on error
        setState(() {
          if (currentIndex != -1) {
            _tasks[currentIndex] = originalTask;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    // Store task in case we need to restore it
    final deletedTaskIndex = _tasks.indexWhere((t) => t.id == taskId);
    Task? deletedTask;
    
    if (deletedTaskIndex != -1) {
      deletedTask = _tasks[deletedTaskIndex];
      // Optimistic UI update
      setState(() {
        _tasks.removeAt(deletedTaskIndex);
      });
    }
    
    try {
      final success = await _supabaseService.deleteTask(taskId);
      
      if (!success && mounted && deletedTask != null) {
        // Restore the task on failure
        setState(() {
          _tasks.insert(deletedTaskIndex, deletedTask!);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete task. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted && deletedTask != null) {
        // Restore the task on error
        setState(() {
          _tasks.insert(deletedTaskIndex, deletedTask!);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addNewTask() async {
    final textController = TextEditingController();
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add New Task',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.validateTaskTitle,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (textController.text.isNotEmpty) {
                    Navigator.pop(context);
                    try {
                      await _supabaseService.createTask(textController.text);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create task: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Add Task'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editTask(Task task) async {
    final textController = TextEditingController(text: task.title);
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Task',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.validateTaskTitle,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (textController.text.isNotEmpty) {
                    Navigator.pop(context);
                    try {
                      final updatedTask = task.copyWith(
                        title: textController.text,
                      );
                      await _supabaseService.updateTask(updatedTask);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update task: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Update Task'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          // Theme toggle
          provider_pkg.Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: 'Toggle theme',
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = provider_pkg.Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTasks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first task to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addNewTask,
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Task'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return TaskTile(
                            task: task,
                            onToggleComplete: (_) => _toggleTaskCompletion(task),
                            onEdit: () => _editTask(task),
                            onDelete: () => _confirmDelete(task),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _tasks.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addNewTask,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// Theme Provider class for toggling between light and dark themes
