import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../services/auth_service.dart';
import '../services/schedule_service.dart';
import '../services/service_locator.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleService _scheduleService;
  final AuthService _authService;

  ScheduleProvider({ScheduleService? scheduleService, AuthService? authService})
      : _scheduleService = scheduleService ?? serviceLocator<ScheduleService>(),
        _authService = authService ?? serviceLocator<AuthService>();

  bool _loading = false;
  String? _error;
  final List<ScheduleModel> _schedules = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<ScheduleModel> get schedules => List.unmodifiable(_schedules);

  Map<int, List<ScheduleModel>> get scheduleByDay {
    final Map<int, List<ScheduleModel>> grouped = {};
    for (final s in _schedules) {
      final day = s.date.day;
      grouped.putIfAbsent(day, () => []).add(s);
    }
    // Sort each day's schedule by time (assuming HH:MM format)
    grouped.values.forEach((list) {
      list.sort((a, b) => a.time.compareTo(b.time));
    });
    return grouped;
  }

  Future<void> fetchSchedules() async {
    _setLoading(true);
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        _error = 'User not logged in';
        return;
      }
      final data = await _scheduleService.getScheduleByUser(userId);
      _schedules
        ..clear()
        ..addAll(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    try {
      final created = await _scheduleService.addSchedule(schedule);
      _schedules.add(created);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _scheduleService.updateSchedule(id, data);
      final index = _schedules.indexWhere((s) => s.id == id);
      if (index != -1) {
        _schedules[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _scheduleService.deleteSchedule(id);
      _schedules.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
