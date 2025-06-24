import 'package:flutter/material.dart';

/// A simple data model representing a schedule entry
class ScheduleModel {
  final String id;
  final String userId;
  final DateTime date; // Date component (year-month-day)
  final String time; // Human-readable time string e.g. "10:00pm"
  final String label; // Display label e.g. "Sleep Time"
  final String? type; // Optional logical type (sleep, meal, reminder)
  final bool checked;

  ScheduleModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.time,
    required this.label,
    this.type,
    this.checked = false,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date'] ?? json['startTime']),
      time: json['time'] ?? _formatTime(json['startTime']),
      label: json['label'] ?? json['title'] ?? '',
      type: json['type'],
      checked: json['completed'] ?? json['checked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    // Combine date & time into a single DateTime for the API
    final DateTime _startDateTime = _combineDateAndTime();
    return {
      'userId': userId,
      'title': label,
      'startTime': _startDateTime.toIso8601String(),
      'endTime': _startDateTime.toIso8601String(),
      if (type != null) 'type': type,
      'completed': checked,
    };
  }

  // Merge the separate [date] (calendar day) and [time] (human string)
  // into a single DateTime (local) so that we can send ISO strings the
  // backend validator accepts.
  DateTime _combineDateAndTime() {
    final timeStr = time.toLowerCase().trim();
    final regex = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?');
    final match = regex.firstMatch(timeStr);
    int hour = 0;
    int minute = 0;
    if (match != null) {
      hour = int.parse(match.group(1)!);
      minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final ampm = match.group(3);
      if (ampm == 'pm' && hour != 12) {
        hour += 12;
      } else if (ampm == 'am' && hour == 12) {
        hour = 0;
      }
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// UI background colour depending on completion state
  Color get uiColor => checked
      ? const Color(0xFFF8C9E9) // pink if completed
      : const Color(0xFFFFF9C4); // light yellow if pending
  

  /// Helper to get icon based on label/type
  // Convert ISO string (or Date) to human-readable time string
  static String _formatTime(dynamic iso) {
    try {
      final dt = iso is String ? DateTime.parse(iso) : (iso as DateTime);
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final suffix = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute$suffix'.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  IconData get uiIcon {
    switch (type ?? label.toLowerCase()) {
      case 'wake up':
      case 'wake_up':
        return Icons.wb_twilight; // fixed spelling in Icons
      case 'breakfast':
      case 'break-fast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
      case 'diner':
        return Icons.restaurant;
      case 'sleep':
      case 'sleep time':
        return Icons.nightlight_round;
      default:
        return Icons.schedule;
    }
  }
}
