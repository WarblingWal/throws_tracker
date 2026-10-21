import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB('throws_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        sex TEXT NOT NULL,
        ageGroup TEXT NOT NULL,
        country TEXT NOT NULL DEFAULT 'United Kingdom (UK)',
        isActive INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE throws (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        discipline TEXT NOT NULL,
        division TEXT NOT NULL,
        loggedDistance REAL NOT NULL,
        activeWeight REAL NOT NULL,
        projectedDistance REAL NOT NULL,
        timestamp TEXT NOT NULL,
        technique TEXT NOT NULL DEFAULT 'Standing Throw'
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
            "ALTER TABLE user_profile ADD COLUMN country TEXT NOT NULL DEFAULT 'United Kingdom (UK)'");
      } catch (e) {
        debugPrint("Database migration column safety bypass: $e");
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
            "ALTER TABLE throws ADD COLUMN technique TEXT NOT NULL DEFAULT 'Standing Throw'");
      } catch (e) {
        debugPrint("Database migration technique column safety bypass: $e");
      }
    }
  }

  Future<bool> createProfile(String username, String sex, String ageGroup,
      {String country = 'United Kingdom (UK)'}) async {
    try {
      final db = await instance.database;
      final profileData = {
        'username': username,
        'sex': sex,
        'ageGroup': ageGroup,
        'country': country,
        'isActive': 0,
      };
      final rowId = await db.insert('user_profile', profileData);
      return rowId > 0;
    } catch (e) {
      debugPrint("Profile creation engine error: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final db = await instance.database;
    return await db.query('user_profile', orderBy: 'username ASC');
  }

  Future<void> setActiveProfile(int id) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.update('user_profile', {'isActive': 0});
    batch.update('user_profile', {'isActive': 1},
        where: 'id = ?', whereArgs: [id]);
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> getActiveProfile() async {
    final db = await instance.database;
    final maps =
        await db.query('user_profile', where: 'isActive = 1', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> clearActiveProfile() async {
    final db = await instance.database;
    await db.update('user_profile', {'isActive': 0}, where: 'isActive = 1');
  }

  Future<int> insertThrow({
    required int userId,
    required String discipline,
    required String division,
    required double loggedDistance,
    required double activeWeight,
    required double projectedDistance,
    required String technique,
  }) async {
    final db = await instance.database;
    final dataRow = {
      'userId': userId,
      'discipline': discipline,
      'division': division,
      'loggedDistance': loggedDistance,
      'activeWeight': activeWeight,
      'projectedDistance': projectedDistance,
      'timestamp': DateTime.now().toIso8601String(),
      'technique': technique,
    };
    return await db.insert('throws', dataRow);
  }

  // 🔹 Added: High-contrast data removal database execution engine layer
  Future<bool> deleteThrow(int id) async {
    try {
      final db = await instance.database;
      final rowsAffected =
          await db.delete('throws', where: 'id = ?', whereArgs: [id]);
      return rowsAffected > 0;
    } catch (e) {
      debugPrint("Database entry deletion failure: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchThrowsForUser(
      int userId, String discipline) async {
    final db = await instance.database;
    return await db.query(
      'throws',
      where: 'userId = ? AND discipline = ?',
      whereArgs: [userId, discipline],
      orderBy: 'timestamp DESC',
    );
  }
}
