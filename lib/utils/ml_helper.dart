import 'dart:io';
import 'dart:math';
// Temporarily disabled TFLite import
// import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import '../models/prediction_model.dart';

class PredictionResult {
  final double predictionScore;
  final int predictedInterruptionCount;
  final List<Map<String, dynamic>> predictedInterruptionWindows;
  final Map<String, double> contributingFactors;
  final List<String> recommendations;

  PredictionResult({
    required this.predictionScore,
    required this.predictedInterruptionCount,
    required this.predictedInterruptionWindows,
    required this.contributingFactors,
    required this.recommendations,
  });
}

class MLHelper {
  static final MLHelper _instance = MLHelper._internal();
  // Temporarily commented out
  // Interpreter? _interpreter;
  bool _modelLoaded = false;

  factory MLHelper() {
    return _instance;
  }

  MLHelper._internal();

  // Load the TensorFlow Lite model
  Future<void> _loadModel() async {
    try {
      // For demonstration purposes - in a real app, this would load a real TensorFlow Lite model
      // _interpreter = await Interpreter.fromAsset('assets/ml_models/sleep_prediction_model.tflite');
      // _modelLoaded = true;
      
      // Simulate model loading
      await Future.delayed(const Duration(seconds: 1));
      _modelLoaded = true;
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  // Run prediction using the TensorFlow Lite model
  Future<PredictionResult> runPrediction(Map<String, dynamic> inputData) async {
    if (!_modelLoaded) {
      await _loadModel();
    }

    try {
      // In a real implementation, this would process the input data and run it through the TensorFlow model
      // For demonstration purposes, we'll simulate the prediction with random data
      
      // Simulate the model taking time to process
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate a random prediction score (0.0 to 1.0)
      final random = Random();
      final predictionScore = random.nextDouble();
      
      // Determine interruption count based on prediction score
      final predictedInterruptionCount = (predictionScore * 5).round();
      
      // Generate random interruption windows
      final predictedInterruptionWindows = _generateInterruptionWindows(
        predictedInterruptionCount,
        inputData,
      );
      
      // Generate contributing factors
      final contributingFactors = _generateContributingFactors(inputData);
      
      // Generate recommendations
      final recommendations = _generateRecommendations(contributingFactors);
      
      return PredictionResult(
        predictionScore: predictionScore,
        predictedInterruptionCount: predictedInterruptionCount,
        predictedInterruptionWindows: predictedInterruptionWindows,
        contributingFactors: contributingFactors,
        recommendations: recommendations,
      );
    } catch (e) {
      print('Error running prediction: $e');
      rethrow;
    }
  }
  
  // Generate random interruption windows
  List<Map<String, dynamic>> _generateInterruptionWindows(
    int count,
    Map<String, dynamic> inputData,
  ) {
    final random = Random();
    final windows = <Map<String, dynamic>>[];
    
    // Use current date as base for the predictions
    final now = DateTime.now();
    final bedTime = DateTime(now.year, now.month, now.day, 22, 0); // 10:00 PM
    
    for (int i = 0; i < count; i++) {
      // Generate a random time between 10 PM and 7 AM
      final hourOffset = random.nextInt(9); // 0-8 hours after bedtime
      final minuteOffset = random.nextInt(60); // 0-59 minutes
      
      final startTime = bedTime.add(Duration(hours: hourOffset, minutes: minuteOffset));
      
      // Window duration between 5-30 minutes
      final windowDuration = 5 + random.nextInt(26);
      final endTime = startTime.add(Duration(minutes: windowDuration));
      
      // Probability between 0.6 and 0.95
      final probability = 0.6 + (random.nextDouble() * 0.35);
      
      windows.add({
        'startTime': startTime,
        'endTime': endTime,
        'probability': probability,
      });
    }
    
    // Sort windows by start time
    windows.sort((a, b) => (a['startTime'] as DateTime).compareTo(b['startTime'] as DateTime));
    
    return windows;
  }
  
  // Generate contributing factors
  Map<String, double> _generateContributingFactors(Map<String, dynamic> inputData) {
    final random = Random();
    
    // Define possible factors
    const factors = [
      'room_temperature',
      'caffeine_intake',
      'alcohol_consumption',
      'exercise_timing',
      'screen_time_before_bed',
      'noise_level',
      'light_exposure',
      'late_meal',
      'stress_level',
      'irregular_sleep_schedule',
    ];
    
    final contributingFactors = <String, double>{};
    
    // Generate 3-5 random factors
    final factorCount = 3 + random.nextInt(3);
    final selectedFactors = factors.toList()..shuffle();
    
    for (int i = 0; i < factorCount; i++) {
      // Weight between 0.1 and 0.9
      final weight = 0.1 + (random.nextDouble() * 0.8);
      contributingFactors[selectedFactors[i]] = weight;
    }
    
    return contributingFactors;
  }
  
  // Generate recommendations based on contributing factors
  List<String> _generateRecommendations(Map<String, double> contributingFactors) {
    final recommendations = <String>[];
    
    // Map factors to recommendations
    final factorRecommendations = {
      'room_temperature': 'Keep your bedroom temperature between 65-68°F (18-20°C) for optimal sleep.',
      'caffeine_intake': 'Avoid consuming caffeine at least 6 hours before bedtime.',
      'alcohol_consumption': 'Limit alcohol consumption, especially in the evening, as it disrupts sleep cycles.',
      'exercise_timing': 'Try to complete exercise at least 3 hours before bedtime.',
      'screen_time_before_bed': 'Avoid screens (phones, tablets, computers) for at least 1 hour before bed.',
      'noise_level': 'Use a white noise machine or earplugs to minimize noise disturbances.',
      'light_exposure': 'Ensure your bedroom is dark and consider using blackout curtains or a sleep mask.',
      'late_meal': 'Avoid heavy meals within 3 hours of bedtime.',
      'stress_level': 'Practice relaxation techniques such as deep breathing or meditation before sleep.',
      'irregular_sleep_schedule': 'Maintain a consistent sleep schedule, even on weekends.',
    };
    
    // Sort factors by weight (highest first)
    final sortedFactors = contributingFactors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Generate recommendations for top factors
    for (final factor in sortedFactors) {
      if (factorRecommendations.containsKey(factor.key)) {
        recommendations.add(factorRecommendations[factor.key]!);
      }
    }
    
    return recommendations;
  }
} 