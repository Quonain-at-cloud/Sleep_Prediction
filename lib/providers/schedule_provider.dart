import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/schedule_service.dart';
import '../services/notification_service.dart';
import '../services/service_locator.dart';
import '../providers/notification_provider.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleService _scheduleService;
  final AuthService _authService;
  final NotificationService _notificationService = NotificationService();

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

      // Schedule notifications for all upcoming schedules
      for (final sched in _schedules) {
        final scheduledDate = _combineDateAndTime(sched);
        if (scheduledDate.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            stringId: sched.id,
            title: 'It\'s time!',
            body: 'It\'s time for ${sched.label}',
            scheduledDate: scheduledDate,
          );
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        _error = 'User not logged in';
        return;
      }

      // Create notification for schedule creation
      final notification = NotificationModel(
        title: 'Schedule Created',
        message: '${schedule.label} scheduled for ${_formatTime12(_combineDateAndTime(schedule))}',
        timestamp: DateTime.now(),
        userId: userId,
        type: 'created',
        category: schedule.type ?? schedule.label.toLowerCase(),
      );

      // Save notification to notification provider
      try {
        final notificationProvider = serviceLocator<NotificationProvider>();
        await notificationProvider.addNotificationModel(notification);
      } catch (e) {
        print('Failed to save notification: $e');
      }

      // Show OS notification
      await _notificationService.show(
        title: notification.title,
        body: notification.message,
      );
      
      final created = await _scheduleService.addSchedule(schedule);
      
      // Schedule future notification (reminder) only if not completed
      final scheduledDate = _combineDateAndTime(created);
      if (!created.checked && scheduledDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          stringId: created.id,
          title: created.label, // Use schedule title for reminder
          body: 'It\'s time for ${created.label}',
          scheduledDate: scheduledDate,
        );
        // Do NOT save reminder notification to provider here; let backend or background fetch handle it at the right time
      }
      
      _schedules.add(created);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    final oldIndex = _schedules.indexWhere((s) => s.id == id);
    // Keep reference to cancel previous notification later
    final oldSchedule = oldIndex != -1 ? _schedules[oldIndex] : null;
    
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        _error = 'User not logged in';
        return;
      }

      final updated = await _scheduleService.updateSchedule(id, data);
      
      // Cancel previous scheduled notification
      if (oldSchedule != null) {
        await _notificationService.cancelNotification(oldSchedule.id);
      }

      // If this is a completion update, do NOT show 'Schedule Updated' notification
      if (data['completed'] == true) {
        // Already handled by completeSchedule
        final index = _schedules.indexWhere((s) => s.id == id);
        if (index != -1) {
          _schedules[index] = updated;
          notifyListeners();
        }
        return;
      }

      // Create notification for schedule update
      final notification = NotificationModel(
        title: 'Schedule Updated',
        message: '${updated.label} updated to ${_formatTime12(_combineDateAndTime(updated))}',
        timestamp: DateTime.now(),
        userId: userId,
        type: 'updated',
        category: updated.type ?? updated.label.toLowerCase(),
      );

      // Save notification to notification provider
      try {
        final notificationProvider = serviceLocator<NotificationProvider>();
        await notificationProvider.addNotificationModel(notification);
      } catch (e) {
        print('Failed to save notification: $e');
      }

      // Show OS notification
      await _notificationService.show(
        title: notification.title,
        body: notification.message,
      );

      // Schedule new notification (reminder) only if not completed
      final scheduledDate = _combineDateAndTime(updated);
      if (!updated.checked && scheduledDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          stringId: updated.id,
          title: updated.label, // Use schedule title for reminder
          body: 'It\'s time for ${updated.label}',
          scheduledDate: scheduledDate,
        );
        // Do NOT save reminder notification to provider here; let backend or background fetch handle it at the right time
      }

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
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        _error = 'User not logged in';
        return;
      }

      // Get schedule details before deletion for notification
      final scheduleToDelete = _schedules.firstWhere((s) => s.id == id);
      
      // Cancel any pending notification first
      await _notificationService.cancelNotification(id);

      // Create notification for schedule deletion
      final notification = NotificationModel(
        title: 'Schedule Deleted',
        message: '${scheduleToDelete.label} has been deleted',
        timestamp: DateTime.now(),
        userId: userId,
        type: 'deleted',
        category: scheduleToDelete.type ?? scheduleToDelete.label.toLowerCase(),
      );

      // Save notification to notification provider
      try {
        final notificationProvider = serviceLocator<NotificationProvider>();
        await notificationProvider.addNotificationModel(notification);
      } catch (e) {
        print('Failed to save notification: $e');
      }

      // Show OS notification
      await _notificationService.show(
        title: notification.title,
        body: notification.message,
      );

      await _scheduleService.deleteSchedule(id);
      _schedules.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // New: Mark schedule as completed (tick)
  Future<void> completeSchedule(ScheduleModel schedule) async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return;
      // Mark as completed in backend
      await _scheduleService.updateSchedule(schedule.id, {'completed': true});
      // Cancel any pending reminder notification for this schedule
      await _notificationService.cancelNotification(schedule.id);
      // Create notification for completion
      final notification = NotificationModel(
        title: 'Schedule Completed',
        message: '${schedule.label} completed successfully',
        timestamp: DateTime.now(),
        userId: userId,
        type: 'completed',
        category: schedule.type ?? schedule.label.toLowerCase(),
      );
      try {
        final notificationProvider = serviceLocator<NotificationProvider>();
        await notificationProvider.addNotificationModel(notification);
      } catch (e) {
        print('Failed to save completion notification: $e');
      }
      await _notificationService.show(
        title: notification.title,
        body: notification.message,
      );
    } catch (e) {
      print('Error completing schedule: $e');
    }
  }

  DateTime _combineDateAndTime(ScheduleModel sched) {
    // Attempts to parse "7 AM", "07:30pm", "19:30" etc.
    final timeStr = sched.time.toLowerCase().trim();
    final date = sched.date;

    final regex = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?');
    final match = regex.firstMatch(timeStr);
    if (match == null) return date; // fallback – return date at 00:00

    int hour = int.parse(match.group(1)!);
    int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
    final ampm = match.group(3);

    if (ampm == 'pm' && hour != 12) {
      hour += 12;
    } else if (ampm == 'am' && hour == 12) {
      hour = 0;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _formatTime12(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
