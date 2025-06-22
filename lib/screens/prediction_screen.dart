import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Added for jsonEncode
import '../utils/app_constants.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/custom_profile_drawer.dart';
import '../services/service_locator.dart';
import '../services/logger_service.dart';
import '../models/prediction_model.dart';
import '../models/user_model.dart';
import '../models/sleep_data_model.dart';
import '../models/environmental_data_model.dart';
import '../models/dietary_data_model.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import '../services/prediction_service.dart';
import '../services/auth_service.dart';
import 'recommendation_screen.dart';
// import 'add_sleep_data_screen.dart'; // Removed missing import
import 'environmental_factors_screen.dart';
import 'dietary_habits_screen.dart';
import 'prediction_graph_screen.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class PredictionScreen extends StatefulWidget {
  final Map<String, dynamic>? sleepData;
  final Map<String, dynamic>? dietaryData;
  final Map<String, dynamic>? environmentalData;
  final Map<String, dynamic>? profileInfo;
  final Map<String, dynamic>? predictionResult;

  const PredictionScreen({
    super.key,
    this.sleepData,
    this.dietaryData,
    this.environmentalData,
    this.profileInfo,
    this.predictionResult,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final PredictionService _predictionService = serviceLocator<PredictionService>();
  final AuthService _authService = serviceLocator<AuthService>();
  final LoggerService _logger = serviceLocator<LoggerService>();
  
  bool _isLoading = true;
  String? _errorMessage;
  String? _predictionText;
  List<String> _recommendations = [];
  String _userName = 'User';
  bool _isGenerating = false;
  String? _generationError;
  UserModel? _userProfile;
  Map<String, dynamic>? _contributingFactors;
  String? _detailedAnalysisText;

  @override
  void initState() {
    super.initState();
    
    if (widget.predictionResult != null) {
      // Log the entire structure of predictionResult for debugging
      _logger.i('PredictionScreen initState: Full widget.predictionResult received: ${jsonEncode(widget.predictionResult)}');
      // If predictionResult is passed, parse it and load profile in parallel.
      // Login status should ideally be checked before even navigating here with results,
      // but for safety, we ensure profile loading respects login state.
      if (!_authService.isLoggedIn) {
        _logger.w('PredictionScreen initState: User not logged in, cannot load profile for widget.predictionResult flow.');
        if (mounted) {
          setState(() {
            _errorMessage = "Please log in to view predictions.";
            _isLoading = false;
          });
        }
        // Potentially parse predictionResult if it doesn't depend on user profile for display
        // For now, we assume profile info might be needed alongside predictionResult.
        _parsePredictionResult(widget.predictionResult!); 
        // _loadUserProfile(); // Do not load profile if not logged in
      } else {
        _parsePredictionResult(widget.predictionResult!);
        _loadUserProfile(); 
      }
    } else {
      _logger.i('PredictionScreen initState: widget.predictionResult is NULL.');
      // If no direct result, set loading, then load profile, then fetch prediction.
      if (!_authService.isLoggedIn) {
        _logger.w('PredictionScreen initState: User not logged in, cannot load profile or fetch prediction.');
        if (mounted) {
          setState(() {
            _errorMessage = "Please log in to view predictions.";
            _isLoading = false;
          });
        }
        return; // Do not proceed if not logged in
      }
      setState(() { 
        _isLoading = true;
        _errorMessage = null;
      });
      _loadUserProfile().then((_) {
        if (!mounted) return;

        if (_userProfile?.id == null) {
          _logger.e("User profile or ID not loaded, cannot fetch prediction.");
          if (mounted) {
            setState(() {
              _errorMessage = "User session error. Please try logging in again.";
              _isLoading = false;
            });
          }
          return;
        }
        _fetchLatestPrediction().then((hasPrediction) {
          if (!hasPrediction && mounted) {
            _startDataCollection();
          }
        });
      }).catchError((error, stackTrace) {
          _logger.e("Error loading user profile: $error", error);
          if (mounted) {
            setState(() {
              _errorMessage = "Failed to load user data. Please try again.";
              _isLoading = false;
            });
          }
      });
    }
  }

  void _parsePredictionResult(Map<String, dynamic> result) {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // ---- Normalize backend response ----
      // The backend may return { prediction: { ... } } OR everything at top-level. Handle both.
      final Map<String, dynamic>? predictionMap =
          result['prediction'] is Map<String, dynamic> ? Map<String, dynamic>.from(result['prediction']) : null;

      // Core fields
      final predictionData = predictionMap?['predictionText'] ?? predictionMap?['prediction'] ?? result['prediction'];
      final detailedAnalysisString = predictionMap?['detailedAnalysis'] ?? result['detailedAnalysis'];
      final recommendationsData = result['recommendations'] ?? predictionMap?['recommendations'];
      final contributingFactorsData = result['contributingFactors'] ?? predictionMap?['contributingFactors'];

      _logger.i('PredictionScreen _parsePredictionResult: Extracted contributingFactorsData: ${jsonEncode(contributingFactorsData)}');
      _logger.i('[DEBUG_PARSE] Raw predictionMap: $predictionMap');
      String? newDetailedAnalysisText;
      if (detailedAnalysisString != null && detailedAnalysisString is String) {
        newDetailedAnalysisText = detailedAnalysisString;
        _logger.i('PredictionScreen _parsePredictionResult: Extracted detailedAnalysis: $newDetailedAnalysisText');
      } else {
        newDetailedAnalysisText = null;
        _logger.w('Detailed analysis in predictionResult is null or not a String. Found: ${detailedAnalysisString?.runtimeType}');
      }

      String? newPredictionText;
      List<String> newRecommendations = [];

      _logger.i('[DEBUG_PARSE] Initial newDetailedAnalysisText: $newDetailedAnalysisText');
      _logger.i('[DEBUG_PARSE] Initial predictionData from result: $predictionData');

      if (predictionData != null && predictionData is String) {
        newPredictionText = predictionData;
        // If detailed analysis also exists, concatenate it here
        if (newDetailedAnalysisText != null && newDetailedAnalysisText.isNotEmpty) {
          _logger.i('[DEBUG_PARSE] Attempting concatenation. Current newPredictionText: "$newPredictionText", newDetailedAnalysisText: "$newDetailedAnalysisText"');
          newPredictionText = '$newPredictionText $newDetailedAnalysisText'; 
          _logger.i('[DEBUG_PARSE] After concatenation newPredictionText: "$newPredictionText"');
        } else {
          _logger.i('[DEBUG_PARSE] Skipping concatenation because newDetailedAnalysisText is null or empty. newDetailedAnalysisText: "$newDetailedAnalysisText"');
        }
      } else {
        // If no main prediction, but detailed analysis exists, maybe show that?
        // For now, if main prediction is null, combined is null or just detailed analysis.
        // If main prediction is null, let's assign detailed analysis to newPredictionText if it exists.
        if (newDetailedAnalysisText != null && newDetailedAnalysisText.isNotEmpty) {
           newPredictionText = newDetailedAnalysisText; // Or some prefix like "Analysis: "
        } else {
          newPredictionText = null; 
        }
        _logger.w('[DEBUG_PARSE] Main prediction data (predictionData) is null or not a String. Found: ${predictionData?.runtimeType}. newDetailedAnalysisText: "$newDetailedAnalysisText"');
      }

      if (recommendationsData != null) {
        if (recommendationsData is List) {
          // Already an array of strings – clean & assign
          newRecommendations = List<String>.from(recommendationsData.map((e) => e.toString().trim()))
              .where((element) => element.isNotEmpty)
              .toList();
        } else if (recommendationsData is String) {
          // Single multiline string – split on new-lines/bullets
          List<String> allLines = recommendationsData
              .split('\n')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
          // Remove any introductory greeting lines
          if (allLines.isNotEmpty &&
              (allLines.first.toLowerCase().contains('dear') || allLines.first.toLowerCase().contains('welcome'))) {
            allLines.removeAt(0);
          }
          newRecommendations = allLines;
        }
      } else {
        newRecommendations = [];
        _logger.w('No recommendations data found in predictionResult.');
      }
      
      if (mounted) {
        setState(() {
          _predictionText = newPredictionText;
          _recommendations = newRecommendations;
          if (contributingFactorsData != null && contributingFactorsData is Map<String, dynamic>) {
            // Convert numeric-string values to double for consistency
            _contributingFactors = contributingFactorsData.map((key, value) {
              if (value is num) {
                return MapEntry(key, value);
              }
              final parsed = double.tryParse(value.toString());
              return MapEntry(key, parsed ?? value);
            });
          } else {
            _contributingFactors = null;
            _logger.w('Contributing factors in predictionResult is null or not a Map. Found: ${contributingFactorsData?.runtimeType}');
          }
          _detailedAnalysisText = newDetailedAnalysisText;
          _isLoading = false;
          _logger.i('[DEBUG_PARSE] Final _predictionText set in setState: "$_predictionText"');
          _logger.i('[DEBUG_PARSE] Final _detailedAnalysisText set in setState: "$_detailedAnalysisText"');
        });
      }
    } catch (e, s) {
      _logger.e('Error parsing predictionResult: $e', e);
      if (mounted) {
        setState(() {
          _predictionText = null;
          _recommendations = [];
          _detailedAnalysisText = null; // Add this line
          _errorMessage = 'Error displaying prediction results.';
          _isLoading = false;
        });
      }
    }
  }
  
  // Make prediction with the collected data
  Future<void> _makePrediction() async {
    if (!_authService.isLoggedIn) {
      _logger.w('_makePrediction: User not logged in. Aborting.');
      if (mounted) {
        setState(() {
          _errorMessage = "Please log in to make predictions.";
          _isLoading = false;
        });
      }
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Combine all the data
      final predictionData = {
        'sleep_data': widget.sleepData,
        'dietary_data': widget.dietaryData,
        'environmental_data': widget.environmentalData,
      };

      // Make the API call with named parameters
      final prediction = await _predictionService.makePrediction(
        sleepData: widget.sleepData!,
        environmentalData: widget.environmentalData!,
        dietaryData: widget.dietaryData!,
      );
      
      if (mounted) {
        setState(() {
          // TODO: Refactor _makePredictionWithUserData. It currently tries to use PredictionModel or similar,
          // which is inconsistent with _predictionText (String?). This method might be deprecated.
          // For now, commenting out assignment to the old _prediction variable.
          // _predictionText = prediction?.toString(); 
          _logger.w('_makePredictionWithUserData attempted to assign to removed _prediction variable.');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate prediction: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _fetchLatestPrediction() async {
    if (!_authService.isLoggedIn) {
      _logger.w('_fetchLatestPrediction: User not logged in. Aborting.');
      if (mounted) {
        setState(() {
          _errorMessage = "Please log in to fetch predictions.";
          _isLoading = false;
        });
      }
      return false;
    }
    if (!mounted) return false;
    
    if (!_isLoading && mounted) { 
        setState(() { _isLoading = true; _errorMessage = null; });
    }

    final String? userId = _userProfile?.id;
    if (userId == null) {
      _logger.w('User ID not available for fetching latest prediction. _userProfile: $_userProfile');
      if (mounted) {
        setState(() {
          _errorMessage = 'User information not available. Please try again.';
          _isLoading = false;
        });
      }
      return false;
    }

    try {
      final Map<String, dynamic> result = await _predictionService.fetchLatestPredictionWithRecommendations(userId);
      
      _parsePredictionResult(result); // Handles all state updates including isLoading

      // Determine if content was successfully parsed and is available to be shown.
      // _parsePredictionResult updates _predictionText (the combined string).
      if (mounted) {
        // If _predictionText (which is prediction + detailedAnalysis) is not null and not empty,
        // it means there's something to display for the main prediction area.
        return _predictionText != null && _predictionText!.isNotEmpty;
      }
      // Should ideally not be reached if mounted check is proper and _parsePredictionResult behaves.
      return false; 
    } catch (e, s) {
      _logger.e('Failed to load latest prediction data: $e', e);
      if (mounted) {
        setState(() {
          _predictionText = null;
          _detailedAnalysisText = null; // Ensure detailed analysis is cleared
          _recommendations = [];
          _contributingFactors = null; // Ensure contributing factors are cleared
          _errorMessage = 'Failed to load prediction data. Please check your connection.';
          _isLoading = false;
        });
      }
      return false;
    }
  }
  
  // Start the data collection flow by sequentially navigating through the three screens
  Future<void> _startDataCollection() async {
    if (!mounted) return;
    
    // Automatically start the prediction with user data flow
    await Future.delayed(Duration(milliseconds: 300)); // Short delay to ensure UI is stable
    _makePredictionWithUserData();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await _authService.getCurrentUserModel();
      if (userProfile != null && mounted) {
        setState(() {
          _userName = userProfile.name ?? 'User';
          _userProfile = userProfile;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }
  
  // Load user data and prediction (original implementation)
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Load user profile for the name
      final userProfile = await _authService.getCurrentUser();
      if (userProfile != null) {
        setState(() {
          _userName = userProfile.name ?? 'User';
          _userProfile = userProfile;
        });
      }
      
      // Then get prediction using the same parameters
      final prediction = await _predictionService.getPrediction({});
      
      if (prediction != null) {
        setState(() {
          // TODO: Refactor _loadData. It currently tries to use PredictionModel or similar from getPrediction(),
          // which is inconsistent with _predictionText (String?). This method might be deprecated.
          _predictionText = prediction?.toString(); // Assuming 'prediction' might be a Model or String
          _isLoading = false;
        });
      } else {
        setState(() {
          _predictionText = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load prediction data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _generatePrediction() async {
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      // Call the backend to generate a new prediction
      final predictionService = serviceLocator<PredictionService>();
      
      await predictionService.generatePrediction(
        _userProfile!.id,
        {}, // Environmental data placeholder
        {}, // Dietary data placeholder
        [], // Historical sleep data placeholder
      );

      // After generating, fetch the latest prediction
      await _loadData();
    } catch (e) {
      setState(() {
        _generationError = e.toString();
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  // Helper to build profile info for backend
  Map<String, dynamic> _buildProfileInfo(UserModel user) {
    final now = DateTime.now();
    final age = now.year - user.dateOfBirth.year - ((now.month < user.dateOfBirth.month || (now.month == user.dateOfBirth.month && now.day < user.dateOfBirth.day)) ? 1 : 0);
    return {
      'Age': age,
      'Gender': user.gender,
      'profileImageUrl': user.profileImageUrl ?? '',
      'userName': user.name,
      'UserId': user.id,
    };
  }

  Future<void> _makePredictionWithUserData() async {
    if (_userProfile == null) {
      await _loadUserProfile();
      if (_userProfile == null) {
        setState(() {
          _errorMessage = 'User profile not loaded.';
          _isLoading = false;
        });
        return;
      }
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // Build profile info for backend
      final profileInfo = _buildProfileInfo(_userProfile!);
      // Use the mapping utility to flatten and map all data to backend keys

      _logger.i('[PREDICTION] Sending mappedData to backend: ' + jsonEncode(widget.sleepData ?? {}));
      final prediction = await _predictionService.makePrediction(
        sleepData: widget.sleepData ?? {},
        environmentalData: widget.environmentalData ?? {},
        dietaryData: widget.dietaryData ?? {},
        profileInfo: profileInfo,
      );
      _logger.i('[PREDICTION] Received prediction: ' + jsonEncode(prediction?.toJson() ?? {}));
      if (prediction != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        // Navigate to RecommendationScreen and pass userProfile and recommendations
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationScreen(
              recommendations: prediction.recommendations,
              userProfile: _userProfile,
            ),
          ),
        );
        // Also navigate to graph screen with contributing factors
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionGraphScreen(
              contributingFactors: prediction.contributingFactors,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'No prediction result.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Prediction failed: $e';
        _isLoading = false;
      });
    }
  }
  
  // This method is no longer needed as it has been replaced by the version above
  // Keeping this comment for reference
  
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF31244C), // Updated purple color
                ),
                child: const Text(
                  'Prediction',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montaga',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
                child: _isLoading
                    ? const Center(child: LoadingIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  _errorMessage!,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FutureBuilder<UserModel?>(
                                future: _authService.getCurrentUserModel(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final user = snapshot.data!;
                                  return Row(
                                    children: <Widget>[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          const Text(
                                            'Hi!,',
                                            style: TextStyle(
                                              fontFamily: 'Montaga',
                                              fontSize: 36,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF31244C),
                                            ),
                                          ),
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              fontFamily: 'Montaga',
                                              fontSize: 36,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF31244C),
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
                                        child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                            ? ClipOval(
                                                child: Image.network(
                                                  user.profileImageUrl!,
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
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // Prediction box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF31244C),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(maxHeight: 400),
                                child: SingleChildScrollView(
                                  child: (_predictionText == null || _predictionText!.isEmpty)
                                      ? const Text(
                                          "No prediction data available. Please complete the data entry process or try refreshing to see your prediction.",
                                          style: TextStyle(
                                            fontFamily: 'Montaga',
                                            fontSize: 16,
                                            color: Colors.white,
                                            height: 1.7,
                                          ),
                                          textAlign: TextAlign.center,
                                        )
                                      : Text(
                                          _predictionText!, // This now contains the combined text
                                          style: const TextStyle(
                                            fontFamily: 'Montaga',
                                            fontSize: 16,
                                            color: Colors.white,
                                            height: 1.7,
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              // Additional content can go here
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Divider(height: 0,color: Colors.transparent,),
                              ),
                              // Spacer to push buttons to bottom
                              // const SizedBox(height: 80),
                              // Space for content separation
                              // const SizedBox(height: 16),
                              // View prediction as graph button
                              Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  child: ElevatedButton(
                                    // TODO: Re-enable and adjust when backend provides structured contributing factors.
                                    // The current _predictionText is a simple string and does not contain parsable factors for the graph.
                                    onPressed: (_contributingFactors != null && _contributingFactors!.isNotEmpty)
                                        ? () {
                                            _logger.i('PredictionScreen: Navigating to graph with contributingFactors: ${jsonEncode(_contributingFactors)}');
                                            Navigator.pushNamed(
                                              context,
                                              AppConstants.predictionGraphRoute,
                                              arguments: {'contributingFactors': _contributingFactors},
                                            );
                                          }
                                        : null,
                                    // onPressed: (_predictionText != null && _predictionText!.isNotEmpty) ? () {
                                    //   // This would require PredictionGraphScreen to be updated or a new way to get factors.
                                    //   // For now, it's disabled as 'contributingFactors' are not available.
                                    //   /*
                                    //   Navigator.pushNamed(
                                    //     context,
                                    //     AppConstants.predictionGraphRoute,
                                    //     arguments: {'contributingFactors': {}}, // Placeholder or parsed factors
                                    //   );
                                    //   */
                                    // } : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF65558F),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 3,
                                    ),
                                    child: const Text(
                                      'View prediction as graph',
                                      style: TextStyle(
                                        fontFamily: 'Montaga',
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // View recommendation button
                              Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  child: ElevatedButton(
                                    onPressed: (_predictionText != null && _predictionText!.isNotEmpty && _recommendations.isNotEmpty) ? () {
                                      Navigator.pushNamed(
                                        context,
                                        AppConstants.recommendationRoute,
                                        arguments: {
                                          'recommendations': _recommendations,
                                          'userProfile': _userProfile, 
                                        },
                                      );
                                    } : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF65558F),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 3,
                                      disabledBackgroundColor: Colors.grey.shade400,
                                    ),
                                    child: const Text(
                                      'View Recommendation',
                                      style: TextStyle(
                                        fontFamily: 'Montaga',
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
              ),
            ],
          ),
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
  
  String _formatContributingFactors(Map<String, dynamic> factors) {
    final formattedFactors = <String>[];
    
    factors.forEach((key, value) {
      if (value is num && value > 0.3) { // Only show factors with significant impact
        final readableKey = key.replaceAll('_', ' ');
        final capitalizedKey = readableKey[0].toUpperCase() + readableKey.substring(1);
        formattedFactors.add(capitalizedKey);
      }
    });
    
    if (formattedFactors.isEmpty) {
      return 'None identified';
    }
    
    return formattedFactors.join(', ');
  }
} 