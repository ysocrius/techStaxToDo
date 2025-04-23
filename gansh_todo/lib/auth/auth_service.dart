import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthService extends ChangeNotifier {
  AuthStatus _authStatus = AuthStatus.loading;
  User? _user;
  String? _error;
  bool _isInitialized = false;
  Stream<AuthState>? _authStateSubscription;

  AuthStatus get authStatus => _authStatus;
  User? get user => _user;
  String? get error => _error;

  AuthService() {
    _initializeService();
  }
  
  // Initialize as a separate method for better control
  Future<void> _initializeService() async {
    if (_isInitialized) return;
    
    try {
      // Listen to auth state changes
      _setupAuthListener();
      
      // Set initialized to true
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize auth service: $e';
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
  
  void _setupAuthListener() {
    try {
      _authStateSubscription = SupabaseService.client.auth.onAuthStateChange;
      
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data.event, data.session);
      });
    } catch (e) {
      print('Error setting up auth listener: $e');
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
  
  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    switch (event) {
      case AuthChangeEvent.signedIn:
        _user = session?.user;
        _authStatus = AuthStatus.authenticated;
        break;
      case AuthChangeEvent.signedOut:
        _user = null;
        _authStatus = AuthStatus.unauthenticated;
        break;
      case AuthChangeEvent.userUpdated:
        _user = session?.user;
        break;
      default:
        // Handle initialSession and any other events
        if (session != null) {
          _user = session.user;
          _authStatus = AuthStatus.authenticated;
        } else {
          _authStatus = AuthStatus.unauthenticated;
        }
        break;
    }
    
    notifyListeners();
  }

  // Check if user is already logged in
  Future<void> checkAuth() async {
    if (_authStatus != AuthStatus.loading) return;
    
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        _user = user;
        _authStatus = AuthStatus.authenticated;
      } else {
        _authStatus = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _error = e.toString();
    }
    
    notifyListeners();
  }

  // Sign up with loading state management
  Future<bool> signUp(String email, String password) async {
    if (_authStatus == AuthStatus.loading) {
      return false; // Prevent multiple concurrent operations
    }
    
    try {
      _authStatus = AuthStatus.loading;
      notifyListeners();

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        _authStatus = AuthStatus.authenticated;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _authStatus = AuthStatus.unauthenticated;
        _error = 'Sign up failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign in with loading state management
  Future<bool> signIn(String email, String password) async {
    if (_authStatus == AuthStatus.loading) {
      return false; // Prevent multiple concurrent operations
    }
    
    try {
      _authStatus = AuthStatus.loading;
      notifyListeners();

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        _authStatus = AuthStatus.authenticated;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _authStatus = AuthStatus.unauthenticated;
        _error = 'Sign in failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign out with safety
  Future<bool> signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      _user = null;
      _authStatus = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  @override
  void dispose() {
    // Clean up resources
    _isInitialized = false;
    super.dispose();
  }
} 
