// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/biometric_reading.dart';

const TESTING = true; // set to false when ready to pair with device 

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  /// When set (in tests) this Directory will be used instead of calling
  /// getApplicationDocumentsDirectory(), which requires a platform plugin.
  Directory? documentsDirectoryOverride;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('aura_alert.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
  final Directory documentsDirectory = documentsDirectoryOverride ?? await getApplicationDocumentsDirectory();
  final path = join(documentsDirectory.path, fileName);

    if (TESTING) {
      final exists = await databaseExists(path);
      if (exists) {
        await deleteDatabase(path);
      }
        // clear and reset DB when testing
        ByteData data = await rootBundle.load('assets/$fileName');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes);
    } else {
      final exists = await databaseExists(path);
      if (!exists) {
        // Copy from assets
        ByteData data = await rootBundle.load('assets/$fileName');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes);
      }
    }

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        value REAL NOT NULL,
        type TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertReading(BiometricReading r) async {
    final db = await database;
    return await db.insert('readings', r.toMap());
  }

  /// Export all readings to a CSV file. Returns the file path written.
  Future<String> exportToCsv({String? fileName}) async {
    final db = await database;
    final rows = await db.query('readings', orderBy: 'timestamp ASC');

    final buffer = StringBuffer();
    buffer.writeln('id,timestamp,value,type');
    for (final r in rows) {
      buffer.writeln('${r['id']},${r['timestamp']},${r['value']},${r['type']}');
    }

    final fname = fileName ?? 'aura_alert_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';

    Directory dir;
    try {
      // Prefer writing to Downloads on Android when available
      if (Platform.isAndroid) {
        try {
          final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (dirs != null && dirs.isNotEmpty) {
            dir = dirs.first;
          } else {
            dir = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final outPath = join(dir.path, fname);
      final outFile = File(outPath);
      await outFile.create(recursive: true);
      await outFile.writeAsString(buffer.toString());
      debugPrint('CSV exported to: $outPath');
      return outPath;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all readings from the database.
  Future<void> deleteAllReadings() async {
    final db = await database;
    await db.delete('readings');
  }

  Future<List<BiometricReading>> queryReadings({required String type, DateTime? from, DateTime? to}) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object>[];

    whereClauses.add('type = ?');
    whereArgs.add(type);

    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final whereString = whereClauses.join(' AND ');

    final rows = await db.query('readings', where: whereString, whereArgs: whereArgs, orderBy: 'timestamp ASC');
    return rows.map((r) => BiometricReading.fromMap(r)).toList();
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
    _db = null;
  }

  /// Insert [count] random dummy readings into the database.
  /// Returns number of rows inserted.
  Future<int> insertDummyData(int count) async {
    final db = await database;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90));
    final rng = Random();

    int inserted = 0;
    const batchSize = 200;
    final types = ['hr', 'temp', 'o2'];

    for (var offset = 0; offset < count; offset += batchSize) {
      final batch = db.batch();
      final end = (offset + batchSize).clamp(0, count);
      for (var i = offset; i < end; i++) {
        final typ = types[rng.nextInt(types.length)];
        double value;
        if (typ == 'hr') {
          value = rng.nextDouble() * 80 + 40; // 40..120-ish
          value = value.clamp(30, 200);
        } else if (typ == 'temp') {
          value = rng.nextDouble() * 7 + 30; // 30..37
          value = value.clamp(20.0, 45.0);
        } else {
          value = rng.nextDouble() * 10 + 90; // 90..100
          value = value.clamp(50.0, 100.0);
        }

        final delta = now.difference(start);
        final randSeconds = rng.nextDouble() * delta.inSeconds;
        final ts = start.add(Duration(seconds: randSeconds.toInt()));

        batch.insert('readings', {
          'timestamp': ts.toIso8601String(),
          'value': value,
          'type': typ,
        });
        inserted++;
      }
      await batch.commit(noResult: true);
    }

    return inserted;
  }
}
