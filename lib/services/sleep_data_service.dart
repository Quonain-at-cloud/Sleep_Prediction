import '../models/sleep_data_model.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'base_service.dart';
import 'service_locator.dart';
import 'logger_service.dart';

class SleepDataService extends BaseService {
  final ApiService _apiService;
  final LoggerService _logger = LoggerService();

  SleepDataService({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super();

  // Add new sleep data
  Future<SleepDataModel> addSleepData(SleepDataModel sleepData) async {
    try {
      // Calculate sleep duration if not provided
      int calculatedDuration = sleepData.sleepDuration;
      if (calculatedDuration == 0) {
        final difference = sleepData.wakeUpTime.difference(sleepData.bedTime);
        calculatedDuration = difference.inMinutes - sleepData.timeToFallAsleep;
      }
      
      // Prepare data with calculated duration
      final dataWithDuration = sleepData.copyWith(
        sleepDuration: calculatedDuration,
      );
      
      final response = await _apiService.post(
        ApiConfig.endpoints.sleepData.base,
        dataWithDuration.toJson(),
      );
      
      return SleepDataModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update sleep data
  Future<SleepDataModel> updateSleepData(SleepDataModel sleepData) async {
    try {
      final response = await _apiService.patch(
        ApiConfig.endpoints.sleepData.byId(sleepData.id),
        sleepData.toJson(),
      );
      return SleepDataModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get sleep data by ID
  Future<SleepDataModel?> getSleepDataById(String id) async {
    final cacheKey = super.generateCacheKey('sleep_data_$id');
    
    try {
      final response = await _apiService.get(ApiConfig.endpoints.sleepData.byId(id));
      return SleepDataModel.fromJson(response);
    } catch (e) {
      _logger.e('Error getting sleep data by ID', e);
      rethrow;
    }
  }
  
  // Get all sleep data for a user
  Future<List<SleepDataModel>> getSleepDataForUser(String userId) async {
    final cacheKey = super.generateCacheKey('sleep_data_user_$userId');
    
    try {
      final response = await _apiService.get(ApiConfig.endpoints.sleepData.byUser(userId));
      return (response as List)
          .map((data) => SleepDataModel.fromJson(data))
          .toList();
    } catch (e) {
      _logger.e('Error getting sleep data for user', e);
      rethrow;
    }
  }
  
  // Get all sleep data
  Future<List<SleepDataModel>> getSleepData() async {
    try {
      final response = await _apiService.get(ApiConfig.endpoints.sleepData.base);
      return (response as List)
          .map((data) => SleepDataModel.fromJson(data))
          .toList();
    } catch (e) {
      _logger.e('Error getting all sleep data', e);
      rethrow;
    }
  }
  
  // Get sleep data for a date range
  Future<List<SleepDataModel>> getSleepDataForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    final cacheKey = super.generateCacheKey(
      'sleep_data_range',
      {
        'userId': userId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    
    try {
      final response = await _apiService.get(
        ApiConfig.endpoints.sleepData.byDateRange(startDate, endDate),
      );
      
      return (response as List)
          .map((data) => SleepDataModel.fromJson(data))
          .toList();
    } catch (e) {
      _logger.e('Error getting sleep data for date range', e);
      rethrow;
    }
  }
  
  // Delete sleep data
  Future<void> deleteSleepData(String id) async {
    try {
      await _apiService.delete(ApiConfig.endpoints.sleepData.byId(id));
      // Clear related caches
      await super.clearCache(super.generateCacheKey('sleep_data_$id'));
      final userId = await serviceLocator.auth.getCurrentUserId();
      await super.clearCache(super.generateCacheKey('sleep_data_user_$userId'));
    } catch (e) {
      _logger.e('Error deleting sleep data', e);
      rethrow;
    }
  }
  
  // Get latest sleep data
  Future<SleepDataModel?> getLatestSleepData(String userId) async {
    final cacheKey = super.generateCacheKey('sleep_data_latest_$userId');
    
    try {
      final response = await _apiService.get(ApiConfig.endpoints.sleepData.latest);
      final List data = response as List;
      return data.isNotEmpty ? SleepDataModel.fromJson(data.first) : null;
    } catch (e) {
      _logger.e('Error getting latest sleep data', e);
      rethrow;
    }
  }
}