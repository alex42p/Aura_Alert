import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'database_service.dart';

/// NotificationService handles both persisting notification events and
/// showing a local push notification on-device (when not in tests).
class NotificationService {
  NotificationService._private();
  static final NotificationService instance = NotificationService._private();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _inited = false;

  /// Keep a live unread notification count for UI badges
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Initialize the plugin (no-op during unit tests).
  Future<void> init() async {
    if (_inited) return;
    // Avoid initializing on unit tests
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _inited = true;
      // attempt to ensure DB is accessible in tests
      try {
        final db = DatabaseService();
        final cnt = await db.countUnreadNotifications();
        unreadCount.value = cnt;
      } catch (_) {}
      return;
    }

    // FCM Permissions
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get FCM token
    final token = await _fcm.getToken();
    debugPrint('Firebase Messaging Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        sendNotification(
            message.notification?.body ?? message.data['body'] ?? 'New Notification');
      }
    });

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    final settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    _inited = true;
  }

  /// Send a notification - persist it and show a local notification if available.
  Future<void> sendNotification(String message) async {
    // Persist to inbox and update unread count
    try {
      final db = DatabaseService();
      await db.insertNotification(message, read: 0);
      final cnt = await db.countUnreadNotifications();
      unreadCount.value = cnt;
    } catch (e, st) {
      debugPrint('Failed to persist notification: $e\n$st');
    }

    // Show local push if available
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      debugPrint('Notification (test): $message');
      return;
    }

    if (!_inited) await init();

    const androidDetails = AndroidNotificationDetails(
      'aura_alert_channel',
      'Aura Alert',
      channelDescription: 'Stress alerts and notifications from Aura Alert',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final platform = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Aura Alert',
      message,
      platform,
    );
  }

  /// Mark a notification read (and update unread count)
  Future<void> markRead(int id) async {
    try {
      final db = DatabaseService();
      await db.markNotificationRead(id);
      final cnt = await db.countUnreadNotifications();
      unreadCount.value = cnt;
    } catch (e, st) {
      debugPrint('Failed to mark notification read: $e\n$st');
    }
  }

  /// Delete all notifications that are already marked read and update unread count.
  Future<int> clearReadNotifications() async {
    try {
      final db = DatabaseService();
      final removed = await db.deleteReadNotifications();
      final cnt = await db.countUnreadNotifications();
      unreadCount.value = cnt;
      return removed;
    } catch (e, st) {
      debugPrint('Failed to clear read notifications: $e\n$st');
      return 0;
    }
  }
}
