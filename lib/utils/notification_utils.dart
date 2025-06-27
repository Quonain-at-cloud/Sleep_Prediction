import 'package:flutter/material.dart';

IconData notificationIcon(String? categoryOrLabel) {
  final key = (categoryOrLabel ?? '').toLowerCase();
  switch (key) {
    case 'wake up':
    case 'wake_up':
      return Icons.wb_twilight;
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
    case 'sleepstart':
      return Icons.nightlight_round;
    case 'wakeup':
      return Icons.alarm;
    case 'exercise':
      return Icons.fitness_center;
    default:
      return Icons.notifications;
  }
}

Color notificationBgColor(String? type, String? category) {
  switch (type) {
    case 'created':
      return const Color(0xFFD0F2FF); // Blue
    case 'updated':
      return const Color(0xFFFFF4D0); // Orange/Yellow
    case 'deleted':
      return const Color(0xFFFFD6D6); // Red
    case 'completed':
      return const Color(0xFFD6FFD6); // Green
    case 'missed':
      return const Color(0xFFF3E6FF); // Purple/Grey
    case 'reminder':
      return const Color(0xFFFFF9C4); // Light Yellow
    default:
      return Colors.grey.shade200;
  }
} 