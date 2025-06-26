import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'logger_service.dart';
import 'service_locator.dart';
import '../providers/notification_provider.dart';

class AuthService {
  final ApiService _apiService;
  final LoggerService _logger = LoggerService();
  final _authStateController = StreamController<UserModel?>.broadcast();
  Timer? _tokenRefreshTimer;
  UserModel? _currentUser;
  String? _localToken; // Added local token storage

  // Get the current logged-in user
  UserModel? get currentUser => _currentUser;

  // Get the current auth token
  String? get token => _localToken;

  // Auth state changes stream
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  // Getter for login status
  bool get isLoggedIn {
    if (_localToken == null) return false;
    try {
      // Ensure token is not empty before decoding
      if (_localToken!.isEmpty) return false;
      return !JwtDecoder.isExpired(_localToken!);
    } catch (e) {
      _logger.w('Error decoding local token during isLoggedIn check. Token: $_localToken. Error: $e. Stack: ${StackTrace.current}');
      return false; // Treat as not logged in if token is malformed or empty
    }
  }

  AuthService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService() {
    // Initialization will be called explicitly via init() from service_locator
  }

  void dispose() {
    _authStateController.close();
    _tokenRefreshTimer?.cancel();
  }

  Future<String?> getToken() async {
    return await _apiService.getToken();
  }

  Future<void> init() async { // Renamed from _checkAuthState
    _localToken = await _apiService.getToken(); // Get token from ApiService (which gets from SharedPreferences)
    _logger.i('AuthService init: Token from ApiService: ${_localToken == null ? "null" : (_localToken!.isEmpty ? "empty" : "present")}');

    if (_localToken != null && _localToken!.isNotEmpty) {
      try {
        if (JwtDecoder.isExpired(_localToken!)) {
          _logger.i('AuthService init: Token expired, attempting refresh.');
          await _refreshToken(); // This will update _localToken, _currentUser, and ApiService token if successful, or sign out.
        } else {
          // Token is valid, fetch user model
          _logger.i('AuthService init: Token valid, fetching user model.');
          final user = await getCurrentUserModel(); // This uses ApiService, which should have its headers set by ApiService.init()
          _currentUser = user;
          _authStateController.add(user);
          // Re-check _localToken as _refreshToken (if called due to error in getCurrentUserModel or other path) might nullify it on failure
          if (_localToken != null && _localToken!.isNotEmpty) { 
             _setupTokenRefresh(_localToken!); // Setup timer with the current valid token
          } else {
            _logger.w('AuthService init: Token became null/empty after user fetch or during other operations. Not setting up refresh timer.');
            // Ensure consistent state if token disappeared
            if (_currentUser != null) _currentUser = null; // If user was fetched but token gone, invalidate user
            if (_authStateController.hasListener) _authStateController.add(null);
          }
        }
      } catch (e) {
        _logger.e('AuthService init: Error during auth initialization: $e. Stack: ${StackTrace.current}', e);
        await logout(); // Clears local token, api token, user state
      }
    } else {
      // No token found or token is empty
      _logger.i('AuthService init: No token found or token is empty.');
      if (_currentUser != null) _currentUser = null;
      if (_authStateController.hasListener) _authStateController.add(null);
      if (_localToken != null) _localToken = null; // Explicitly ensure local token is null if it was e.g. empty string
    }
  }

