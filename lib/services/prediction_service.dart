import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/prediction_model.dart';
import '../models/sleep_data_model.dart';
import '../models/environmental_data_model.dart';
import '../models/dietary_data_model.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'base_service.dart';
import 'service_locator.dart';
import 'logger_service.dart';
import '../models/factor_progress.dart';

class PredictionService extends BaseService {
  final _weatherDio = Dio();
  final ApiService _apiService;
  final LoggerService _logger = LoggerService();
  static const String _weatherApiBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _weatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  
  PredictionService({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super();
  
  // Generate a new prediction
  Future<PredictionModel> generatePrediction(
    String userId, 
    Map<String, dynamic> environmentalData,
    Map<String, dynamic> dietaryData,
    List<SleepDataModel> historicalSleepData,
  ) async {
    try {
      // Prepare input data for prediction
      final inputData = {
        'userId': userId,
        'environmentalData': environmentalData,
        'dietaryData': dietaryData,
        'historicalSleepData': historicalSleepData.map((data) => {
          'date': data.date.toIso8601String(),
          'sleepDuration': data.sleepDuration,
          'interruptionCount': data.interruptionCount,
          'timeToFallAsleep': data.timeToFallAsleep,
          'sleepQuality': data.sleepQuality,
        }).toList(),
      };
      
      // Generate prediction using backend ML model
      final response = await _apiService.post(
        ApiConfig.endpoints.predictions.generate,
        inputData,
      );
      return PredictionModel.fromJson(response);
    } catch (e) {
      _logger.e('Error generating prediction', e);
      rethrow;
    }
  }
  
  // Get prediction by ID
  Future<PredictionModel?> getPredictionById(String id) async {
    final cacheKey = super.generateCacheKey('prediction_$id');
    
    try {
      final response = await _apiService.get(ApiConfig.endpoints.predictions.byId(id));
      return PredictionModel.fromJson(response);
    } catch (e) {
      _logger.e('Error getting prediction by ID', e);
      return null;
    }
  }
  
  // Get all predictions for a user
  Future<List<PredictionModel>> getPredictionsForUser(String userId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.endpoints.predictions.byUser(userId),
      );
      return (response as List)
          .map((data) => PredictionModel.fromJson(data))
          .toList();
    } catch (e) {
      _logger.e('Error getting predictions for user', e);
      return [];
    }
  }
  
