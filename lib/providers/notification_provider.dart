import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/notification_model.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final SocketService _socketService;
  final AuthService _authService;
  final LoggerService _logger = LoggerService();
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  
  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  NotificationProvider({
    SocketService? socketService,
    AuthService? authService,
  }) : _socketService = socketService ?? SocketService(),
       _authService = authService ?? AuthService() {
    // Don't auto-initialize, wait for user login
    _logger.i('NotificationProvider: Created, waiting for user login');
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      _logger.i('NotificationProvider: Starting initialization');
      await _loadCurrentUser();
      
      if (_currentUserId != null) {
        await _openHiveBox();
        await _listenToSocket();
        _isInitialized = true;
        _logger.i('NotificationProvider: Initialization complete. User ID: $_currentUserId');
      } else {
        _logger.w('NotificationProvider: No user ID available, skipping initialization');
      }
    } catch (e) {
      _logger.e('NotificationProvider: Initialization failed', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUserModel();
      _currentUserId = user?.id;
      _logger.i('NotificationProvider: Loaded user ID: $_currentUserId');
    } catch (e) {
      _logger.e('NotificationProvider: Failed to load current user', e);
      _currentUserId = null;
    }
  }

  Future<void> _openHiveBox() async {
    if (_currentUserId == null) {
      _logger.w('NotificationProvider: No user ID available, skipping Hive box opening');
      return;
    }
    
    try {
      final boxName = 'notifications_box_$_currentUserId';
      final box = await Hive.openBox<NotificationModel>(boxName);
      
      // Only load notifications for the current user
      _notifications = box.values
          .where((notification) => notification.userId == _currentUserId)
          .toList()
          .reversed
          .toList();
      
      _logger.i('NotificationProvider: Loaded ${_notifications.length} notifications for user $_currentUserId');
      notifyListeners();
    } catch (e) {
      _logger.e('NotificationProvider: Failed to open Hive box', e);
    }
  }

  Future<void> _listenToSocket() async {
    try {
      final wsUrl = ApiConfig.baseUrl.replaceAll('/api', '');
      _logger.i('NotificationProvider: Initializing socket connection to $wsUrl');
      
      await _socketService.init(wsUrl);
      
      // Listen for notifications from backend
      _socketService.on('new_notification', _handleIncomingNotification);
      
      _logger.i('NotificationProvider: Socket listener set up successfully');
    } catch (e) {
      _logger.e('NotificationProvider: Failed to set up socket listener', e);
    }
  }

  void _handleIncomingNotification(dynamic data) {
    _logger.i('NotificationProvider: Received notification: $data');
    if (data is Map) {
      try {
        final notif = NotificationModel.fromJson(Map<String, dynamic>.from(data));
        if (notif.userId == _currentUserId || notif.userId.isEmpty) {
          _addNotification(notif);
        }
      } catch (e) {
        _logger.e('NotificationProvider: Failed to parse notification data', e);
      }
    }
  }

  Future<void> _addNotification(NotificationModel notification) async {
    if (_currentUserId == null) {
      _logger.w('NotificationProvider: Cannot add notification - no user ID');
      return;
    }
    
    try {
      final boxName = 'notifications_box_$_currentUserId';
      final box = await Hive.openBox<NotificationModel>(boxName);

      // Improved duplicate check: title + message + type + category + timestamp ±1min
      final alreadyExists = _notifications.any((n) =>
        n.title == notification.title &&
        n.message == notification.message &&
        n.type == notification.type &&
        n.category == notification.category &&
        (n.timestamp.difference(notification.timestamp).abs().inMinutes < 1)
      );
      
      if (alreadyExists) {
        _logger.i('NotificationProvider: Duplicate notification skipped: ${notification.title}');
        return;
      }

      await box.add(notification);
      _notifications.insert(0, notification);
      // Always keep sorted by timestamp descending
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _logger.i('NotificationProvider: Added notification: ${notification.title}');
      
      // Trigger OS level local notification
      try {
        await _notificationService.show(title: notification.title, body: notification.message);
      } catch (e) {
        _logger.e('NotificationProvider: Failed to show OS notification', e);
      }
      
      notifyListeners();
    } catch (e) {
      _logger.e('NotificationProvider: Failed to add notification', e);
    }
  }

  // Method to manually add a notification (for testing)
  Future<void> addTestNotification(String title, String message) async {
    final notification = NotificationModel(
      title: title,
      message: message,
      timestamp: DateTime.now(),
      userId: _currentUserId ?? '',
    );
    await _addNotification(notification);
  }

  // Method to add a notification model directly
  Future<void> addNotificationModel(NotificationModel notification) async {
    await _addNotification(notification);
  }

  // Method to clear notifications when user logs out
  Future<void> clearNotifications() async {
    if (_currentUserId == null) return;
    
    try {
      final boxName = 'notifications_box_$_currentUserId';
      final box = await Hive.openBox<NotificationModel>(boxName);
      await box.clear();
      _notifications.clear();
      _logger.i('NotificationProvider: Cleared notifications for user $_currentUserId');
      notifyListeners();
    } catch (e) {
      _logger.e('NotificationProvider: Failed to clear notifications', e);
    }
  }

  // Method to refresh user context (call this when user logs in/out)
  Future<void> refreshUserContext() async {
    _logger.i('NotificationProvider: Refreshing user context');
    
    // Clear current state
    _notifications.clear();
    _isInitialized = false;
    notifyListeners();
    
    // Dispose current socket connection
    try {
      _socketService.dispose();
    } catch (e) {
      _logger.e('NotificationProvider: Error disposing socket', e);
    }
    
    // Re-initialize with new user context
    await initialize();
  }

  @override
  void dispose() {
    try {
      _socketService.dispose();
    } catch (e) {
      _logger.e('NotificationProvider: Error disposing socket service', e);
    }
    super.dispose();
  }
}
