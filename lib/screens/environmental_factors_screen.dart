import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/custom_profile_drawer.dart';
import '../services/prediction_service.dart';
import '../services/auth_service.dart';
import '../services/environment_service.dart';
import 'dart:async';
import '../models/prediction_model.dart';
import '../widgets/loading_indicator.dart';

class EnvironmentalFactorsScreen extends StatefulWidget {
  final bool onSaveOnly;
  final Map<String, dynamic>? sleepData;
  final Map<String, dynamic>? dietaryData;
  final Map<String, dynamic>? profileInfo;

  const EnvironmentalFactorsScreen({
    super.key, 
    this.onSaveOnly = false,
    this.sleepData,
    this.dietaryData,
    this.profileInfo,
  });

  @override
  State<EnvironmentalFactorsScreen> createState() => _EnvironmentalFactorsScreenState();
}

class _EnvironmentalFactorsScreenState extends State<EnvironmentalFactorsScreen> {
  final _formKey = GlobalKey<FormState>();
  // Text controllers for inputable fields
  final TextEditingController _lightIntensityController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _soundLevelController = TextEditingController();
  String _soundExposure = 'Quiet (< 30 dB)';
  late EnvironmentService _envService;
  StreamSubscription<double>? _luxSub;
  StreamSubscription<double>? _tempSub;
  StreamSubscription<double>? _dbSub;
  bool _isLoading = false;
  
  // Store final sensor values after 2 seconds
  double? _finalLightIntensity;
  double? _finalSoundLevel;
  bool _isCollecting = true;

