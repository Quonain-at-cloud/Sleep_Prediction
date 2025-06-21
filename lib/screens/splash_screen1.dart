import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/service_locator.dart';
import '../services/auth_service.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({Key? key}) : super(key: key);

  static const String routeName = '/splash_screen1';

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  Future<void> _navigateToWelcome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    // Check if user is already logged in
    final authService = serviceLocator<AuthService>();
    final token = await authService.getToken();
    
    if (token != null) {
      // User is already logged in, navigate to home/prediction screen
      Navigator.pushReplacementNamed(context, AppConstants.predictionRoute);
    } else {
      // User is not logged in, navigate to welcome screen
      Navigator.pushReplacementNamed(context, AppConstants.welcomeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B314D),
              Color(0xFF2A2438),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 300),
            // Logo
            Padding(
              padding: const EdgeInsets.only(right: 50),
              child: Image.asset(
                'assets/icons/icon_large.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 20),
            // SLEEPMATE
            Center(
              child: Text(
                'SLEEPMATE',
                style: GoogleFonts.aladin(
                  fontSize: 60,
                  color: Colors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  height: 0.8,
                ),
              ),
            ),
            // Subtitle
            Padding(
              padding: const EdgeInsets.only(right: 50, top: 0),
              child: Text(
                'PREDICTIVE MODEL',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            // Tagline
            Padding(
              padding: const EdgeInsets.only(right: 50),
              child: Text(
                'for sleep interruption',
                style: GoogleFonts.pacifico(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
