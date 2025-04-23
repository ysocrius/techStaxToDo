import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/task_model.dart';

class SupabaseService {
  static final String supabaseUrl = 'https://ahhqnmpqecpsqhxdclxl.supabase.co';
  static final String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFoaHFubXBxZWNwc3FoeGRjbHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxMzI5NDgsImV4cCI6MjA2MDcwODk0OH0.5nkxBZWutp_OgA5B7mTdp9BXMR56rKmBCO8PPhMun9c';
  static late final SupabaseClient _client;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
    } catch (e) {
      print('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client;
  }

  // Authentication methods
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Task CRUD operations with optimizations
  Future<List<Task>> getTasks() async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((task) => Task.fromJson(task)).toList();
    } catch (e) {
      print('Error fetching tasks: $e');
      return []; // Return empty list instead of crashing
    }
  }

  Future<Task?> createTask(String title) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      
      final response = await _client.from('tasks').insert({
        'title': title,
        'user_id': userId,
        'is_completed': false,
      }).select();
      
      return response.isNotEmpty ? Task.fromJson(response[0]) : null;
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      await _client.from('tasks').update({
        'title': task.title,
        'is_completed': task.isCompleted,
      }).eq('id', task.id);
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await _client.from('tasks').delete().eq('id', taskId);
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // Optimized subscription for real-time updates
  RealtimeChannel? _activeChannel;
  
  RealtimeChannel subscribeToTasks(void Function(List<Task>) onTasksUpdate) {
    // Close any existing channel before creating a new one
    if (_activeChannel != null) {
      try {
        _activeChannel!.unsubscribe();
      } catch (e) {
        print('Error unsubscribing from channel: $e');
      }
    }
    
    final channel = _client.channel('public:tasks');
    _activeChannel = channel;
    
    // Set up the channel with error handling
    try {
      channel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',
          schema: 'public',
          table: 'tasks',
        ),
        (payload, [ref]) async {
          // Only fetch tasks if the channel is still active
          if (channel.presence.state == 'joined') {
            try {
              final tasks = await getTasks();
              onTasksUpdate(tasks);
            } catch (e) {
              print('Error in realtime update: $e');
            }
          }
        },
      );
      
      // Use proper signature for error handling
      channel.onError((error) {
        print('Channel error: $error');
      });
      
      channel.subscribe();
    } catch (e) {
      print('Error setting up channel: $e');
    }
    
    return channel;
  }

  void unsubscribeFromTasks(RealtimeChannel channel) {
    try {
      channel.unsubscribe();
      if (_activeChannel == channel) {
        _activeChannel = null;
      }
    } catch (e) {
      print('Error unsubscribing from tasks: $e');
    }
  }
} 