  @override
  void initState() {
    super.initState();
    _envService = EnvironmentService();

    // Start collecting sensor values
    _luxSub = _envService.luxStream.listen((lux) {
      if (_isCollecting) {
        setState(() {
          _finalLightIntensity = lux;
          _lightIntensityController.text = lux.toStringAsFixed(0);
        });
      }
    });
    _dbSub = _envService.dbStream.listen((db) {
      if (_isCollecting) {
        setState(() {
          _finalSoundLevel = db;
          _soundLevelController.text = db.toStringAsFixed(0);
          if (db < 30) {
            _soundExposure = 'Quiet (< 30 dB)';
          } else if (db < 60) {
            _soundExposure = 'Moderate (30-60 dB)';
          } else {
            _soundExposure = 'Loud (> 60 dB)';
          }
        });
      }
    });
    _tempSub = _envService.temperatureStream.listen((temp) {
      // Only update if user hasn't typed anything yet
      if (_temperatureController.text.isEmpty) {
        setState(() {
          _temperatureController.text = temp.toStringAsFixed(1);
        });
      }
    });

    // Stop collecting after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isCollecting = false;
      });
      _luxSub?.cancel();
      _dbSub?.cancel();
    });
  }
  
  @override
  void dispose() {
    _luxSub?.cancel();
    _tempSub?.cancel();
    _dbSub?.cancel();
    _envService.dispose();
    _lightIntensityController.dispose();
    _temperatureController.dispose();
    _soundLevelController.dispose();
    super.dispose();
  }

  // Helper method to build environmental data object
  Map<String, dynamic>? _buildEnvironmentalData() {
    // Light intensity: sensor value ya default 0
    final lightValue = _finalLightIntensity?.round() ?? int.tryParse(_lightIntensityController.text) ?? 0;
    // Sound level: sensor value ya default 0
    final soundValue = _finalSoundLevel?.round() ?? int.tryParse(_soundLevelController.text) ?? 0;
    final tempValue = double.tryParse(_temperatureController.text);
    final soundExposure = _soundExposure;
    // Light intensity ab kabhi null nahi hogi, isliye uska check hata diya
    // Sound level ab kabhi null nahi hoga, isliye uska check hata diya
    if (tempValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid temperature.')),
      );
      return null;
    }
    if (soundExposure.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sound exposure is missing.')),
      );
      return null;
    }
    return {
      'lightIntensity': lightValue,
      'temperature': tempValue,
      'soundExposure': soundExposure,
      'noiseLevel': soundValue,
    };
  }

  // Helper to map keys to backend expected format
  Map<String, dynamic> _mapToBackendFormat(Map<String, dynamic> data) {
    final Map<String, String> keyMap = {
      'sleepDuration': 'Sleep Duration',
      'stressLevel': 'Stress Level',
      'rateSleepQuality': 'Rate Sleep Quality',
      'useElectronicDevicesBeforeBed': 'Use Electronic Devices Before Bed',
      'howRelaxedBeforeSleep': 'How Relaxed Before Sleep',
      'awakeningsDuringNight': 'Awakenings During Night',
            'lightIntensity': 'Light Intensity',
      'temperature': 'Temperature',
      'soundExposure': 'Sound Exposure',
      'noiseLevel': 'Noise Level',
      'takeBreakfast': 'Take Breakfast',
      'breakfastTimeHour': 'Breakfast Time Hour',
      'breakfastTimeMinute': 'Breakfast Time Minute',
      'breakfastFoodType': 'Breakfast Food Type',
      'breakfastPortionSize': 'Breakfast Portion Size',
      'doLunch': 'Do Lunch',
      'lunchTimeHour': 'Lunch Time Hour',
      'lunchTimeMinute': 'Lunch Time Minute',
      'lunchFoodType': 'Lunch Food Type',
      'lunchPortionSize': 'Lunch Portion Size',
      'haveDinner': 'Have Dinner',
      'dinnerTimeHour': 'Dinner Time Hour',
      'dinnerTimeMinute': 'Dinner Time Minute',
      'dinnerFoodType': 'Dinner Food Type',
      'dinnerPortionSize': 'Dinner Portion Size',
      'noOfMealsPerDay': 'No Of Meals Per Day',
    };
    return data.map((key, value) => MapEntry(keyMap[key] ?? key, value));
  }

  Widget _buildInputField(String label, {TextEditingController? controller, IconData? icon, String? suffix}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montaga',
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        Container(
          width: 170,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF31244C), width: 2),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Use TextField for inputable fields when controller is provided
              if (controller != null) ...[              
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          readOnly: !(label.toLowerCase().contains('temperature')),
                          enabled: label.toLowerCase().contains('temperature'),
                          style: const TextStyle(
                            fontFamily: 'Montaga',
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (suffix != null)
                        Text(
                          ' $suffix',
                          style: const TextStyle(
                            fontFamily: 'Montaga',
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (icon != null) ...[                
                const SizedBox(width: 10),
                Icon(
                  icon,
                  size: 22,
                  color: Colors.grey.shade600,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Save environmental data, send to backend ML model, and navigate to PredictionScreen
  Future<void> _saveAndContinue() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final envData = _buildEnvironmentalData();
      if (envData == null) {
        setState(() => _isLoading = false);
        return;
      }
      // Defensive: Ensure all keys have minimum default values (not null, not 0)
      final rawArgs = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
      final allData = {
        'sleepData': widget.sleepData ?? (rawArgs['sleepData'] is Map ? rawArgs['sleepData'] : null) ?? {'Sleep Duration': 1, 'Awakenings During Night': 1, 'Rate Sleep Quality': 1, 'Stress Level': 1},
        'dietaryData': widget.dietaryData ?? (rawArgs['dietaryData'] is Map ? rawArgs['dietaryData'] : null) ?? {'Meals Per Day': 1, 'Meals': []},
        'profileInfo': widget.profileInfo ?? (rawArgs['profileInfo'] is Map ? rawArgs['profileInfo'] : null) ?? {'age': 1, 'gender': 'male'},
      };
      allData['environmentalData'] = envData;
      // Minimum complete maps for all sections
      Map<String, dynamic> minSleepData = {
        'Sleep Duration': 7,
        'Awakenings During Night': 1,
        'Rate Sleep Quality': 1,
        'Stress Level': 1,
        'Weekday Bedtime Hour': 22,
        'Weekday Bedtime Minute': 0,
        'Weekday Wake-up Hour': 7,
        'Weekday Wake-up Minute': 0,
        'Weekend Bedtime Hour': 22,
        'Weekend Bedtime Minute': 0,
        'Weekend Wake-up Hour': 8,
        'Weekend Wake-up Minute': 0,
        'Use Electronic Devices Before Bed': false,
        'How Relaxed Before Sleep': 1,
      };
      Map<String, dynamic> minDietaryData = {
        'Meals Per Day': 3,
        'Meals': [],
        'takeBreakfast': false,
        'breakfastTimeHour': 8,
        'breakfastTimeMinute': 0,
        'breakfastFoodType': '',
        'breakfastPortionSize': 1,
        'doLunch': false,
        'lunchTimeHour': 12,
        'lunchTimeMinute': 0,
        'lunchFoodType': '',
        'lunchPortionSize': 1,
        'haveDinner': false,
        'dinnerTimeHour': 18,
        'dinnerTimeMinute': 0,
        'dinnerFoodType': '',
        'dinnerPortionSize': 1,
        'noOfMealsPerDay': 1,
      };
      Map<String, dynamic> minEnvData = {
        'lightIntensity': 10,
        'temperature': 25,
        'soundExposure': 'Quiet (< 30 dB)',
      };
      // Merge user data with minimums (user value priority)
      Map<String, dynamic> mergedSleepData = {...minSleepData, ...allData['sleepData']};
      Map<String, dynamic> mergedDietaryData = {...minDietaryData, ...allData['dietaryData']};
      Map<String, dynamic> mergedEnvData = {...minEnvData, ...envData};
      final sleepData = _mapToBackendFormat(mergedSleepData);
      final dietaryData = _mapToBackendFormat(mergedDietaryData);
      final profileInfo = allData['profileInfo'];
      final envDataMapped = mergedEnvData;
      // Safe maps: agar empty ho to minimum values bhejo
      final safeSleepData = sleepData.isNotEmpty ? sleepData : minSleepData;
      final safeDietaryData = dietaryData.isNotEmpty ? dietaryData : minDietaryData;
      final safeProfileInfo = profileInfo.isNotEmpty ? profileInfo : {'age': 1, 'gender': 'male'};
      final safeEnvData = envDataMapped.isNotEmpty ? envDataMapped : minEnvData;
      print('[DEBUG] Sending to backend: sleepData: '
          + safeSleepData.toString() + '\ndietaryData: ' + safeDietaryData.toString() + '\nenvData: ' + safeEnvData.toString());
      if (widget.onSaveOnly) {
        Navigator.pop(context, safeEnvData);
        return;
      }
      final predictionService = Provider.of<PredictionService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final String? userId = await authService.getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated. Please log in.')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
      void _submitDataForPrediction() {
        if (!_formKey.currentState!.validate()) {
          return; // If form is not valid, do not proceed
        }

        // Show loading dialog
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

        // Build the environmental data object
        final environmentalData = _buildEnvironmentalData();

        // Use a Future.delayed to simulate network latency and allow UI to update
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context); // Close loading dialog

          // Make the prediction
          predictionService.makePrediction(
            sleepData: safeSleepData,
            dietaryData: safeDietaryData,
            environmentalData: safeEnvData,
            profileInfo: safeProfileInfo,
          );
        });
      }
      await predictionService.makePrediction(
        sleepData: safeSleepData,
        dietaryData: safeDietaryData,
        environmentalData: safeEnvData,
        profileInfo: safeProfileInfo,
      );
      final Map<String, dynamic> predictionResult = await predictionService.fetchLatestPredictionWithRecommendations(userId);
      if (mounted) {
        // Defensive: Remove all null values from allData before spreading
        final cleanedAllData = Map<String, dynamic>.from(allData)
          ..removeWhere((key, value) => value == null);
        Navigator.pushReplacementNamed(
          context,
          AppConstants.predictionRoute,
          arguments: {
            ...cleanedAllData,
            'predictionResult': predictionResult,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending data to ML model: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomProfileDrawer(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2041),
              ),
              child: const Text(
                'Environmental Factors',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 100, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Light Intensity Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Light Intensity',
                          style: TextStyle(
                            fontFamily: 'Montaga',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          width: 170,
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF31244C), width: 2),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: TextFormField(
                                  controller: _lightIntensityController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontFamily: 'Montaga',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    isDense: true,
                                  ),
                                  enabled: false, // read-only
                                ),
                              ),
                              const Text(
                                ' lux',
                                style: TextStyle(
                                  fontFamily: 'Montaga',
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.wb_sunny_outlined,
                                size: 22,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Sound Level Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sound Level',
                          style: TextStyle(
                            fontFamily: 'Montaga',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          width: 170,
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF31244C), width: 2),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: TextFormField(
                                  controller: _soundLevelController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontFamily: 'Montaga',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    isDense: true,
                                  ),
                                  enabled: false, // read-only
                                ),
                              ),
                              const Text(
                                ' dB',
                                style: TextStyle(
                                  fontFamily: 'Montaga',
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Temperature Input (user-editable)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Temperature',
                          style: TextStyle(
                            fontFamily: 'Montaga',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          width: 170,
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF31244C), width: 2),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: TextFormField(
                                  controller: _temperatureController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontFamily: 'Montaga',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    isDense: true,
                                  ),
                                  enabled: true, // User can edit
                                ),
                              ),
                              const Text(
                                ' °C',
                                style: TextStyle(
                                  fontFamily: 'Montaga',
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sound Exposure',
                      style: TextStyle(
                        fontFamily: 'Montaga',
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 100.0),
                          child: RadioListTile<String>(
                            title: const Text(
                              'Quiet (< 30 dB)',
                              style: TextStyle(
                                fontFamily: 'Montaga',
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            value: 'Quiet (< 30 dB)',
                            groupValue: _soundExposure,
                            onChanged: null,
                            activeColor: const Color(0xFF2D2041),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 100.0),
                          child: RadioListTile<String>(
                            title: const Text(
                              'Moderate (30-60 dB)',
                              style: TextStyle(
                                fontFamily: 'Montaga',
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            value: 'Moderate (30-60 dB)',
                            groupValue: _soundExposure,
                            onChanged: null,
                            activeColor: const Color(0xFF2D2041),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 100.0),
                          child: RadioListTile<String>(
                            title: const Text(
                              'Loud (> 60 dB)',
                              style: TextStyle(
                                fontFamily: 'Montaga',
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            value: 'Loud (> 60 dB)',
                            groupValue: _soundExposure,
                            onChanged: null,
                            activeColor: const Color(0xFF2D2041),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.90,
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF65558F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text(
                        'View Prediction',
                        style: TextStyle(
                          fontFamily: 'Montaga',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 18, bottom: 0),
              width: double.infinity,
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 65,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[350],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 65,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[350],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 65,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C5470),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        screenColor: Colors.white,
        currentIndex: 0,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
    );
  }
} 