import '../config/api_config.dart';
import 'service_locator.dart';
import 'error_service.dart';
import 'connectivity_service.dart';
import 'cache_service.dart';
import 'logger_service.dart';

abstract class BaseService {
  final LoggerService _logger = LoggerService();
  final ErrorService _errorService = serviceLocator<ErrorService>();
  final ConnectivityService _connectivityService = serviceLocator<ConnectivityService>();
  final CacheService _cacheService = serviceLocator<CacheService>();
  
  // Protected getters for child classes
  LoggerService get logger => _logger;
  ErrorService get errorService => _errorService;
  ConnectivityService get connectivityService => _connectivityService;
  CacheService get cacheService => _cacheService;
  
  // Cache configuration
  Duration get defaultCacheExpiration => const Duration(hours: 24);
  bool get useCache => true;
  
  // Generate cache key for a given endpoint and parameters
  String generateCacheKey(String endpoint, [Map<String, dynamic>? params]) {
    if (params == null || params.isEmpty) {
      return endpoint;
    }
    
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    return '$endpoint?${_serializeParams(sortedParams)}';
  }
  
  // Serialize parameters for cache key
  String _serializeParams(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${e.key}=${e.value.toString()}')
        .join('&');
  }
  
  // Execute an operation with error handling, caching, and retry logic
  Future<T> executeOperation<T>({
    required Future<T> Function() operation,
    String? cacheKey,
    Duration? cacheExpiration,
    bool forceFetch = false,
    T Function(Map<String, dynamic>)? fromJson,
    Map<String, dynamic> Function(T)? toJson,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    try {
      // Check cache first if enabled and not force fetching
      if (useCache && !forceFetch && cacheKey != null) {
        final cachedData = await _cacheService.get<T>(
          cacheKey,
          fromJson: fromJson,
        );
        
        if (cachedData != null) {
          _logger.i('Retrieved data from cache: $cacheKey');
          return cachedData;
        }
      }
      
      // Execute operation with retry logic
      final result = await _connectivityService.withConnectivity(
        operation: operation,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
        shouldRetry: (e) => !(e is ApiException && e.statusCode == 401),
      );
      
      // Cache the result if caching is enabled
      if (useCache && cacheKey != null) {
        await _cacheService.set<T>(
          cacheKey,
          result,
          expiration: cacheExpiration ?? defaultCacheExpiration,
          toJson: toJson,
        );
      }
      
      return result;
    } catch (error) {
      _logger.e('Error executing operation', error);
      
      if (error is ApiException) {
        rethrow;
      }
      
      // Create a friendly error message
      final errorMessage = error.toString();
      throw ApiException(
        errorMessage,
        statusCode: error is ApiException ? error.statusCode : null,
      );
    }
  }
  
  // Clear cache for specific endpoint
  Future<void> clearCache(String endpoint) async {
    await _cacheService.delete(endpoint);
  }
  
  // Clear all cache
  Future<void> clearAllCache() async {
    await _cacheService.clear();
  }
  
  // Check if data is cached
  bool isCached(String cacheKey) {
    return _cacheService.hasKey(cacheKey);
  }
  
  // Get cache expiry time
  DateTime? getCacheExpiry(String cacheKey) {
    return _cacheService.getExpiryTime(cacheKey);
  }
  
  // Update cache expiry
  Future<void> updateCacheExpiry(String cacheKey, Duration newExpiration) async {
    await _cacheService.updateExpiryTime(cacheKey, newExpiration);
  }
  
  // Log debug information
  void logDebug(String message) {
    _logger.d(message);
  }
  
  // Log information
  void logInfo(String message) {
    _logger.i(message);
  }
  
  // Log warning
  void logWarning(String message) {
    _logger.w(message);
  }
  
  // Log error
  void logError(String message, [dynamic error]) {
    _logger.e(message, error);
  }
}
