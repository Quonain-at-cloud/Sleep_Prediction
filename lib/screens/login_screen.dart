import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'onboarding_screen.dart';
import 'sleep_patterns_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is AuthAuthenticated && state.user != null) {
          final user = state.user!;
          final isGenderMissing = user['gender'] == null || user['gender'].toString().isEmpty;
          final isDobMissing = user['dateOfBirth'] == null || user['dateOfBirth'].toString().isEmpty;
          if (isGenderMissing || isDobMissing) {
            Navigator.of(context).pushReplacementNamed(AppConstants.onboardingRoute);
          } else {
            Navigator.of(context).pushReplacementNamed(AppConstants.sleepPatternsRoute);
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final bool isLoading = state is AuthLoading;

          return Scaffold(
            body: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2438), // Dark purple background
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, AppConstants.welcomeRoute);
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            SizedBox(height: MediaQuery.of(context).size.height * 0.037),
                            Center(
                              child: Image.asset(
                                'assets/icons/icon_large.png',
                                width: 60,
                                height: 60,
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.037),
                            // Welcome Text
                            Text(
                              'Welcome back! Glad\nto see you, Again!',
                              style: AppTheme.titleLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                            // Email TextField
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextField(
                                controller: _emailController,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: Colors.white,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Enter your email',
                                  hintStyle: AppTheme.bodyLarge.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                            // Password TextField
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: Colors.white,
                                ),
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: AppTheme.bodyLarge.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppConstants.forgotPasswordRoute);
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                            // Login Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              margin: const EdgeInsets.symmetric(horizontal: 0),
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        final email = _emailController.text.trim();
                                        final password = _passwordController.text.trim();

                                        if (email.isEmpty || password.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please enter both email and password'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please enter a valid email address'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        context.read<AuthBloc>().add(
                                              AuthLoginRequested(
                                                email: email,
                                                password: password,
                                              ),
                                            );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                  disabledBackgroundColor: Colors.white.withOpacity(0.7),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF2A2438),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Login',
                                        style: AppTheme.buttonLarge.copyWith(
                                          color: const Color(0xFF2A2438),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.16),
                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Don\'t have an account? ',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(1),
                                    fontWeight: FontWeight.w900,  
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushNamed(AppConstants.registerRoute);
                                  },
                                  child: Text(
                                    'Register Now',
                                    style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gold,
                                ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}