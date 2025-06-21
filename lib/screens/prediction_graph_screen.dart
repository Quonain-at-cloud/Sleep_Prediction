import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/sleep_factors_pie_chart.dart';
import '../widgets/custom_profile_drawer.dart';
import 'package:flutter/services.dart';
import '../services/prediction_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';
import '../services/service_locator.dart';
import '../services/logger_service.dart';

class PredictionGraphScreen extends StatefulWidget {
  final Map<String, double>? contributingFactors;

  const PredictionGraphScreen({super.key, this.contributingFactors});

  @override
  State<PredictionGraphScreen> createState() => _PredictionGraphScreenState();
}

class _PredictionGraphScreenState extends State<PredictionGraphScreen> {
  final PredictionService _predictionService = serviceLocator<PredictionService>();
  final AuthService _authService = serviceLocator<AuthService>();
  final LoggerService _logger = serviceLocator<LoggerService>();
  
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, double> _contributingFactors = {};
  
  @override
  void initState() {
    super.initState();
    _logger.i('PredictionGraphScreen: initState called.');
    _loadLatestContributingFactors();
  }

  @override
  void didUpdateWidget(covariant PredictionGraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.i('PredictionGraphScreen: didUpdateWidget called.');
    _applyIncomingFactors(widget.contributingFactors);
  }

  void _applyIncomingFactors(Map<String, double>? factors) {
    if (factors != null && factors.isNotEmpty) {
      _logger.i('Applying contributingFactors. Count: ${factors.length}');
      setState(() {
        _contributingFactors = factors.map(
          (key, value) => MapEntry(key, (value is num ? value.toDouble() : 0.0)),
        );
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      _logger.w('Incoming contributingFactors is null or empty.');
      setState(() {
        _errorMessage = 'No contributing factors data available to display.';
        _isLoading = false;
        _contributingFactors = {};
      });
    }
  }
  
  Future<void> _loadLatestContributingFactors() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final String? userId = await _authService.getCurrentUserId();
      if (userId == null) {
        _logger.w('User ID not available for fetching latest prediction.');
        _applyIncomingFactors(widget.contributingFactors);
        return;
      }

      final Map<String, dynamic> result =
          await _predictionService.fetchLatestPredictionWithRecommendations(userId);

      Map<String, dynamic>? rawFactors;
      if (result['contributingFactors'] is Map) {
        rawFactors = Map<String, dynamic>.from(result['contributingFactors']);
      } else if (result['prediction'] is Map &&
          (result['prediction'] as Map).containsKey('contributingFactors')) {
        rawFactors = Map<String, dynamic>.from(
            (result['prediction'] as Map)['contributingFactors']);
      }

      if (rawFactors != null && rawFactors.isNotEmpty) {
        final mapped = rawFactors.map((key, value) {
          if (value is num) {
            return MapEntry(key, value.toDouble());
          }
          final parsed = double.tryParse(value.toString());
          return MapEntry(key, parsed ?? 0.0);
        });

        if (mounted) {
          setState(() {
            _contributingFactors = mapped;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        _logger.w('No contributing factors returned from API.');
        _applyIncomingFactors(widget.contributingFactors);
      }
    } catch (e, s) {
      _logger.e('Error loading latest contributing factors: $e', e);
      _applyIncomingFactors(widget.contributingFactors);
    }
  }

  // _fetchPredictionData is no longer needed as data is passed via constructor
  /*
  Future<void> _fetchPredictionData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // This service call might need adjustment if it's still used as a fallback
      // final predictionData = await _predictionService.getLatestPrediction(); 
      // Ensure the structure matches: predictionData['contributingFactors']
      // For now, assuming it's not used.
      // setState(() {
      //   _contributingFactors = (predictionData?['contributingFactors'] as Map<String, dynamic>? ?? {}).map(
      //     (key, value) => MapEntry(key, (value is num ? value.toDouble() : 0.0)),
      //   );
      //   _isLoading = false;
      // });
    } catch (e) {
      _logger.e('Failed to load prediction data: $e');
      if(mounted){
        setState(() {
          _errorMessage = 'Failed to load prediction data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  */
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2041),
              ),
              child: const Text(
                'Prediction Graph',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montaga',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // ElevatedButton(
                            //   onPressed: _fetchPredictionData, // _fetchPredictionData removed
                            //   child: const Text('Try Again'),
                            // ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Here's Your prediction\nin graph form!",
                            textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montaga',
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _contributingFactors.isNotEmpty
                    ? Expanded(
                        child: SleepFactorsPieChart(
                          chartTitle: "Factors contributing to sleep loss",
                          contributingFactors: _contributingFactors,
                        ),
                      )
                    : const Center(child: Text('No data available for chart.')),
                    const SizedBox(height: 180),
                    Center(
                      child: SizedBox(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C5470),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 1,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
      endDrawer: const CustomProfileDrawer(),
    );
  }
} 