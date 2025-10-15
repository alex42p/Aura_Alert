import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/biometric_reading.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('aura_alert.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);

    final exists = await databaseExists(path);
    if (!exists) {
      // Copy from assets
      ByteData data = await rootBundle.load('assets/$fileName');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
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
}
