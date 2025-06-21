import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logger_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  
  final _connectivity = Connectivity();
  final _logger = LoggerService();
  final _connectivityController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  Timer? _retryTimer;
  
  // Stream of connectivity status changes
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  
  // Current connectivity status
  bool get isConnected => _isConnected;
  
  ConnectivityService._internal() {
    _initConnectivity();
    _setupConnectivityStream();
  }
  
  // Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _logger.e('Error checking connectivity', e);
      _isConnected = false;
    }
  }
  
  // Setup stream for connectivity changes
  void _setupConnectivityStream() {
    _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _updateConnectionStatus(result);
      },
      onError: (error) {
        _logger.e('Error monitoring connectivity', error);
        _isConnected = false;
        _connectivityController.add(false);
      },
    );
  }
  
  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    _connectivityController.add(_isConnected);
    
    if (_isConnected) {
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }
  
  // Execute a function with automatic retries on network failure
  Future<T> withConnectivity<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (true) {
      try {
        if (!_isConnected) {
          _logger.w('No internet connection. Waiting for connectivity...');
          await waitForConnectivity();
        }
        
        return await operation();
      } catch (e) {
        attempts++;
        
        final shouldRetryOperation = shouldRetry?.call(e as Exception) ?? true;
        if (attempts >= maxRetries || !shouldRetryOperation) {
          rethrow;
        }
        
        _logger.i('Operation failed, retrying in ${retryDelay.inSeconds} seconds (Attempt $attempts/$maxRetries)');
        await Future.delayed(retryDelay * attempts);
      }
    }
  }
  
  // Wait for connectivity to be restored
  Future<void> waitForConnectivity() async {
    if (_isConnected) return;
    
    final completer = Completer<void>();
    
    StreamSubscription? subscription;
    subscription = onConnectivityChanged.listen((connected) {
      if (connected) {
        subscription?.cancel();
        completer.complete();
      }
    });
    
    return completer.future;
  }
  
  // Start periodic connectivity checks
  void startPeriodicCheck({Duration interval = const Duration(seconds: 30)}) {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(interval, (_) => _checkConnectivity());
  }
  
  // Stop periodic connectivity checks
  void stopPeriodicCheck() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
  
  // Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _logger.e('Error checking connectivity', e);
    }
  }
  
  // Dispose resources
  void dispose() {
    _connectivityController.close();
    _retryTimer?.cancel();
  }
}
