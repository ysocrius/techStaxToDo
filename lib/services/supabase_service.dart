channel.on(
  RealtimeListenTypes.postgresChanges,
  PostgresChangeFilter(
    event: '*',
    schema: 'public',
    table: 'tasks',
  ),
  (payload, [ref]) {
    // Handle payload
    // ... existing code ...
  },
); 

RealtimeChannel subscribeToTasks(void Function(List<Task>) onTasksUpdate) {
  final channel = _client.channel('public:tasks');

  channel.on(
    RealtimeListenTypes.postgresChanges,
    PostgresChangeFilter(
      schema: 'public',
      table: 'tasks',
      event: '*',
    ),
    // ... existing code ...
  );

  return channel;
} 