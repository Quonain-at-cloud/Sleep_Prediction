import 'dart:async';
import 'package:workmanager/workmanager.dart';
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
  static const String fetchTaskName = 'notificationFetchTask';

  /// Registers & configures [workmanager]. Must be called **early** in
  /// `main()` *before* [runApp].
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      fetchTaskName,
      fetchTaskName,
      frequency: Duration(minutes: 15),
      initialDelay: Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// The callback dispatcher for workmanager.
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      await _performFetch();
      return Future.value(true);
    });
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
