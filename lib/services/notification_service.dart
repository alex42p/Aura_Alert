import 'dart:io';
import 'dart:math';
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
  late final FirebaseMessaging _fcm;
  bool _inited = false;

  /// Random stress-related messages to send when a notification is triggered
  final List<String> _stressMessages = [
    'We noticed you\'re stressed. Try this breathing exercise: Breathe in for 4 counts, hold for 4, exhale for 4.',
    'Your stress levels are rising. Take a moment to step outside and get some fresh air.',
    'High stress detected. Consider doing some light stretching or meditation for the next 5 minutes.',
    'We\'re sensing increased stress. Try listening to your favorite calming music or podcast.',
    'Stress alert! Take a short walk or do some deep breathing to help you relax.',
    'Your body is showing signs of stress. Consider taking a break and hydrating yourself.',
  ];

  /// Get a random stress-related message
  String getRandomMessage() {
    return _stressMessages[Random().nextInt(_stressMessages.length)];
  }

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

    // Initialize FCM (lazy load)
    _fcm = FirebaseMessaging.instance;

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
      debugPrint('Got a message while in the foreground!');
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
  /// If message is empty, a random stress message will be selected.
  Future<void> sendNotification(String message) async {
    // Use a random stress message if none provided
    final notificationMessage = message.isEmpty ? getRandomMessage() : message;
    // Persist to inbox and update unread count
    try {
      final db = DatabaseService();
      await db.insertNotification(notificationMessage, read: 0);
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
      notificationMessage,
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
