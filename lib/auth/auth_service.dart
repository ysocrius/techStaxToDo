import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// Define valid auth states
enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

// Define auth events including initialSession
// This ensures compatibility with the API
class CustomAuthChangeEvent {
  static const signedIn = AuthChangeEvent.signedIn;
  static const signedOut = AuthChangeEvent.signedOut;
  static const userUpdated = AuthChangeEvent.userUpdated;
  static const initialSession = AuthChangeEvent('INITIAL_SESSION');
  
  static AuthChangeEvent fromString(String event) {
    switch (event) {
      case 'INITIAL_SESSION':
        return initialSession;
      default:
        return AuthChangeEvent(event);
    }
  }
}

class AuthService extends ChangeNotifier {
  // ... existing code ...
  
  // In the onAuthStateChange listener, replace:
  // case AuthChangeEvent.initialSession:
  // with:
  // case CustomAuthChangeEvent.initialSession:
  
  // ... rest of the code ... 
} 