import 'package:flutter/material.dart';
import '../models/factor_progress.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';
import '../services/prediction_service.dart';
import '../services/service_locator.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/custom_profile_drawer.dart';
import 'package:flutter/services.dart';

class ProgressReportScreen extends StatefulWidget {
  const ProgressReportScreen({super.key});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<FactorProgress> _progressData = [];
  final PredictionService _predictionService = PredictionService();
  final LoggerService _logger = serviceLocator<LoggerService>();
  AuthService _authService = serviceLocator<AuthService>();

  @override
  void initState() {
    super.initState();
    _fetchProgressReportData();
  }

  Future<void> _fetchProgressReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        _logger.w('ProgressReportScreen: User ID is null. Cannot fetch progress report.');
        setState(() {
          _errorMessage = 'Could not identify user. Please log in again.';
          _isLoading = false;
        });
        return;
      }
      _logger.i('ProgressReportScreen: Fetching progress report for user $userId');
      final data = await _predictionService.getProgressReport(userId);
      setState(() {
        _progressData = data;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.e('ProgressReportScreen: Error fetching progress report: $e', e);
      setState(() {
        _errorMessage = 'Failed to load progress report. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Widget _buildProgressContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_progressData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No progress data available for the past week.',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    String formattedProgressText = "We've analyzed your previous data and found several progress in it by comparing them.\n\n" +
        _progressData.map((factor) =>
        '·${factor.factorName}: ${factor.status} ${factor.change}'
        ).join('\n');

    return Text(
      formattedProgressText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontFamily: 'Montaga',
        height: 1.6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9),
      endDrawer: const CustomProfileDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFF2D2041),
              child: const Text(
                'Progress report',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'Montaga',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF4B3869),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: _buildProgressContent(),
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Simple line chart placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.12,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SimpleLineChartPainter(),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.008),
            // Days row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Mon', style: TextStyle(color: Colors.black54, fontFamily: 'Montaga', fontSize: 13)),
                  Text('Tues', style: TextStyle(color: Colors.black54, fontFamily: 'Montaga', fontSize: 13)),
                  Text('Wed', style: TextStyle(color: Colors.black54, fontFamily: 'Montaga', fontSize: 13)),
                  Text('Thurs', style: TextStyle(color: Colors.black54, fontFamily: 'Montaga', fontSize: 13)),
                  Text('Fri', style: TextStyle(color: Colors.black54, fontFamily: 'Montaga', fontSize: 13)),
                  Text('Sat', style: TextStyle(color: Colors.black54, fontFamily: 'Montaga', fontSize: 13)),
                  Text('Sun', style: TextStyle(color: Colors.black54, fontFamily: 'Montaga', fontSize: 13)),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 2,
        screenColor: Colors.white,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
    );
  }
}

class _SimpleLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB6A1D6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.16, size.height * 0.6),
      Offset(size.width * 0.32, size.height * 0.5),
      Offset(size.width * 0.48, size.height * 0.3),
      Offset(size.width * 0.64, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.4),
      Offset(size.width, size.height * 0.3),
    ];

    // Draw line
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw highlight circle on Friday
    final highlightPaint = Paint()
      ..color = const Color(0xFFF7F7C6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(points[4], 8, highlightPaint);
    final borderPaint = Paint()
      ..color = const Color(0xFF2D2041)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(points[4], 8, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 