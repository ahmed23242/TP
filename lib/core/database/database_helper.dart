import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'incidents.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        name TEXT,
        role TEXT,
        token TEXT
      )
    ''');

    // Incidents table
    await db.execute('''
      CREATE TABLE incidents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        photo_path TEXT,
        voice_note_path TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT,
        sync_status TEXT,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Incident operations
  Future<int> insertIncident(Map<String, dynamic> incident) async {
    final db = await database;
    return await db.insert('incidents', incident);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedIncidents() async {
    final db = await database;
    return await db.query(
      'incidents',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> markIncidentAsSynced(int id) async {
    final db = await database;
    await db.update(
      'incidents',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUserIncidents(int userId) async {
    final db = await database;
    return await db.query(
      'incidents',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }
}
