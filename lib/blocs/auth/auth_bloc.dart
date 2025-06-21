import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../exceptions/api_exceptions.dart';
import '../../services/logger_service.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final LoggerService _logger = LoggerService();

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {

    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthCheckRequested>(_onCheckRequested);
    on<UpdateProfileEvent>(_onUpdateProfileRequested);
  }

  void _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('Starting login process');
    _logger.i('Login attempt for email: ${event.email}');
    
    emit(const AuthLoading());
    try {
      // First try to login and get the token
      _logger.i('Attempting to get token');
      final token = await _authService.login(
        email: event.email,
        password: event.password,
      );
      _logger.i('Login successful, got token');
      
      try {
        // Then try to get user data
        _logger.i('Fetching user data');
        final user = await _authService.getCurrentUserModel();
        _logger.i('User data fetched successfully');
        
        // Emit authenticated state with both token and user data
        emit(AuthAuthenticated(token, user?.toJson()));
      } catch (userError) {
        // If we can't get user data, still authenticate with just the token
        _logger.e('Failed to get user data', userError);
        emit(AuthAuthenticated(token));
      }
    } catch (e) {
      _logger.e('Login failed', e);
      if (e is ApiException) {
        emit(AuthError(e.message));
      } else {
        emit(AuthError('Login failed: ${e.toString()}'));
      }
    }
  }

  void _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('Starting registration process');
    _logger.i('Registration data: name=${event.name}, email=${event.email}');

    emit(const AuthLoading());
    try {
      // Validate input data
      if (event.name.isEmpty || event.email.isEmpty || event.password.isEmpty) {
        throw ValidationException('All fields are required');
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(event.email)) {
        throw ValidationException('Please enter a valid email address');
      }

      if (event.password.length < 6) {
        throw ValidationException('Password must be at least 6 characters long');
      }

      _logger.i('Calling authService.register');
      // The register method now returns a UserModel object.
      final UserModel registeredUser = await _authService.register(
        email: event.email,
        password: event.password,
        name: event.name,
        // Pass other fields if your UI collects them, e.g., gender, dateOfBirth
        // gender: event.gender, 
        // dateOfBirth: event.dateOfBirth,
      );

      // After successful registration, the AuthService should have the token stored.
      final String? actualToken = _authService.token;

      if (actualToken == null || actualToken.isEmpty) {
        _logger.e('Registration successful but token is missing.');
        emit(const AuthError('Registration successful but failed to retrieve session token.'));
        return;
      }
      
      // The registeredUser object is the source of truth for user data immediately after registration.
      _logger.i('Registration successful for user: ${registeredUser.email}');
      emit(AuthAuthenticated(actualToken, registeredUser.toJson()));
    } catch (e) {
      _logger.e('Registration failed', e);
      String errorMessage;
      
      if (e is ValidationException) {
        errorMessage = e.message;
      } else if (e.toString().contains('Email already registered')) {
        errorMessage = 'This email is already registered';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Registration timed out. Please check your internet connection and try again.';
      } else {
        errorMessage = 'Registration failed: ${e.toString().replaceAll('Exception: ', '')}';
      }
      
      emit(AuthError(errorMessage));
    }
  }

  void _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _authService.getToken();
      if (token != null) {
        // Get user data when checking auth state
        final user = await _authService.getCurrentUserModel();
        if (user == null) {
          emit(const AuthError('Failed to get user data'));
          return;
        }
        emit(AuthAuthenticated(token, user.toJson()));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onUpdateProfileRequested(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('Starting profile update');
    
    if (state is! AuthAuthenticated) {
      _logger.e('Cannot update profile: user not authenticated');
      emit(const AuthError('You must be logged in to update your profile'));
      return;
    }

    emit(const AuthLoading());

    try {
      await _authService.updateUserProfile({
        'dateOfBirth': event.dateOfBirth.toIso8601String(),
        'gender': event.gender,
      });

      // Get updated user data
      final user = await _authService.getCurrentUserModel();
      if (user == null) {
        _logger.e('Failed to get updated user data');
        emit(const AuthError('Failed to get updated user data'));
        return;
      }

      _logger.i('Profile updated successfully');
      final token = await _authService.getToken();
      if (token == null) {
        _logger.e('Token not found after profile update');
        emit(const AuthError('Authentication token not found'));
        return;
      }

      emit(AuthAuthenticated(token, user.toJson()));
    } catch (e) {
      _logger.e('Profile update failed', e);
      if (e is ApiException) {
        emit(AuthError(e.message));
      } else {
        emit(AuthError('Failed to update profile: ${e.toString()}'));
      }
    }
  }
}
