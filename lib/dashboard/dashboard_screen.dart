import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;
import '../app/theme.dart';
import '../auth/auth_service.dart';

// In the AppBar actions:
actions: [
  // Theme toggle button
  Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) => IconButton(
      icon: Icon(
        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () => themeProvider.toggleTheme(),
    ),
  ),
  // ... other actions ...
],

// Fix Provider.of to use the correct Provider
final authService = Provider.of<AuthService>(context, listen: false); 