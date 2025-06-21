import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  UserModel? _userModel;
  bool _isLoading = false;
  String _errorMessage = '';

  AuthProvider() {
    _init();
  }

  void _init() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _authService.getToken();
      _isAuthenticated = token != null;
      if (_isAuthenticated) {
        await _loadUserModel();
      } else {
        _userModel = null;
      }
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _userModel = null;
      notifyListeners();
    }
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> _loadUserModel() async {
    if (!_isAuthenticated) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      _userModel = await _authService.getCurrentUserModel();
      
    } catch (e) {
      _errorMessage = 'Failed to load user profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _authService.login(email: email, password: password);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  // Register with email and password
  // Register with only required fields (email, password, name)
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
      );
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.logout();
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      await _authService.forgotPassword(email);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateProfile({
    DateTime? dateOfBirth,
    String? gender,
    double? weight,
    double? height,
    Map<String, dynamic>? data,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      if (data != null) {
        await _authService.updateUserProfile(data);
      } else {
        await _authService.updateUserProfile({
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
          if (gender != null) 'gender': gender,
          if (weight != null) 'weight': weight,
          if (height != null) 'height': height,
        });
      }
      
      await _loadUserModel(); // Reload user data after update
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 