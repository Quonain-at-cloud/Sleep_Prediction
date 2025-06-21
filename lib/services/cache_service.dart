import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'logger_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  
  late Box _cache;
  final _logger = LoggerService();
  static const String _boxName = 'app_cache';
  
  // Cache configuration
  static const Duration defaultExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // Maximum number of items to cache
  
  CacheService._internal();
  
  // Initialize the cache service
  Future<void> initialize() async {
    await Hive.initFlutter();
    _cache = await Hive.openBox(_boxName);
    await _cleanExpiredCache();
  }
  
  // Get cached data
  Future<T?> get<T>(String key, {T Function(Map<String, dynamic>)? fromJson}) async {
    try {
      final cacheEntry = await _cache.get(key);
      if (cacheEntry == null) return null;
      
      final data = jsonDecode(cacheEntry['data']);
      final expiryTime = DateTime.parse(cacheEntry['expiryTime']);
      
      if (DateTime.now().isAfter(expiryTime)) {
        await delete(key);
        return null;
      }
      
      if (fromJson != null && data is Map<String, dynamic>) {
        return fromJson(data);
      }
      
      return data as T;
    } catch (e) {
      _logger.e('Error retrieving cached data for key: $key', e);
      return null;
    }
  }
  
  // Set cache data
  Future<void> set<T>(
    String key,
    T data, {
    Duration expiration = defaultExpiration,
    Map<String, dynamic> Function(T)? toJson,
  }) async {
    try {
      final expiryTime = DateTime.now().add(expiration);
      final jsonData = toJson != null ? toJson(data) : data;
      
      await _cache.put(key, {
        'data': jsonEncode(jsonData),
        'expiryTime': expiryTime.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await _enforceMaxSize();
    } catch (e) {
      _logger.e('Error caching data for key: $key', e);
    }
  }
  
  // Delete cached data
  Future<void> delete(String key) async {
    try {
      await _cache.delete(key);
    } catch (e) {
      _logger.e('Error deleting cached data for key: $key', e);
    }
  }
  
  // Clear all cached data
  Future<void> clear() async {
    try {
      await _cache.clear();
    } catch (e) {
      _logger.e('Error clearing cache', e);
    }
  }
  
  // Check if key exists in cache
  bool hasKey(String key) {
    return _cache.containsKey(key);
  }
  
  // Get cache entry expiry time
  DateTime? getExpiryTime(String key) {
    try {
      final cacheEntry = _cache.get(key);
      if (cacheEntry == null) return null;
      
      return DateTime.parse(cacheEntry['expiryTime']);
    } catch (e) {
      _logger.e('Error getting expiry time for key: $key', e);
      return null;
    }
  }
  
  // Update expiry time for a cache entry
  Future<void> updateExpiryTime(String key, Duration newExpiration) async {
    try {
      final cacheEntry = _cache.get(key);
      if (cacheEntry == null) return;
      
      cacheEntry['expiryTime'] = DateTime.now()
          .add(newExpiration)
          .toIso8601String();
      await _cache.put(key, cacheEntry);
    } catch (e) {
      _logger.e('Error updating expiry time for key: $key', e);
    }
  }
  
  // Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    try {
      final now = DateTime.now();
      final keys = _cache.keys.toList();
      
      for (final key in keys) {
        final cacheEntry = _cache.get(key);
        if (cacheEntry == null) continue;
        
        final expiryTime = DateTime.parse(cacheEntry['expiryTime']);
        if (now.isAfter(expiryTime)) {
          await delete(key.toString());
        }
      }
    } catch (e) {
      _logger.e('Error cleaning expired cache', e);
    }
  }
  
  // Enforce maximum cache size
  Future<void> _enforceMaxSize() async {
    try {
      if (_cache.length <= maxCacheSize) return;
      
      final entries = _cache.keys
          .map((key) {
            final entry = _cache.get(key);
            return MapEntry(
              key,
              DateTime.parse(entry['timestamp']),
            );
          })
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      // Remove oldest entries until we're under the limit
      while (_cache.length > maxCacheSize) {
        await delete(entries.removeAt(0).key.toString());
      }
    } catch (e) {
      _logger.e('Error enforcing max cache size', e);
    }
  }
  
  // Get all cache keys
  List<String> getAllKeys() {
    return _cache.keys.map((key) => key.toString()).toList();
  }
  
  // Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'totalEntries': _cache.length,
      'keys': getAllKeys(),
      'maxSize': maxCacheSize,
    };
  }
}
