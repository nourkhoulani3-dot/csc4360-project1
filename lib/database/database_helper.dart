import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'plot.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE Activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER,
            title TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            duration_minutes INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'completed',
            FOREIGN KEY (category_id)
              REFERENCES Categories(id)
              ON DELETE SET NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE DailyReflections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            mood INTEGER NOT NULL,
            notes TEXT
          )
        ''');
      },
    );
  }

  // Add a new category.
  Future<int> addCategory(String name, int color) async {
    final db = await database;

    return db.insert('Categories', {'name': name.trim(), 'color': color});
  }

  // Get all saved categories.
  Future<List<Map<String, Object?>>> getCategories() async {
    final db = await database;
    return db.query('Categories', orderBy: 'name ASC');
  }

  // Edit a category.
  Future<int> updateCategory(int id, String name, int color) async {
    final db = await database;

    return db.update(
      'Categories',
      {'name': name.trim(), 'color': color},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a category without deleting its activities.
  Future<int> deleteCategory(int id) async {
    final db = await database;

    return db.delete('Categories', where: 'id = ?', whereArgs: [id]);
  }

  // Add a new activity.
  Future<int> addActivity(Map<String, Object?> activity) async {
    final db = await database;
    return db.insert('Activities', activity);
  }

  // Get activities, starting with the newest.
  Future<List<Map<String, Object?>>> getActivities() async {
    final db = await database;
    return db.query('Activities', orderBy: 'start_time DESC');
  }

  // Get activities from one category.
  Future<List<Map<String, Object?>>> getActivitiesByCategory(
    int categoryId,
  ) async {
    final db = await database;

    return db.query(
      'Activities',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'start_time DESC',
    );
  }

  // Edit an activity.
  Future<int> updateActivity(int id, Map<String, Object?> changes) async {
    final db = await database;

    return db.update('Activities', changes, where: 'id = ?', whereArgs: [id]);
  }

  // Delete an activity.
  Future<int> deleteActivity(int id) async {
    final db = await database;

    return db.delete('Activities', where: 'id = ?', whereArgs: [id]);
  }

  // Get the total recorded minutes for a category.
  Future<int> getCategoryTotalMinutes(int categoryId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(duration_minutes), 0) AS total
      FROM Activities
      WHERE category_id = ? AND status = 'completed'
      ''',
      [categoryId],
    );

    return (result.first['total'] as num).toInt();
  }

  // Add or update a reflection for a specific day.
  Future<int> saveReflection(String date, int mood, String notes) async {
    final db = await database;

    return db.insert('DailyReflections', {
      'date': date,
      'mood': mood,
      'notes': notes,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all reflections, newest first.
  Future<List<Map<String, Object?>>> getReflections() async {
    final db = await database;
    return db.query('DailyReflections', orderBy: 'date DESC');
  }

  // Delete a reflection.
  Future<int> deleteReflection(int id) async {
    final db = await database;

    return db.delete('DailyReflections', where: 'id = ?', whereArgs: [id]);
  }

  // Close the database when needed.
  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
