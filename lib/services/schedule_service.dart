import '../config/api_config.dart';
import '../models/schedule_model.dart';
import 'api_service.dart';

/// Service responsible for CRUD operations for schedules via the backend API.
class ScheduleService {
  final ApiService _apiService;

  ScheduleService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<ScheduleModel>> getScheduleByUser(String userId) async {
    final response = await _apiService.get('${ApiConfig.endpoints.schedule.base}/$userId');
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response)
        .map(ScheduleModel.fromJson)
        .toList();
  }

  Future<ScheduleModel> addSchedule(ScheduleModel schedule) async {
    final response = await _apiService.post(ApiConfig.endpoints.schedule.base, schedule.toJson());
    return ScheduleModel.fromJson(response);
  }

  Future<ScheduleModel> updateSchedule(String id, Map<String, dynamic> data) async {
    final response = await _apiService.put('${ApiConfig.endpoints.schedule.base}/$id', data);
    return ScheduleModel.fromJson(response);
  }

  Future<void> deleteSchedule(String id) async {
    await _apiService.delete('${ApiConfig.endpoints.schedule.base}/$id');
  }
}
