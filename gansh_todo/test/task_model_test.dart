import 'package:flutter_test/flutter_test.dart';
import 'package:gansh_todo/dashboard/task_model.dart';

void main() {
  group('Task Model Tests', () {
    test('Task.fromJson creates a Task correctly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'user_id': '456e7890-e12b-34d5-a678-426614174111',
        'title': 'Test Task',
        'is_completed': false,
        'created_at': '2023-04-01T10:00:00.000Z',
      };

      final task = Task.fromJson(json);

      expect(task.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(task.userId, '456e7890-e12b-34d5-a678-426614174111');
      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);
      expect(task.createdAt, DateTime.parse('2023-04-01T10:00:00.000Z'));
    });

    test('Task.toJson converts Task to JSON correctly', () {
      final task = Task(
        id: '123e4567-e89b-12d3-a456-426614174000',
        userId: '456e7890-e12b-34d5-a678-426614174111',
        title: 'Test Task',
        isCompleted: false,
        createdAt: DateTime.parse('2023-04-01T10:00:00.000Z'),
      );

      final json = task.toJson();

      expect(json['id'], '123e4567-e89b-12d3-a456-426614174000');
      expect(json['user_id'], '456e7890-e12b-34d5-a678-426614174111');
      expect(json['title'], 'Test Task');
      expect(json['is_completed'], false);
      expect(json['created_at'], '2023-04-01T10:00:00.000Z');
    });

    test('Task.copyWith creates a new instance with updated fields', () {
      final task = Task(
        id: '123e4567-e89b-12d3-a456-426614174000',
        userId: '456e7890-e12b-34d5-a678-426614174111',
        title: 'Test Task',
        isCompleted: false,
        createdAt: DateTime.parse('2023-04-01T10:00:00.000Z'),
      );

      final updatedTask = task.copyWith(
        title: 'Updated Task',
        isCompleted: true,
      );

      // Original task should remain unchanged
      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);

      // Updated task should have new values
      expect(updatedTask.id, task.id); // Same ID
      expect(updatedTask.userId, task.userId); // Same user ID
      expect(updatedTask.title, 'Updated Task'); // Updated title
      expect(updatedTask.isCompleted, true); // Updated completion status
      expect(updatedTask.createdAt, task.createdAt); // Same creation date
    });
  });
} 