# Mini TaskHub - Flutter Todo App

A modern, responsive todo app built with Flutter and Supabase for the backend. This app features user authentication, task management, real-time updates, and theme switching.

## Features

- 🔒 User authentication (login and signup)
- ✅ Create, read, update, and delete tasks
- 🌓 Toggle between light and dark theme
- 🔄 Real-time updates using Supabase Realtime
- 📱 Responsive UI with custom design

## Screenshots

*Screenshots will be added here*

## Setup Instructions

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK
- VS Code, Android Studio, or any preferred IDE
- Git

### Installation Steps

1. Clone the repository:
   ```
   git clone <repository-url>
   cd gansh_todo
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```

### Supabase Setup Steps

1. Create a Supabase account at [https://supabase.com/](https://supabase.com/)
2. Create a new project
3. Set up database tables:
   - Create a `tasks` table with the following columns:
     - `id` (uuid, primary key)
     - `user_id` (uuid, foreign key to auth.users)
     - `title` (text)
     - `is_completed` (boolean, default: false)
     - `created_at` (timestamp with time zone, default: now())

4. Set up Row Level Security (RLS):
   - Enable RLS on the `tasks` table
   - Create policies for:
     - SELECT: Allow users to read their own tasks
     - INSERT: Allow users to create their own tasks
     - UPDATE: Allow users to update their own tasks
     - DELETE: Allow users to delete their own tasks

5. Enable Email Authentication:
   - Go to Authentication > Providers
   - Enable Email provider
   - Customize settings as needed

6. Update the Supabase URL and anonymous key in the app:
   - Find these values in your Supabase project dashboard
   - Update them in `lib/services/supabase_service.dart`

## Project Structure

```
lib/
│
├── main.dart                  # App entry point
├── app/
│   └── theme.dart             # App theming
├── auth/
│   ├── login_screen.dart      # Login UI
│   ├── signup_screen.dart     # Signup UI
│   └── auth_service.dart      # Authentication logic
├── dashboard/
│   ├── dashboard_screen.dart  # Main task list UI
│   ├── task_tile.dart         # Individual task widget
│   └── task_model.dart        # Task data model
├── services/
│   └── supabase_service.dart  # Supabase API integration
├── utils/
│   └── validators.dart        # Form validation utilities
```

## Hot Reload vs Hot Restart

### Hot Reload

**Hot Reload** allows you to inject updated source code into the running Dart VM. It updates the UI almost instantly without losing the current state of the app.

**When to use:**
- Making UI changes
- Adding new widgets
- Updating methods or functionalities that don't affect the current state

**Limitations:**
- Cannot add new classes or change class hierarchies
- State is preserved, so if you need to reset state, use Hot Restart
- Some changes may require Hot Restart to take effect

### Hot Restart

**Hot Restart** completely resets the state of the app and rebuilds it from scratch.

**When to use:**
- When you've made changes to the class structure
- When you need to reset app state
- When Hot Reload doesn't apply your changes properly
- When you've added new dependencies

**Key differences:**
- Hot Reload: Fast, preserves state, for UI changes
- Hot Restart: Slower, resets state, for structural changes

## Testing

Run the tests with:
```
flutter test
```

## Dependencies

- flutter
- provider
- supabase_flutter
- flutter_riverpod
- shared_preferences
- http

## License

This project is licensed under the MIT License.

## Acknowledgements

- Flutter team for the amazing framework
- Supabase for the backend solution
- All contributors who helped with this project
