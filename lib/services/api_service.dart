import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../exceptions/api_exceptions.dart';
import 'logger_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiService {
  final Dio _dio;
  final LoggerService _logger;
  final Future<SharedPreferences> _prefs;

  ApiService({
    Dio? dio,
    LoggerService? logger,
    Future<SharedPreferences>? prefs,
  })
      : _dio = dio ?? Dio(),
        _logger = logger ?? LoggerService(),
        _prefs = prefs ?? SharedPreferences.getInstance(); // Removed direct call to _initializeDio

  // Asynchronous initialization method
  Future<void> init() async {
    await _initializeDioAndHeaders();
  }
  
  Future<void> _initializeDioAndHeaders() async {
  // Ensure SharedPreferences is ready before trying to update headers
  // This line is crucial: it ensures that SharedPreferences.getInstance() has completed.
  // The _prefs field itself is a Future<SharedPreferences>, awaiting it here ensures it's resolved.
  await _prefs;
  _logger.i('SharedPreferences instance awaited in ApiService._initializeDioAndHeaders.');

  _logger.i('[ApiService_LOG_1] Attempting to set Dio options...');
  // Update options on the existing _dio instance
  _dio.options = BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
  _logger.i('[ApiService_LOG_2] Dio options set.');

  _logger.i('[ApiService_LOG_3] Attempting to clear interceptors...');
  // Clear existing interceptors to avoid duplicates
  _dio.interceptors.clear();
  _logger.i('[ApiService_LOG_4] Interceptors cleared.');
  
  _logger.i('[ApiService_LOG_5] Attempting to add QueuedInterceptorsWrapper...');
  // Add retry interceptor
  _dio.interceptors.add(QueuedInterceptorsWrapper(
    onError: (error, handler) async {
      _logger.w('[ApiService Retry] onError triggered for ${error.requestOptions.path}, type: ${error.type}, message: ${error.message}');
      if (error.type == DioErrorType.connectionTimeout ||
          error.type == DioErrorType.connectionError) {
        _logger.i('[ApiService Retry] Error is connectionTimeout or connectionError for ${error.requestOptions.path}.');
        int currentRetryCount = error.requestOptions.extra['retryCount'] ?? 0;
        if (currentRetryCount < 3) {
          final options = error.requestOptions;
          options.extra['retryCount'] = currentRetryCount + 1;
          _logger.i('[ApiService Retry] Retrying request to ${options.path}, attempt #${options.extra['retryCount']}.');
          try {
            final response = await _dio.fetch(options);
            _logger.i('[ApiService Retry] Retry successful for ${options.path}, status: ${response.statusCode}.');
            return handler.resolve(response);
          } catch (e) {
            _logger.e('[ApiService Retry] Retry attempt #${options.extra['retryCount']} for ${options.path} FAILED. Error: $e');
            // Propagate the error from the retry attempt if it's a DioError, otherwise the original error
            if (e is DioError) {
              return handler.reject(e);
            } else {
              // It's often better to reject with the original error if the retry itself throws an unexpected (non-Dio) error.
              return handler.reject(error); 
            }
          }
        } else {
          _logger.w('[ApiService Retry] Max retries (${currentRetryCount}) reached for ${error.requestOptions.path}. Not retrying further.');
        }
      } else {
        _logger.i('[ApiService Retry] Error for ${error.requestOptions.path} is not a retryable type (${error.type}).');
      }
      _logger.i('[ApiService Retry] Passing error to next handler for ${error.requestOptions.path}.');
      return handler.reject(error);
    },
  ));
  _logger.i('[ApiService_LOG_6] QueuedInterceptorsWrapper added.');
  
  // Log the actual base URL being used
  _logger.i('[ApiService_LOG_7] Initializing Dio with base URL: ${ApiConfig.baseUrl}');

  _logger.i('[ApiService_LOG_8] Attempting to add general InterceptorsWrapper...');
  _dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.i('Request: ${options.method} ${options.uri}');

        final publicPaths = [
          ApiConfig.endpoints.auth.login,       // e.g., '/users/login'
          ApiConfig.endpoints.auth.register,    // e.g., '/users/register'
          ApiConfig.endpoints.auth.refreshToken, // e.g., '/auth/refresh-token'
          // Add other public paths if any, like forgot-password, verify-otp, etc.
          // ApiConfig.endpoints.auth.forgotPassword,
          // ApiConfig.endpoints.auth.resetPassword,
          // ApiConfig.endpoints.auth.verifyOtp,
        ];

        final requestPath = options.path; // Get the path part of the URI

        if (!options.headers.containsKey('Authorization')) {
          bool isPublicPath = publicPaths.any((publicPath) => requestPath.endsWith(publicPath));
          if (!isPublicPath) {
            _logger.w('Authorization header IS MISSING for protected route: ${options.uri}');
          } else {
            _logger.i('Authorization header is appropriately missing for public route: ${options.uri}');
          }
        } else {
          _logger.i('Authorization header IS PRESENT in request to ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i('Response: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        _logger.e('Error: ${error.message}', error);
        if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
          _logger.e('Authorization error details: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ),
  );
  _logger.i('[ApiService_LOG_9] General InterceptorsWrapper added.');

  _logger.i('[ApiService_LOG_10] Attempting to call updateHeaders()...');
  // Perform an initial header update after Dio is configured
  await updateHeaders();
  _logger.i('[ApiService_LOG_11] updateHeaders() completed.');
  _logger.i('[ApiService_LOG_12] ApiService fully initialized and initial headers updated.');
}

  void _initializeDio() { // This is the old method, content moved to _initializeDioAndHeaders
    // Update options on the existing _dio instance
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Clear existing interceptors to avoid duplicates
    _dio.interceptors.clear();
    
    // Add retry interceptor
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioErrorType.connectionTimeout ||
            error.type == DioErrorType.connectionError) {
          // Retry the request up to 3 times
          if ((error.requestOptions.extra['retryCount'] ?? 0) < 3) {
            final options = error.requestOptions;
            options.extra['retryCount'] = (options.extra['retryCount'] ?? 0) + 1;
            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.reject(error);
            }
          }
        }
        return handler.reject(error);
      },
    ));
    
    // Log the actual base URL being used
    _logger.i('Initializing Dio with base URL: ${ApiConfig.baseUrl}');

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Logging moved to _initializeDioAndHeaders to include auth header status
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i('Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          // Logging moved to _initializeDioAndHeaders to include auth error details
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> getToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString('auth_token');
  }

  Future<void> clearToken() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove('auth_token');
    _logger.i('Token removed from SharedPreferences.');
    await updateHeaders(); // Ensure headers are updated immediately after clearing token
  }

  Future<void> setToken(String token) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString('auth_token', token);
    await updateHeaders();
  }

  Future<void> removeToken() async {
    final prefs = await _prefs;
    await prefs.remove('auth_token');
    await updateHeaders();
  }

  Future<void> updateHeaders() async {
    final token = await getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    await _checkConnectivity();
    await updateHeaders();
    try {
      // Ensure we're using the current base URL
      _dio.options.baseUrl = ApiConfig.baseUrl;
      final response = await _dio.get(endpoint, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      throw _handleError(e as DioError);
    }
  }

  Future<dynamic> post(
    String endpoint, 
    Map<String, dynamic> data, 
    {
      Duration? timeout,
      bool handleErrors = true,
    }) async {
    await _checkConnectivity();
    await updateHeaders();
    try {
      // Ensure we're using the current base URL
      _dio.options.baseUrl = ApiConfig.baseUrl;
      
      // Set timeout if provided
      if (timeout != null) {
        _dio.options.connectTimeout = timeout;
        _dio.options.receiveTimeout = timeout;
        _dio.options.sendTimeout = timeout;
      }
      
      _logger.i('Making POST request to: ${_dio.options.baseUrl}$endpoint');
      _logger.i('Request data: $data');
      
      final response = await _dio.post(endpoint, data: data);
      
      _logger.i('Response received: ${response.statusCode}');
      _logger.i('Response data: ${response.data}');
      
      return response.data;
    } on DioError catch (e) {
      _logger.e('DioError in POST request:', e);
      _logger.e('Response data:', e.response?.data);
      _logger.e('Status code: ${e.response?.statusCode}');
      
      if (!handleErrors) {
        // If handleErrors is false, rethrow the original DioError
        rethrow;
      }
      
      throw _handleError(e);
    } catch (e) {
      _logger.e('Unexpected error in POST request:', e);
      if (!handleErrors) {
        rethrow;
      }
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    await _checkConnectivity();
    await updateHeaders();
    try {
      // Ensure we're using the current base URL
      _dio.options.baseUrl = ApiConfig.baseUrl;
      final response = await _dio.patch(endpoint, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e as DioError);
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    await _checkConnectivity();
    await updateHeaders();
    try {
      // Ensure we're using the current base URL
      _dio.options.baseUrl = ApiConfig.baseUrl;
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e as DioError);
    }
  }

  Future<void> delete(String endpoint) async {
    await _checkConnectivity();
    await updateHeaders();
    try {
      // Ensure we're using the current base URL
      _dio.options.baseUrl = ApiConfig.baseUrl;
      await _dio.delete(endpoint);
    } catch (e) {
      throw _handleError(e as DioError);
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await (Connectivity()).checkConnectivity();
    if (connectivityResult == (ConnectivityResult.none)) {
      throw NetworkException('No internet connection');
    }
  }

  Exception _handleError(DioError e) {
    _logger.e('API Error:', e);
    _logger.e('Response data:', e.response?.data);
    _logger.e('Request data:', e.requestOptions.data);

    switch (e.type) {
      case DioErrorType.connectionTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.receiveTimeout:
        return TimeoutException('Request timed out. Please check your internet connection and try again.');
      case DioErrorType.connectionError:
        return NetworkException('No internet connection. Please check your network settings.');
      case DioErrorType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        switch (statusCode) {
          case 400:
            if (responseData is Map<String, dynamic>) {
              final error = responseData['error'];
              final details = responseData['details'];
              final message = responseData['message'];
              
              if (error == 'Email already registered') {
                return ValidationException('This email is already registered');
              } else if (error == 'Validation error' && details is List) {
                final errors = details.map((e) => '${e['field']}: ${e['message']}').join('\n');
                return ValidationException(errors);
              } else if (message != null) {
                return ValidationException(message.toString());
              }
            }
            return ValidationException('Invalid request data');
            
          case 401:
            return AuthException('Authentication failed. Please log in again.');
            
          case 403:
            return AuthException('You do not have permission to perform this action.');
            
          case 404:
            return NotFoundException('The requested resource was not found.');
            
          case 409:
            return ConflictException('This operation conflicts with an existing record.');
            
          case 422:
            if (responseData is Map<String, dynamic>) {
              final message = responseData['message'] ?? 'Validation failed';
              return ValidationException(message.toString());
            }
            return ValidationException('Invalid input data');
            
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException('A server error occurred. Please try again later.');
            
          default:
            return ApiException('An error occurred: ${e.message}');
        }
        
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled');
        
      default:
        return ApiException('An unexpected error occurred: ${e.message}');
    }
  }  
}
