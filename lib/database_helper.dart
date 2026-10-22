import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('throws_tracker_prod.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        country TEXT NOT NULL,
        discipline TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE throw_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        discipline TEXT NOT NULL,
        techniqueVariant TEXT NOT NULL,
        distance REAL NOT NULL,
        dateStamp TEXT NOT NULL
      )
    ''');
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await instance.database;
    final maps = await db.query('user_profile', limit: 1);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> saveUserProfile(
      String name, String country, String discipline) async {
    final db = await instance.database;
    await db.delete('user_profile');
    await db.insert('user_profile', {
      'name': name,
      'country': country,
      'discipline': discipline,
    });
  }

  Future<List<Map<String, dynamic>>> getThrowLogs(String discipline) async {
    final db = await instance.database;
    return await db.query(
      'throw_logs',
      where: 'discipline = ?',
      whereArgs: [discipline],
      orderBy: 'id DESC',
    );
  }

  Future<int> insertThrowLog(String discipline, String variant, double distance,
      String dateStamp) async {
    final db = await instance.database;
    return await db.insert('throw_logs', {
      'discipline': discipline,
      'techniqueVariant': variant,
      'distance': distance,
      'dateStamp': dateStamp,
    });
  }

  Future<int> deleteThrowLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'throw_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db =
        _database; // 👈 Fixed: Removed 'await' since raw Database instance isn't a Future
    if (db != null) await db.close();
  }
}
