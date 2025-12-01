import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aura_alert/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService', () {
    test('insertDummyData and queryReadings basic', () async {
      // initialize ffi implementation for sqflite in the Dart VM
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final db = DatabaseService();
      // Use a temporary directory for documents
      final tmp = await Directory.systemTemp.createTemp('aura_test_');
      db.documentsDirectoryOverride = tmp;

  // Ensure fresh DB by closing any existing
  await db.close();
  // Force initialization (copies asset DB when TESTING==true), then clear
  await db.database;
  await db.deleteAllReadings();
  final inserted = await db.insertDummyData(50);
      expect(inserted, 50);

      final hr = await db.queryReadings(type: 'hr');
      final temp = await db.queryReadings(type: 'temp');
      final o2 = await db.queryReadings(type: 'o2');

      expect(hr.length + temp.length + o2.length, 50);

      // cleanup
      await db.deleteAllReadings();
      await db.close();
      await tmp.delete(recursive: true);
    });

    test('updateReadingsActivityForLast updates recent rows only', () async {
      final db = DatabaseService();
      final tmp = await Directory.systemTemp.createTemp('aura_test_');
      db.documentsDirectoryOverride = tmp;

      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      await db.close();
      await db.database;
      await db.deleteAllReadings();

      final now = DateTime.now();
      // Insert readings: one 2 minutes ago, one 10 minutes ago
      final dbHandle = await db.database;
      await dbHandle.insert('readings', {'timestamp': now.subtract(const Duration(minutes: 2)).toIso8601String(), 'value': 72, 'type': 'hr'});
      await dbHandle.insert('readings', {'timestamp': now.subtract(const Duration(minutes: 10)).toIso8601String(), 'value': 70, 'type': 'hr'});

      final updated = await db.updateReadingsActivityForLast(const Duration(minutes: 5), 'driving');
      expect(updated, 1);

      final rows = await db.queryReadings(type: 'hr');
      expect(rows.length, 2);
      final recent = rows.where((r) => r.timestamp.isAfter(now.subtract(const Duration(minutes: 5)))).toList();
      expect(recent.first.activity, 'driving');

      // cleanup
      await db.deleteAllReadings();
      await db.close();
      await tmp.delete(recursive: true);
    });
  });
}
