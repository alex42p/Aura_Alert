import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aura_alert/services/database_service.dart';
import 'package:aura_alert/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    test('sendNotification persists to DB', () async {
      final db = DatabaseService();
      final tmp = await Directory.systemTemp.createTemp('aura_notif_');
      db.documentsDirectoryOverride = tmp;

      await db.close();
      await db.database; // initialize

      final svc = NotificationService.instance;
      // in tests init() is a no-op but persists to DB
      await svc.init();

      expect(svc.unreadCount.value, equals(0));

      await svc.sendNotification('test message');

      // persisted
      final rows = await db.queryNotifications();
      expect(rows, isNotEmpty);
      expect((rows.first['message'] as String), contains('test message'));

      // unread count updated
      expect(svc.unreadCount.value, equals(1));

      // mark it read
      final id = rows.first['id'] as int;
      await svc.markRead(id);
      final rows2 = await db.queryNotifications();
      expect((rows2.first['read'] as int), equals(1));
      expect(svc.unreadCount.value, equals(0));

      // now clear read notifications
      final removed = await svc.clearReadNotifications();
      expect(removed, greaterThanOrEqualTo(1));
      final rows3 = await db.queryNotifications();
      // any rows remaining should be unread (read == 0)
      expect(rows3.where((r) => (r['read'] as int) == 1), isEmpty);

      await db.close();
      await tmp.delete(recursive: true);
    });
  });
}
