import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import '../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late StreamSubscription<UserModel?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    final authService = serviceLocator<AuthService>();
    
    // Use a short delay to allow the splash screen to be visible
    // and to ensure that the auth stream has had a chance to emit its initial value.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      _authSubscription = authService.authStateChanges.listen((user) {
        _navigate(user);
      });

      // Handle the case where the stream has already emitted a value
      // but the listener was attached late.
      if (authService.currentUser != null) {
         _navigate(authService.currentUser);
      } else if (!authService.isLoggedIn) {
         _navigate(null);
      }
    });
  }

  void _navigate(UserModel? user) {
    if (!mounted) return;

    // To prevent multiple navigations, cancel the subscription.
    _authSubscription.cancel();

    if (user != null) {
      final isGenderMissing = user.gender.isEmpty;
      // Check for a realistic default date or null.
      final isDobMissing = user.dateOfBirth == null || user.dateOfBirth.year < 1920; 

      if (isGenderMissing || isDobMissing) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.onboardingRoute,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.sleepPatternsRoute,
          (route) => false,
        );
      }
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppConstants.splashScreen1Route,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2438),
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/icon_large.png',
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}
