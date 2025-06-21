import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'dart:math';

class SleepQualityScreen extends StatefulWidget {
  const SleepQualityScreen({Key? key}) : super(key: key);

  @override
  State<SleepQualityScreen> createState() => _SleepQualityScreenState();
}

class _SleepQualityScreenState extends State<SleepQualityScreen> {
  double _sliderValue = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A2438),
              Color(0xFF352F44),
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
                    const SizedBox(height: 60),
                    // Question Text
                    Text(
                      'How would you\nrate your sleep\nquality?',
                      style: AppTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rate your sleep quality from 1 to 10',
                      style: AppTheme.modifyStyle(
                        AppTheme.bodyMedium,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Slider Value Display
                    Center(
                      child: Text(
                        _sliderValue.toInt().toString(),
                        style: AppTheme.modifyStyle(
                          AppTheme.displayLarge,
                          fontSize: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Custom Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: Colors.white,
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayColor: Colors.white.withOpacity(0.1),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: _sliderValue,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (value) {
                          setState(() {
                            _sliderValue = value;
                          });
                        },
                      ),
                    ),
                    
                    // Min and Max Labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Poor',
                            style: AppTheme.modifyStyle(
                              AppTheme.bodyMedium,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            'Excellent',
                            style: AppTheme.modifyStyle(
                              AppTheme.bodyMedium,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Next Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppConstants.sleepDurationRoute);
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
                            style: AppTheme.modifyStyle(
                              AppTheme.buttonLarge,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sleep Pattern Icon
              Positioned(
                right: -40,
                bottom: 140,
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: SleepPatternPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SleepPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 3;

    // Draw main circle
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // Draw spikes
    for (int i = 0; i < 12; i++) {
      final double angle = (i * 30) * (3.14159 / 180);
      final double startX = centerX + radius * cos(angle);
      final double startY = centerY + radius * sin(angle);
      final double endX = centerX + (radius * 1.5) * cos(angle);
      final double endY = centerY + (radius * 1.5) * sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );

      // Draw small circles at the end of spikes
      canvas.drawCircle(
        Offset(endX, endY),
        3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 