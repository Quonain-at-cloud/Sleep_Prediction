import 'package:flutter/material.dart';

class AppConstants {
  // App theme colors
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color accentColor = Color(0xFF7D5260);
  static const Color backgroundColor = Color(0xFFF8F8FA);
  static const Color errorColor = Color(0xFFB3261E);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6750A4), Color(0xFF9780D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );
  
  // Padding and spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Border radius
  static const double defaultBorderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 25.0;
  
  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // App-specific constants
  static const int minSleepHours = 6;
  static const int maxSleepHours = 10;
  static const int predictionGenerationTimeSeconds = 5;
  
  // Routes
  static const String splashRoute = '/splash';
  static const String splashScreen1Route = '/splash_screen1';
  static const String welcomeRoute = '/welcome';
  static const String loginRoute = '/login';
  static const String forgotPasswordRoute = '/forgot_password_screen';
  static const String registerRoute = '/register';
  static const String onboardingRoute = '/onboarding';
  static const String registerSuccessRoute = '/register-success';
  static const String sleepQualityRoute = '/sleep-quality';
  static const String sleepDurationRoute = '/sleep-duration';
  static const String sleepGoalsRoute = '/sleep-goals';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String sleepDataRoute = '/sleep-data';
  static const String addSleepDataRoute = '/add-sleep-data';
  static const String predictionRoute = '/prediction';
  static const String predictionGraphRoute = '/prediction-graph';
  static const String recommendationRoute = '/recommendation';
  static const String sleepQualityFeedbackRoute = '/sleep-quality-feedback';
  static const String settingsRoute = '/settings';
  static const String editProfileRoute = '/edit-profile';
  static const String changePasswordRoute = '/change-password';
  static const String notificationPreferencesRoute = '/notification-preferences';
  static const String exportDataRoute = '/export-data';
  static const String privacySettingsRoute = '/privacy-settings';
  static const String dietaryHabitsRoute = '/dietary-habits';
  static const String environmentalFactorsRoute = '/environmental-factors';
  static const String sleepPatternsRoute = '/sleep-patterns';
  static const String scheduleRoute = '/schedule';
  
  // Shared preferences keys
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String userProfileCompleteKey = 'user_profile_complete';
  static const String darkModeKey = 'dark_mode';
  
  // Error messages
  static const String genericErrorMessage = 'Something went wrong. Please try again later.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String authErrorMessage = 'Authentication failed. Please check your credentials.';
} 