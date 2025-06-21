import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'password_changed_success_screen.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const CreateNewPasswordScreen({
    Key? key,
    required this.email,
    required this.resetToken,
  }) : super(key: key);

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // Validate both fields manually
    _validatePassword(_passwordController.text);
    _validateConfirmPassword(_confirmPasswordController.text);
    
    // Check if there are any errors
    if (_passwordError != null || _confirmPasswordError != null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.resetPassword(
        email: widget.email,
        newPassword: _passwordController.text,
        resetToken: widget.resetToken,
      );

      if (!mounted) return;

      // Navigate to password changed success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PasswordChangedSuccessScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Password validation errors
  String? _passwordError;
  String? _confirmPasswordError;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      _passwordError = 'Please enter a password';
    } else if (value.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
    } else if (!value.contains(RegExp(r'[A-Z]'))) {
      _passwordError = 'Password must contain at least one uppercase letter';
    } else if (!value.contains(RegExp(r'[a-z]'))) {
      _passwordError = 'Password must contain at least one lowercase letter';
    } else if (!value.contains(RegExp(r'[0-9]'))) {
      _passwordError = 'Password must contain at least one number';
    } else {
      _passwordError = null;
    }
    setState(() {});
    return null; // Always return null so error isn't shown in the TextFormField
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
    } else if (value != _passwordController.text) {
      _confirmPasswordError = 'Passwords do not match';
    } else {
      _confirmPasswordError = null;
    }
    setState(() {});
    return null; // Always return null so error isn't shown in the TextFormField
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () => Navigator.pop(context),
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
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          'Create new\npassword',
                          style: AppTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          'Your new password must be unique from those\npreviously used',
                          style: AppTheme.modifyStyle(
                            AppTheme.bodyMedium,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // New Password TextField
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    style: AppTheme.bodyLarge,
                                    onChanged: _validatePassword,
                                    decoration: InputDecoration(
                                      hintText: 'New Password',
                                      hintStyle: AppTheme.modifyStyle(
                                        AppTheme.bodyLarge,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(25),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_passwordError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                                    child: Text(
                                      _passwordError!,
                                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                                    ),
                                  ),
                              ]),
                              const SizedBox(height: 16),
                              
                              // Confirm Password TextField
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: TextField(
                                    controller: _confirmPasswordController,
                                    obscureText: !_isConfirmPasswordVisible,
                                    style: AppTheme.bodyLarge,
                                    onChanged: _validateConfirmPassword,
                                    decoration: InputDecoration(
                                      hintText: 'Confirm Password',
                                      hintStyle: AppTheme.modifyStyle(
                                        AppTheme.bodyLarge,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(25),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                          });
                                        },
                                        icon: Icon(
                                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_confirmPasswordError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                                    child: Text(
                                      _confirmPasswordError!,
                                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                                    ),
                                  ),
                              ]),
                              const SizedBox(height: 60),
                              
                              // Error message if any
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 32),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              
                              // Reset Password Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _resetPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A2438)),
                                          ),
                                        )
                                      : Text(
                                          'Reset Password',
                                          style: AppTheme.modifyStyle(
                                            AppTheme.buttonLarge,
                                            color: const Color(0xFF2A2438),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 