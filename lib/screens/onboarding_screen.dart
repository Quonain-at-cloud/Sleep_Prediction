import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/custom_profile_drawer.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && state.user != null) {
            // Close loading indicator
            if (mounted) {
              Navigator.pop(context);
              // Navigate to the data collection flow
              Navigator.pushReplacementNamed(
                context, 
                AppConstants.sleepPatternsRoute,
              );
            }
          } else if (state is AuthError) {
            // Close loading indicator if it's showing
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2A2438), // Dark purple
                Color(0xFF352F44), // Slightly lighter purple
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.09),
                      // Title
                      Text(
                        'Start to improve\nyour sleep\nquality',
                        style: GoogleFonts.montserratAlternates(
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.017),
                      // Subtitle
                      Text(
                        'with our app\'s guidance and support.',
                        style: AppTheme.modifyStyle(
                          AppTheme.bodyLarge,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      // Sleep Icon Pattern (moved here)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Transform.translate(
                            offset: const Offset(140, 0), // Move half the width right
                            child: Image.asset(
                              'assets/icons/icon_large.png',
                              width: 290,
                              height: 290,
                            ),
                          ),
                        ],
                      ),
                      // Age TextField
                      Transform.translate(
                        offset: const Offset(0, -80), // Move up by 20 pixels
                        child: Center(
                          child: Container(
                            height: 55,
                            width: 170,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                              controller: _ageController,
                              style: AppTheme.bodyLarge,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Age',
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
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.017),
                      
                      // Gender Dropdown
                      Transform.translate(
                        offset: const Offset(0, -80), // Move up by 20 pixels
                        child: Center(
                          child: Container(
                            height: 55,
                            width: 170,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF352F44),
                                icon: const SizedBox.shrink(), // Hide the dropdown icon
                                hint: Center(
                                  child: Text(
                                    'Gender',
                                    style: AppTheme.modifyStyle(
                                      AppTheme.bodyLarge,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                items: ['Male', 'Female', 'Other']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Center(
                                      child: Text(
                                        value,
                                        style: AppTheme.modifyStyle(
                                          AppTheme.bodyLarge,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedGender = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                                          
                      // Next Button
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: MediaQuery.of(context).size.height * 0.06,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_ageController.text.isEmpty || _selectedGender == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter your age and select your gender'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  final age = int.tryParse(_ageController.text);
                                  if (age == null || age < 1 || age > 120) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a valid age between 1 and 120'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  final authBloc = BlocProvider.of<AuthBloc>(context);
                                  final currentState = authBloc.state;
                                  
                                  if (currentState is! AuthAuthenticated) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('User not found. Please try logging in again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  final user = currentState.user;
                                  
                                  try {
                                    // Show loading indicator
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        );
                                      },
                                    );
                                    
                                    // Calculate accurate date of birth without losing a year.
                                    final now = DateTime.now();
                                    final dateOfBirth = DateTime(now.year - age, now.month, now.day);
                                    
                                    // Update user profile
                                    authBloc.add(UpdateProfileEvent(
                                      dateOfBirth: dateOfBirth,
                                      gender: _selectedGender!.toLowerCase(),
                                    ));
                                  } catch (e) {
                                    if (mounted) {
                                      // Close loading indicator
                                      Navigator.pop(context);
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to update profile: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E1B2C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Next',
                                  style: GoogleFonts.montaga(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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
      bottomNavigationBar: CustomBottomNavigation(
        screenColor: Colors.purple,
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
        },
      ),
      endDrawer: const CustomProfileDrawer(),
    );
  }
}