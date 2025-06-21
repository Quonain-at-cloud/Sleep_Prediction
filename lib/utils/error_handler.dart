import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/logger_service.dart';

/// Standardized error handling for API calls
class ErrorHandler {
  static final LoggerService _logger = LoggerService();
  
  /// Process an error and return a user-friendly message
  static String handleError(dynamic error, {String fallbackMessage = 'Something went wrong'}) {
    _logger.e('Error caught by handler', error);
    
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    } else if (error is FormatException) {
      return 'Invalid data format received from server.';
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    
    return fallbackMessage;
  }
  
  /// Handle Dio specific errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
        
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
        
      case DioExceptionType.cancel:
        return 'Request was cancelled';
        
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network settings.';
        
      case DioExceptionType.badCertificate:
        return 'Invalid server certificate. Please contact support.';
        
      case DioExceptionType.unknown:
      default:
        if (error.message?.contains('SocketException') == true) {
          return 'No internet connection. Please check your network settings.';
        }
        return 'An unexpected error occurred. Please try again.';
    }
  }
  
  /// Process HTTP response errors
  static String _handleResponseError(Response? response) {
    if (response == null) {
      return 'No response received from server.';
    }
    
    final statusCode = response.statusCode;
    
    // Extract error message from response if available
    String? serverMessage;
    if (response.data is Map) {
      serverMessage = response.data['error'] ?? response.data['message'];
    }
    
    // Use server message if available, otherwise use standard HTTP status messages
    if (serverMessage != null) {
      return serverMessage;
    }
    
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication failed. Please login again.';
      case 403:
        return 'You don\'t have permission to access this resource.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Error ${statusCode}. Please try again.';
    }
  }
  
  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  /// Handle API error with a callback
  static Future<T?> handleApiCall<T>({
    required Future<T> Function() apiCall,
    required Function(String errorMessage) onError,
    String fallbackErrorMessage = 'Operation failed',
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      final errorMessage = handleError(e, fallbackMessage: fallbackErrorMessage);
      onError(errorMessage);
      return null;
    }
  }
  
  /// Show a dialog with error details
  static void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }
  
  /// Handle token expiration
  static bool isTokenExpiredError(dynamic error) {
    if (error is DioException && 
        error.type == DioExceptionType.badResponse && 
        error.response?.statusCode == 401) {
      final data = error.response?.data;
      if (data is Map && 
          (data['message']?.toString().toLowerCase().contains('expired') == true || 
           data['error']?.toString().toLowerCase().contains('expired') == true)) {
        return true;
      }
    }
    return false;
  }
}
