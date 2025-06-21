import 'package:dio/dio.dart';
import 'logger_service.dart';

class ErrorService {
  final LoggerService _logger = LoggerService();
  
  // Handle API errors
  String handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else {
      _logger.e('Unexpected error', error);
      return 'An unexpected error occurred';
    }
  }
  
  // Handle Dio specific errors
  String _handleDioError(DioException error) {
    _logger.e('DioError: ${error.message}', error);
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
        
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
        
      case DioExceptionType.cancel:
        return 'Request was cancelled';
        
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
        
      default:
        return 'An error occurred while communicating with the server';
    }
  }
  
  // Handle HTTP response errors
  String _handleBadResponse(Response? response) {
    if (response == null) {
      return 'No response received from server';
    }
    
    switch (response.statusCode) {
      case 400:
        return _extractErrorMessage(response.data) ?? 'Invalid request';
      case 401:
        return 'Unauthorized. Please log in again';
      case 403:
        return 'You do not have permission to perform this action';
      case 404:
        return 'The requested resource was not found';
      case 409:
        return _extractErrorMessage(response.data) ?? 'A conflict occurred';
      case 422:
        return _extractErrorMessage(response.data) ?? 'Invalid data provided';
      case 500:
        return 'Server error. Please try again later';
      default:
        return 'An error occurred: ${response.statusCode}';
    }
  }
  
  // Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is Map) {
        return data['error'] ?? data['message'] ?? data['detail'];
      } else if (data is String) {
        return data;
      }
    } catch (e) {
      _logger.e('Error extracting error message', e);
    }
    
    return null;
  }
  
  // Format validation errors
  Map<String, String> formatValidationErrors(Map<String, dynamic> errors) {
    final formattedErrors = <String, String>{};
    
    errors.forEach((key, value) {
      if (value is List) {
        formattedErrors[key] = value.join('. ');
      } else if (value is String) {
        formattedErrors[key] = value;
      }
    });
    
    return formattedErrors;
  }
  
  // Log errors for analytics
  void logError(String message, dynamic error) {
    _logger.e(message, error);
    // Here you could add additional error reporting services like Sentry, Firebase Crashlytics, etc.
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

// Custom exception for validation errors
class ValidationException implements Exception {
  final Map<String, String> errors;

  ValidationException(this.errors);

  @override
  String toString() => 'Validation errors: ${errors.values.join(', ')}';
}