  // Send forgot password OTP
  Future<void> forgotPassword(String email) async {
    try {
      _logger.i('Sending forgot password request for email: $email');
      
      // Basic email validation
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Please enter a valid email address');
      }
      
      final response = await _apiService.post(
        ApiConfig.endpoints.auth.forgotPassword,
        {'email': email},
        handleErrors: false, // We'll handle errors manually
      );

      _logger.i('Forgot password response: $response');

      if (response == null) {
        throw Exception('Server error: No response received');
      }

      // Handle different response statuses
      if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
          _logger.i('OTP sent successfully to $email');
          return;
        } else if (response['message'] != null) {
          throw Exception(response['message']);
        }
      }
      
      // If we get here, the response format is unexpected
      throw Exception('Unexpected response from server');
      
    } on DioError catch (e) {
      _logger.e('Dio error in forgotPassword', e);
      
      if (e.response?.statusCode == 404) {
        throw Exception('No account found with this email address.');
      } else if (e.type == DioErrorType.connectionTimeout ||
                 e.type == DioErrorType.receiveTimeout) {
        throw Exception('Request timed out. Please check your internet connection.');
      } else if ((e.error?.toString().contains('SocketException') ?? false)) {
        throw Exception('No internet connection. Please check your network settings.');
      } else if (e.response?.data != null && e.response?.data is Map) {
        // Handle server error messages
        final errorData = e.response!.data as Map<String, dynamic>;
        throw Exception(errorData['error']?.toString() ?? 'An error occurred');
      } else {
        throw Exception('Failed to process request. Please try again later.');
      }
    } catch (e) {
      _logger.e('Unexpected error in forgotPassword', e);
      rethrow;
    }
  }
  
  // Reset password with new password and reset token
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String resetToken,
  }) async {
    try {
      await _apiService.post(
        ApiConfig.endpoints.auth.resetPassword,
        {
          'email': email,
          'newPassword': newPassword,
          'resetToken': resetToken,
        },
      );
    } catch (e) {
      _logger.e('Error resetting password', e);
      rethrow;
    }
  }

  // Verify OTP for password reset
  Future<String> verifyOTP(String email, String otp) async {
    try {
      final response = await _apiService.post(
        ApiConfig.endpoints.auth.verifyOTP,
        {
          'email': email,
          'otp': otp,
        },
      );
      
      if (response == null) {
        throw Exception('Server error: No response received');
      }

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Invalid or expired OTP');
      }
      
      if (response['resetToken'] == null) {
        throw Exception('Server error: Reset token not received');
      }
      
      return response['resetToken'] as String;
    } catch (e) {
      _logger.e('Error verifying OTP', e);
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please check your internet connection and try again.');
      }
      throw Exception('Failed to verify OTP. Please try again.');
    }
  }

  // Get the current user model from the API
  // getCurrentUserModel is already defined below with better error handling
  
  void _setupTokenRefresh(String token) {
    _tokenRefreshTimer?.cancel();
    
    final decodedToken = JwtDecoder.decode(token);
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
    final timeToExpiry = expiryDate.difference(DateTime.now());
    
    // Refresh token 5 minutes before expiry
    final refreshTime = timeToExpiry - const Duration(minutes: 5);
    if (refreshTime.isNegative) {
      _refreshToken();
    } else {
      _tokenRefreshTimer = Timer(refreshTime, _refreshToken);
    }
  }
  
  Future<void> _refreshToken() async {
    try {
      final currentToken = await getToken();
      if (currentToken != null) {
        final newToken = await refreshToken(currentToken);
        _setupTokenRefresh(newToken);
      } else {
        await signOut();
      }
    } catch (e) {
      _logger.e('Error refreshing token in _refreshToken. Stack: ${StackTrace.current}', e);
      await logout();
    }
  }
  
  Future<String> refreshToken(String currentToken) async {
    try {
      final response = await _apiService.post(ApiConfig.endpoints.auth.refreshToken, {});
      if (response == null || !response.containsKey('token')) {
        throw Exception('Invalid response from refresh token endpoint');
      }
      
      final String newToken = response['token'];
      await _apiService.setToken(newToken);
      
      // Update the current user in the auth state
      if (response.containsKey('user')) {
        final user = UserModel.fromJson(response['user']);
        _authStateController.add(user);
      }
      
      return newToken;
    } catch (e) {
      _logger.e('Error refreshing token in refreshToken(String currentToken). Stack: ${StackTrace.current}', e);
      // If token refresh fails, sign out the user
      await logout();
      throw Exception('Failed to refresh token: ${e.toString()}');
    }
  }
  
  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = await getCurrentUserModel();
      return user?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Sign in with email and password
  Future<String> login({required String email, required String password}) async {
    try {
      final response = await _apiService.post(ApiConfig.endpoints.auth.login, {
        'email': email,
        'password': password,
      });

      final String token = response['token'];
      await _apiService.setToken(token);
      await Future.delayed(const Duration(milliseconds: 250)); // Diagnostic delay
      _localToken = token; // Store token locally
      
      // Fetch and set the current user data
      final user = await getCurrentUserModel();
      _currentUser = user; // Set the current user
      _authStateController.add(user);
      _setupTokenRefresh(token);
      
      // Initialize notification provider for the new user
      try {
        final notificationProvider = serviceLocator<NotificationProvider>();
        await notificationProvider.initialize();
      } catch (e) {
        _logger.w('Failed to initialize notification provider on login: $e');
      }
      
      return token;
    } catch (e) {
      _currentUser = null; // Ensure current user is null on error
      rethrow;
    }
  }
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> registrationData,
  }) async {
    _logger.i('Attempting registration for email: $email');
    try {
      // Construct the payload, ensuring email and password are at the root
      final Map<String, dynamic> payload = {
        'email': email,
        'password': password,
        ...registrationData, // Spread the rest of the registration data
      };
      // Remove id if present, backend should assign it
      payload.remove('id'); 
      payload.removeWhere((key, value) => value == null); // Remove null values

      _logger.i('Registration payload: $payload');

      final response = await _apiService.post(
        ApiConfig.endpoints.auth.register,
        payload,
        timeout: const Duration(seconds: 30),
      );

      if (response == null) {
        _logger.e('Registration failed: No response from server');
        throw Exception('Registration failed: No response from server');
      }

      final String? token = response['token'];
      final Map<String, dynamic>? userData = response['user'];

      if (token == null || token.isEmpty) {
        _logger.e('Registration failed: Token not received. Response: $response');
        throw Exception(response['error'] ?? 'Registration failed: Token not received');
      }

      if (userData == null) {
        _logger.e('Registration failed: User data not received. Response: $response');
        throw Exception(response['error'] ?? 'Registration failed: User data not received');
      }

      await _apiService.setToken(token);
      await Future.delayed(const Duration(milliseconds: 250)); // Diagnostic delay
      _localToken = token;
      
      final newUser = UserModel.fromJson(userData);
      _currentUser = newUser;
      if (_authStateController.hasListener && !_authStateController.isClosed) {
        _authStateController.add(newUser);
      }
      _setupTokenRefresh(token);
      _logger.i('User registered successfully: ${newUser.email}');
      return newUser;
    } catch (e, s) {
      _logger.e('Registration error for $email: $e. Stack: $s', e);
      _currentUser = null;
      _localToken = null;
      if (_authStateController.hasListener && !_authStateController.isClosed) {
        _authStateController.add(null);
      }
      await _apiService.clearToken();
      if (e is DioError && e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? gender,
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    List<String>? healthConditions,
  }) async {
    final Map<String, dynamic> registrationData = {
      'name': name,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (healthConditions != null) 'healthConditions': healthConditions,
    };

    return await registerWithEmailAndPassword(
      email: email,
      password: password,
      registrationData: registrationData,
    );
  }
  
  // Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    try {
      final response = await _apiService.get(ApiConfig.endpoints.users.profile);
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      _logger.e('Error getting current user model. Stack: ${StackTrace.current}', e);
      // If the error is due to authentication, sign out the user
      if (e is DioError && e.response?.statusCode == 401) {
        _logger.w('Auth error (401) getting user model, signing out.');
        await logout();
      }
      return null;
    }
  }
  
  Future<String?> getCurrentUserId() async {
    try {
      final user = await getCurrentUserModel();
      return user?.id;
    } catch (e) {
      _logger.e('Error getting current user ID', e);
      return null;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      _logger.i('Updating user profile with data: $userData');
      
      // Convert date if present
      final dataToSend = Map<String, dynamic>.from(userData);
      
      // Handle date conversion if present
      if (dataToSend.containsKey('dateOfBirth') && dataToSend['dateOfBirth'] is String) {
        final date = DateTime.tryParse(dataToSend['dateOfBirth']);
        if (date != null) {
          dataToSend['dateOfBirth'] = date.toIso8601String();
        }
      }
      
      final response = await _apiService.patch(
        ApiConfig.endpoints.users.updateProfile, 
        dataToSend,
      );
      
      if (response == null) {
        _logger.e('Update profile response is null');
        throw Exception('Failed to update profile: No response from server');
      }
      
      if (response['error'] != null) {
        _logger.e('Update profile error: ${response['error']}');
        throw Exception(response['error']);
      }
      
      // Update current user data
      final updatedUser = UserModel.fromJson(response);
      _currentUser = updatedUser;
      _authStateController.add(updatedUser);
      
      _logger.i('User profile updated successfully');
      _logger.i('Profile updated successfully: ${updatedUser.toJson()}');
      
      // Emit the updated user data
      _authStateController.add(updatedUser);
    } catch (e) {
      _logger.e('Error updating user profile:', e);
      rethrow;
    }
  }
  
  // Reset password flow methods are already defined above with better parameter handling
  
  // Get user sleep statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _apiService.get(ApiConfig.endpoints.users.stats);
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await _apiService.get(ApiConfig.endpoints.users.byId(userId));
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      return await getCurrentUserModel();
    } catch (e) {
      _logger.e('Error getting current user', e);
      return null;
    }
  }

  // Sign out method
  Future<void> logout() async {
    try {
      // Clear notifications for the current user
      try {
        final notificationProvider = serviceLocator<NotificationProvider>();
        await notificationProvider.clearNotifications();
      } catch (e) {
        _logger.w('Failed to clear notifications on logout: $e');
      }
      
      // Clear local data
      await _apiService.clearToken();
      _localToken = null;
      _currentUser = null;
      _authStateController.add(null);
      
      // Clear any stored user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error during logout', e);
      rethrow;
    }
  }

  // Alias for logout if needed, or can be removed if direct calls to logout() are preferred.
  Future<void> signOut() async {
    await logout();
  }
}