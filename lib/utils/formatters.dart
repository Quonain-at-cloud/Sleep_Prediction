import 'package:intl/intl.dart';

class Formatters {
  // Date formatters
  static final DateFormat dateFormat = DateFormat('MMMM d, yyyy');
  static final DateFormat shortDateFormat = DateFormat('MM/dd/yyyy');
  static final DateFormat timeFormat = DateFormat('h:mm a');
  static final DateFormat dateTimeFormat = DateFormat('MMM d, yyyy - h:mm a');
  static final DateFormat isoDateFormat = DateFormat('yyyy-MM-dd');
  
  // Format a DateTime to a readable date string
  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }
  
  // Format a DateTime to a short date string
  static String formatShortDate(DateTime date) {
    return shortDateFormat.format(date);
  }
  
  // Format a DateTime to a time string
  static String formatTime(DateTime time) {
    return timeFormat.format(time);
  }
  
  // Format a DateTime to a date and time string
  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormat.format(dateTime);
  }
  
  // Format minutes to hours and minutes
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }
  
  // Format a sleep quality score (0-10) to a description
  static String formatSleepQuality(double score) {
    if (score >= 9) {
      return 'Excellent';
    } else if (score >= 7) {
      return 'Good';
    } else if (score >= 5) {
      return 'Average';
    } else if (score >= 3) {
      return 'Poor';
    } else {
      return 'Very Poor';
    }
  }
  
  // Format a prediction score (0-1) to a percentage
  static String formatPredictionScore(double score) {
    return '${(score * 100).round()}%';
  }
  
  // Format a prediction score (0-1) to a risk level
  static String formatPredictionRisk(double score) {
    if (score >= 0.8) {
      return 'Very High';
    } else if (score >= 0.6) {
      return 'High';
    } else if (score >= 0.4) {
      return 'Moderate';
    } else if (score >= 0.2) {
      return 'Low';
    } else {
      return 'Very Low';
    }
  }
  
  // Format a temperature from Celsius to a readable string
  static String formatTemperature(double celsius) {
    return '${celsius.round()}°C (${(celsius * 9 / 5 + 32).round()}°F)';
  }
} 