  // Get prediction based on parameters (legacy method)  
  Future<PredictionModel?> getPrediction(Map<String, dynamic> params) async {
    try {
      final response = await _apiService.get(
        ApiConfig.endpoints.predictions.predict,
        queryParameters: params,
      );
      return PredictionModel.fromJson(response);
    } catch (e) {
      _logger.e('Error getting prediction', e);
      return null;
    }
  }
  

  
  // Make AI-based prediction with user-provided data
  Future<PredictionModel?> makePrediction({
    required Map<String, dynamic> sleepData,
    required Map<String, dynamic> environmentalData,
    required Map<String, dynamic> dietaryData,
    Map<String, dynamic>? profileInfo,
  }) async {
    try {
      _logger.i('Making AI prediction with user data');
      
      final userId = await serviceLocator.auth.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated. Cannot make prediction.');
      }

      // Combine sleep data with profile info, as the backend expects a single sleepData object
      final Map<String, dynamic> finalSleepData = Map.from(sleepData);
      if (profileInfo != null) {
        finalSleepData.addAll(profileInfo);
      }

      final payload = {
        'userId': userId,
        'sleepData': finalSleepData,
        'environmentalData': environmentalData,
        'dietaryData': dietaryData,
      };

      _logger.i('Sending data to endpoint: ${ApiConfig.endpoints.predictions.predict}');
      _logger.i('Payload: ${jsonEncode(payload)}');

      final response = await _apiService.post(
        ApiConfig.endpoints.predictions.predict,
        payload,
      );

      if (response != null && response is Map<String, dynamic>) {
        _logger.i('Prediction response received: $response');
        return PredictionModel.fromJson(response);
      }
      _logger.w('Prediction response was null or not a map.');
      return null;
    } catch (e) {
      _logger.e('Error making AI prediction: ${e.toString()}');
      return null;
    }
  }
  
  // Helper to calculate age from date of birth
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
  
  // Submit combined sleep data to the backend
  Future<void> submitSleepData({
    required String userId,
    required Map<String, dynamic> sleepPatterns,
    required Map<String, dynamic> profileInfo,
    required Map<String, dynamic> dietaryHabits,
    required Map<String, dynamic> environmentalFactors,
  }) async {
    try {
      _logger.i('Submitting combined sleep data for user $userId');
      final payload = {
        'userId': userId,
        'sleepPatterns': sleepPatterns,
        'profileInfo': profileInfo,
        'dietaryHabits': dietaryHabits,
        'environmentalFactors': environmentalFactors,
      };
      await _apiService.post(ApiConfig.endpoints.sleepData.submit, payload);
      _logger.i('Sleep data submitted successfully for user $userId');
    } catch (e) {
      _logger.e('Error submitting sleep data for user $userId', e);
      rethrow; // Rethrow to be handled by the caller
    }
  }

  // Fetch the latest prediction and recommendations for a user
  Future<Map<String, dynamic>> fetchLatestPredictionWithRecommendations(String userId) async {
    try {
      _logger.i('Fetching latest prediction and recommendations for user $userId');
      final response = await _apiService.get(
        ApiConfig.endpoints.predictions.getLatestWithRecommendations,
        queryParameters: {'userId': userId},
      );
      _logger.i('RAW API RESPONSE for prediction/recommendations: ${jsonEncode(response)}');
      _logger.i('RAW PREDICTION RESPONSE: $response');
      if (response != null && response is Map<String, dynamic>) {
        _logger.i('Successfully fetched prediction and recommendations for user $userId');
        return response;
      }
      _logger.w('No prediction data returned for user $userId');
      return {}; // Return empty map if no data or unexpected format
    } catch (e) {
      _logger.e('Error fetching latest prediction and recommendations for user $userId', e);
      rethrow; // Rethrow to be handled by the caller
    }
  }
  
  // Get predictions for a date range
  Future<List<PredictionModel>> getPredictionsForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.get(
        ApiConfig.endpoints.predictions.byDateRange(startDate, endDate),
      );
      
      return (response as List)
          .map((data) => PredictionModel.fromJson(data))
          .toList();
    } catch (e) {
      _logger.e('Error getting predictions for date range', e);
      return [];
    }
  }
  
  // Get latest prediction
  Future<Map<String, dynamic>> getLatestPrediction([String? userId]) async {
    try {
      // If userId is not provided, get current user's ID
      String? targetUserId = userId;
      if (targetUserId == null) {
        targetUserId = await serviceLocator.auth.getCurrentUserId();
      }
      
      // Handle case where we still don't have a userId
      if (targetUserId == null) {
        throw Exception('User ID not available');
      }
      
      final response = await _apiService.get(
        ApiConfig.endpoints.predictions.latest,
        queryParameters: {'userId': targetUserId},
      );
      
      // Return the full response data for flexibility in UI
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
      return {};
    } catch (e) {
      _logger.e('Error getting latest prediction', e);
      return {};
    }
  }
  
  // Get recommendations based on sleep data
  Future<List<String>> getRecommendations([Map<String, dynamic>? params]) async {
    try {
      // If params is not provided, create an empty map
      final queryParams = params ?? {};
      
      // If userId is not in params, get current user's ID
      if (!queryParams.containsKey('userId')) {
        final currentUserId = await serviceLocator.auth.getCurrentUserId();
        if (currentUserId != null) {
          queryParams['userId'] = currentUserId;
        }
      }
      
      final response = await _apiService.get(
        ApiConfig.endpoints.predictions.recommendations,
        queryParameters: queryParams,
      );
      
      if (response != null) {
        if (response is Map<String, dynamic> && response.containsKey('recommendations')) {
          return List<String>.from(response['recommendations']);
        } else if (response is List) {
          return List<String>.from(response);
        }
      }
      
      // Return empty list if response is invalid
      return <String>[];
    } catch (e) {
      _logger.e('Error getting recommendations', e);
      return <String>[];
    }
  }
  
  // Get weather data from external API
  Future<Map<String, dynamic>> getWeatherData(double latitude, double longitude) async {
    final cacheKey = generateCacheKey(
      'weather_data',
      {'lat': latitude, 'lon': longitude},
    );
    
    return executeOperation(
      operation: () async {
        if (_weatherApiKey.isEmpty) {
          throw Exception('OpenWeather API key not configured');
        }
        
        final response = await _weatherDio.get(
          '$_weatherApiBaseUrl/weather',
          queryParameters: {
            'lat': latitude,
            'lon': longitude,
            'appid': _weatherApiKey,
            'units': 'metric',
          },
        );
        
        return response.data;
      },
      cacheKey: cacheKey,
      cacheExpiration: const Duration(minutes: 30), // Weather data updates every 30 mins
    );
  }
  
  // Delete prediction
  Future<void> deletePrediction(String id) async {
    try {
      await _apiService.delete(ApiConfig.endpoints.predictions.byId(id));
      // Clear related caches
      await super.clearCache(super.generateCacheKey('prediction_$id'));
      final userId = await serviceLocator.auth.getCurrentUserId();
      if (userId != null) {
        await super.clearCache(super.generateCacheKey('predictions_user_$userId'));
      }
    } catch (e) {
      _logger.e('Error deleting prediction', e);
      rethrow;
    }
  }

  // Fetch progress report for a user
  Future<List<FactorProgress>> getProgressReport(String userId) async {
    try {
      _logger.i('Fetching progress report for user $userId');
      final response = await _apiService.get(
        ApiConfig.endpoints.users.progressReport, // Endpoint: /users/progress-report
        queryParameters: {'userId': userId}, // Pass userId as a query parameter
      );

      if (response != null && response is List) {
        // Ensure that each item in the list is a Map<String, dynamic>
        // before attempting to call FactorProgress.fromJson
        final List<FactorProgress> progressReportData = response
            .where((item) => item is Map<String, dynamic>) // Filter out non-map items
            .map((data) => FactorProgress.fromJson(data as Map<String, dynamic>))
            .toList();
        _logger.i('Successfully fetched progress report for user $userId. Count: ${progressReportData.length}');
        return progressReportData;
      }
      _logger.w('No progress report data returned or unexpected format for user $userId. Response: $response');
      return []; // Return empty list if no data or unexpected format
    } catch (e) {
      _logger.e('Error fetching progress report for user $userId', e);
      return []; // Return empty list on error to prevent app crash
    }
  }

  /// Robust method: Always map, POST new data, and return prediction
  Future<PredictionModel?> submitAndFetchPrediction({
    required Map<String, dynamic> sleepData,
    required Map<String, dynamic> environmentalData,
    required Map<String, dynamic> dietaryData,
  }) async {
    // 1. Fetch user profile for age/gender
    final userProfile = await serviceLocator.auth.getCurrentUserModel();
    if (userProfile == null) throw Exception('User profile not found.');

    final profileMap = {
      'Age': _calculateAge(userProfile.dateOfBirth),
      'Gender': userProfile.gender,
      'userName': userProfile.name,
    };

    final requestData = {
      'sleepData': sleepData,
      'environmentalData': environmentalData,
      'dietaryData': dietaryData,
    };

    _logger.i('[PREDICTION] Sending prediction request: ' + jsonEncode(requestData));

    // 3. POST to backend
    final response = await _apiService.post(
      ApiConfig.endpoints.predictions.predict,
      requestData,
    );

    _logger.i('[PREDICTION] Received prediction response: ' + jsonEncode(response));

    // 4. Return the prediction model if response is valid
    if (response != null && response is Map<String, dynamic>) {
      return PredictionModel.fromJson(response);
    }
    throw Exception('Prediction failed or invalid response from backend.');
  }
} 