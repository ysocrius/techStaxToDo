import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'services/supabase_service.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with a loading indicator
  runApp(const AppLoader());
  
  // Initialize Supabase in background
  await SupabaseService.initialize();
  
  // After initialization, run the actual app
  runApp(const MyApp());
}

// Simple loading screen while initializing
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Loading app...'),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider_pkg.MultiProvider(
      providers: [
        // Lazy load providers to prevent startup bottlenecks
        provider_pkg.ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          lazy: false, // Theme needs to be available immediately
        ),
        provider_pkg.ChangeNotifierProvider(
          create: (_) => AuthService(),
          lazy: true, // Can be lazy loaded
        ),
      ],
      child: provider_pkg.Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Mini TaskHub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// Separate stateful widget to handle auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = provider_pkg.Provider.of<AuthService>(context);
    
    // If auth service is still initializing
    if (authService.authStatus == AuthStatus.loading) {
      // Trigger the auth check
      Future.microtask(() => authService.checkAuth());
      
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Navigate based on auth status
    return authService.authStatus == AuthStatus.authenticated
        ? const DashboardScreen()
        : const LoginScreen();
  }
}
