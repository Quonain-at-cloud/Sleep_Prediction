import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/notification_model.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import 'package:hive/hive.dart';

/// Handles periodic background-fetch (15 min) when the Flutter app is *terminated*.
///
/// It queries the backend for notifications created since the last fetch, stores
/// them to Hive and triggers OS-level local notifications so the user can see
/// them like real push-notifications – no Firebase required.
class NotificationBackgroundFetcher {
  static const String _prefsLastFetchKey = 'last_notification_fetch';

  /// Registers & configures [background_fetch]. Must be called **early** in
  /// `main()` *before* [runApp].
  static Future<void> initialize() async {
    // background_fetch is not supported on Flutter Web.
    if (kIsWeb) return;
    // iOS/Android config
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15, // minutes
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiredNetworkType: NetworkType.ANY,
      ),
      _onFetch,
      _onTimeout,
    );
  }

  /// Background callback when app is *running* (foreground / background).
  static Future<void> _onFetch(String taskId) async {
    await _performFetch();
    BackgroundFetch.finish(taskId);
  }

  /// Background callback when fetch times out (very rare).
  static void _onTimeout(String taskId) {
    LoggerService().w('BackgroundFetch timeout: $taskId');
    BackgroundFetch.finish(taskId);
  }

  /// Android *headless* entry-point when the app is terminated.
  /// On Android (when the app is *terminated*) this callback is invoked.
  /// On other platforms (including Web) the function exits immediately.
  static Future<void> backgroundFetchHeadlessTask(dynamic task) async {
    if (kIsWeb) return;
    if (task.timeout) {
      BackgroundFetch.finish(task.taskId);
      return;
    }
    await _performFetch();
    BackgroundFetch.finish(task.taskId);
  }

  /// Core logic: fetch new notifications from backend, store and show.
  static Future<void> _performFetch() async {
    final logger = LoggerService();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        logger.w('No auth token – skipping background fetch');
        return;
      }

      final lastIso = prefs.getString(_prefsLastFetchKey);
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final url = '${ApiConfig.baseUrl}/notifications/user/latest'
          '${lastIso != null ? '?since=$lastIso' : ''}';

      final resp = await dio.get(url);
      if (resp.statusCode == 200 && resp.data is Map) {
        final List list = resp.data['notifications'] ?? [];
        if (list.isNotEmpty) {
          logger.i('Fetched ${list.length} new notifications in bg');
          await NotificationService().init();

          final boxName = 'notifications_box_${prefs.getString('user_id') ?? 'unknown'}';
          final box = await Hive.openBox<NotificationModel>(boxName);

          for (final item in list) {
            final notif = NotificationModel.fromJson(Map<String, dynamic>.from(item));
            await box.add(notif);
            await NotificationService()
                .show(title: notif.title, body: notif.message);
          }
        }
      }
      // Save current timestamp
      prefs.setString(_prefsLastFetchKey, DateTime.now().toIso8601String());
    } catch (e) {
      logger.e('Background fetch failed', e);
    }
  }
}
