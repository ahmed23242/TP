import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accidents.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        name TEXT,
        role TEXT NOT NULL,
        token TEXT,
        last_login TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE incidents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        photo_path TEXT,
        photo_url TEXT,
        voice_note_path TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        incident_type TEXT NOT NULL DEFAULT 'general',
        sync_status TEXT NOT NULL,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_incidents_user_id ON incidents(user_id)');
    await db.execute('CREATE INDEX idx_incidents_sync_status ON incidents(sync_status)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Mise à jour de la structure de la base de données lors des mises à jour
    if (oldVersion < 2) {
      // Ajouter les colonnes manquantes à la table incidents
      try {
        await db.execute('ALTER TABLE incidents ADD COLUMN photo_url TEXT;');
        await db.execute('ALTER TABLE incidents ADD COLUMN status TEXT NOT NULL DEFAULT "pending";');
        await db.execute('ALTER TABLE incidents ADD COLUMN incident_type TEXT NOT NULL DEFAULT "general";');
      } catch (e) {
        print('Error upgrading database: $e');
        // Si erreur (ex: colonne existe déjà), on continue
      }
    }
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertIncident(Map<String, dynamic> incident) async {
    final db = await database;
    return await db.insert(
      'incidents',
      incident,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getIncidentsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'incidents',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedIncidents() async {
    final db = await database;
    return await db.query(
      'incidents',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> updateIncidentSyncStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'incidents',
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
