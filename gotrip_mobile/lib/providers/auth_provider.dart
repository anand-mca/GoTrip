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
    _supabaseService.authStateChanges().listen((authState) {
      _isAuthenticated = authState.session != null;
      notifyListeners();
    });
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signUp(email, password, name);
      
      if (response.user != null) {
        // Create user profile in database
        await _supabaseService.createUserProfile(response.user!.id, name, email);
        
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
      final response = await _supabaseService.signIn(email, password);
      
      if (response.user != null) {
        _isAuthenticated = true;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
      _isAuthenticated = false;
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
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
