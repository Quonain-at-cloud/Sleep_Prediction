import 'package:logger/logger.dart';

/// A logging service that wraps the Logger package
class LoggerService {
  final Logger _logger = Logger();

  // Singleton instance
  static final LoggerService _instance = LoggerService._internal();
  
  factory LoggerService() {
    return _instance;
  }
  
  LoggerService._internal();
  
  /// Log a debug message
  void d(String message) {
    _logger.d(message);
  }
  
  /// Log an info message
  void i(String message) {
    _logger.i(message);
  }
  
  /// Log a warning message
  void w(String message) {
    _logger.w(message);
  }
  
  /// Log an error message with optional error object and stack trace
  void e(String message, [dynamic error]) {
    if (error != null) {
      _logger.e('$message: ${error.toString()}');
    } else {
      _logger.e(message);
    }
  }
  
  /// Log a verbose message
  void v(String message) {
    _logger.v(message);
  }
  
  /// Log a WTF message
  void wtf(String message) {
    _logger.wtf(message);
  }
}
