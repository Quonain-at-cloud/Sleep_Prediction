import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/custom_profile_drawer.dart';
import 'package:flutter/services.dart';
import '../services/prediction_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';
import '../models/user_model.dart';
import '../services/service_locator.dart';
import '../services/logger_service.dart';

class RecommendationScreen extends StatefulWidget {
  final List<String>? recommendations;
  final UserModel? userProfile;
  
  const RecommendationScreen({super.key, this.recommendations, this.userProfile});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final PredictionService _predictionService = serviceLocator<PredictionService>();
  final AuthService _authService = serviceLocator<AuthService>();
  final LoggerService _logger = serviceLocator<LoggerService>();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _recommendations = [];
  String _userName = 'User'; // Fallback if userProfile is not provided or name is null
  UserModel? _userProfile; // Will be set from widget.userProfile or fetched
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    _logger.i('RecommendationScreen: _loadData called.');
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Use passed userProfile if available, otherwise fetch
      if (widget.userProfile != null) {
        _logger.i('Using passed userProfile: ${widget.userProfile!.id}');
        if (mounted) {
          setState(() {
            _userProfile = widget.userProfile;
            _userName = widget.userProfile!.name ?? 'User';
          });
        }
      } else {
        _logger.i('widget.userProfile is null, fetching current user model.');
        final fetchedUserProfile = await _authService.getCurrentUserModel();
        if (fetchedUserProfile != null && mounted) {
          setState(() {
            _userProfile = fetchedUserProfile;
            _userName = fetchedUserProfile.name ?? 'User';
          });
        }
      }
      
      // Use passed recommendations if available, otherwise fetch
      if (widget.recommendations != null && widget.recommendations!.isNotEmpty) {
        _logger.i('Using passed recommendations. Count: ${widget.recommendations!.length}');
        if (mounted) {
          setState(() {
            _recommendations = widget.recommendations!;
            _isLoading = false;
          });
        }
      } else {
        _logger.i('widget.recommendations is null or empty, fetching from service.');
        // Fallback: load recommendations from the API if not passed or empty
        final fetchedRecommendations = await _predictionService.getRecommendations(); // This might need context or user ID
        if (mounted) {
          setState(() {
            _recommendations = fetchedRecommendations;
            _isLoading = false;
          });
        }
      }
      _logger.i('Finished _loadData. isLoading: $_isLoading, recommendations count: ${_recommendations.length}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load recommendations: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column( // Main Column for the screen
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2041),
              ),
              child: const Text(
                'Recommendation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montaga',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!, // Not const
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center, 
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hi!,',
                                        style: TextStyle(
                                          fontFamily: 'Montaga',
                                          fontSize: 36,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2D2041),
                                        ),
                                      ),
                                      Text( 
                                        _userName,
                                        style: const TextStyle(
                                          fontFamily: 'Montaga',
                                          fontSize: 36,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2D2041),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEFEFEF),
                                    ),
                                    child: _userProfile?.profileImageUrl != null && _userProfile!.profileImageUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              _userProfile!.profileImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(
                                                Icons.person,
                                                color: Color(0xFF2D2041),
                                                size: 45,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Color(0xFF2D2041),
                                            size: 45,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 380.0),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 30),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2041),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 400.0),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 6),
                                            if (_recommendations.isEmpty) 
                                              _buildBulletPoint('No specific recommendations available yet. Ensure data is submitted and processed.')
                                            else
                                              ..._recommendations.map((recommendation) => _buildBulletPoint(recommendation)).toList(),
                                            
                                            const SizedBox(height: 16),
                                           
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 30, top: 20),
                              child: Center(
                                child: SizedBox(
                                  width: 250,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, AppConstants.sleepQualityFeedbackRoute);
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
                                      'Feedback',
                                      style: TextStyle(
                                        fontFamily: 'Montaga',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ), // Closes Padding
            ), // Closes Expanded
          ], // Closes SafeArea's Column children
        ),
      ), // Closes SafeArea
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 1,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
      endDrawer: const CustomProfileDrawer(),
    ); // Closes Scaffold
  } // Closes build method

Widget _buildBulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '  ',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
  }
}