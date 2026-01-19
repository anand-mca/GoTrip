import 'package:flutter/material.dart';
import '../models/user_model.dart' as models;
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isLoading = false;
  String? _error;
  models.AppUser? _user;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  models.AppUser? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    try {
      _supabaseService.authStateChanges().listen((authState) {
        print('🔐 Auth state changed: ${authState.session != null ? "Authenticated" : "Not authenticated"}');
        _isAuthenticated = authState.session != null;
        notifyListeners();
      });
    } catch (e) {
      print('❌ Error initializing auth listener: $e');
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 Signing up: $email');
      
      final response = await _supabaseService.signUp(email, password, name);
      
      if (response.user != null) {
        print('✅ User created: ${response.user!.id}');
        
        // Create user profile in database
        try {
          await _supabaseService.createUserProfile(response.user!.id, name, email);
          print('✅ Profile created successfully');
        } catch (profileError) {
          print('⚠️ Warning creating profile: $profileError');
          // Don't fail signup if profile creation fails
        }
        
        _isAuthenticated = true;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Sign up failed. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Sign up error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔑 Signing in: $email');
      
      final response = await _supabaseService.signIn(email, password);
      
      if (response.user != null) {
        print('✅ Logged in successfully: ${response.user!.email}');
        _isAuthenticated = true;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
        print('❌ Login failed: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Sign in error: $e');
      
      // Better error messages
      String friendlyError = e.toString();
      if (friendlyError.contains('Invalid login credentials')) {
        friendlyError = 'Invalid email or password';
      } else if (friendlyError.contains('Failed to fetch') || friendlyError.contains('ClientException')) {
        friendlyError = 'Connection error. Check your internet connection.';
      } else if (friendlyError.contains('CORS')) {
        friendlyError = 'CORS error. Make sure localhost is configured in Supabase.';
      }
      
      _error = friendlyError;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      print('👋 Signing out');
      await _supabaseService.signOut();
      _isAuthenticated = false;
      _user = null;
      _error = null;
      notifyListeners();
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Sign out error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }


  Future<void> checkAuthStatus() async {
    final currentUser = _supabaseService.getCurrentUser();
    _isAuthenticated = currentUser != null;
    notifyListeners();
  }
}
