import 'dart:convert';

import '../services/activity_time.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  // Open the database when needed.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  // Open the database and create or upgrade its tables.
  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'plot.db');

    return openDatabase(
      path,
      version: 4,
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
            planned_duration_minutes INTEGER,
            notes TEXT,
            timer_type TEXT NOT NULL DEFAULT 'timed',
            timer_started_at TEXT,
            timer_resumed_at TEXT,
            elapsed_seconds INTEGER NOT NULL DEFAULT 0,
            active_intervals TEXT,
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
            mood INTEGER,
            notes TEXT
          )
        ''');
      },

      onOpen: (db) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS PlotMetadata (key TEXT PRIMARY KEY)',
        );
        final seeded = await db.query(
          'PlotMetadata',
          where: 'key = ?',
          whereArgs: ['categories_seeded'],
        );
        if (seeded.isEmpty) {
          await db.transaction((txn) async {
            final existing = await txn.query('Categories');
            if (existing.isEmpty) {
              for (final entry in <String, int>{
                'Studying': 0xFF6750A4,
                'Work': 0xFF00796B,
                'Rest': 0xFF1976D2,
                'Sleep': 0xFF3949AB,
                'Personal': 0xFFEF6C00,
              }.entries) {
                await txn.insert('Categories', {
                  'name': entry.key,
                  'color': entry.value,
                });
              }
            }
            await txn.insert('PlotMetadata', {'key': 'categories_seeded'});
          });
        }
      },

      // Upgrade older databases without deleting saved records.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE Activities ADD COLUMN active_intervals TEXT',
          );
          await db.execute(
            'ALTER TABLE DailyReflections RENAME TO OldReflections',
          );
          await db.execute(
            'CREATE TABLE DailyReflections (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL UNIQUE, mood INTEGER, notes TEXT)',
          );
          await db.execute(
            'INSERT INTO DailyReflections SELECT id, date, mood, notes FROM OldReflections',
          );
          await db.execute('DROP TABLE OldReflections');
        }
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE Activities
            ADD COLUMN planned_duration_minutes INTEGER
          ''');

          await db.execute('''
            ALTER TABLE Activities
            ADD COLUMN notes TEXT
          ''');

          await db.execute('''
            ALTER TABLE Activities
            ADD COLUMN timer_type TEXT NOT NULL DEFAULT 'timed'
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE Activities
            ADD COLUMN timer_started_at TEXT
          ''');

          await db.execute('''
            ALTER TABLE Activities
            ADD COLUMN timer_resumed_at TEXT
          ''');

          await db.execute('''
            ALTER TABLE Activities
            ADD COLUMN elapsed_seconds INTEGER NOT NULL DEFAULT 0
          ''');
        }
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

  // Get one activity by its ID.
  Future<Map<String, Object?>?> getActivityById(int id) async {
    final db = await database;

    final results = await db.query(
      'Activities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
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

  // Get the last three completed activities for the smart helper.
  Future<List<Map<String, Object?>>> getRecentCompletedActivities(
    int categoryId,
  ) async {
    final db = await database;

    return db.query(
      'Activities',
      where: '''
        category_id = ?
        AND status = ?
        AND duration_minutes > 0
      ''',
      whereArgs: [categoryId, 'completed'],
      orderBy: 'end_time DESC',
      limit: 3,
    );
  }

  // All timer changes are committed before the UI changes.
  Future<void> changeTimer(int id, String action) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'Activities',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) throw StateError('Activity no longer exists.');
      final row = rows.first;
      final status = row['status'];
      if (status == 'completed') {
        throw StateError('This activity is already finished.');
      }
      final now = DateTime.now();
      final encoded = row['active_intervals']?.toString();
      final intervals = encoded == null
          ? activityPeriods({...row, 'status': 'paused'})
                .map<dynamic>(
                  (p) => {
                    'start': p.start.toIso8601String(),
                    'end': p.end.toIso8601String(),
                  },
                )
                .toList()
          : jsonDecode(encoded) as List<dynamic>;
      var seconds = (row['elapsed_seconds'] as num?)?.toInt() ?? 0;
      final resumed = DateTime.tryParse(
        row['timer_resumed_at']?.toString() ?? '',
      );
      if (status == 'running' && resumed != null) {
        final extra = now.difference(resumed).inSeconds;
        if (extra > 0) {
          seconds += extra;
          intervals.add({
            'start': resumed.toIso8601String(),
            'end': now.toIso8601String(),
          });
        }
      }
      final changes = <String, Object?>{
        'elapsed_seconds': seconds,
        'active_intervals': jsonEncode(intervals),
        'timer_resumed_at': null,
      };
      if (action == 'start') {
        if (status == 'running') return;
        final running = await txn.query(
          'Activities',
          where: "status = 'running' AND id != ?",
          whereArgs: [id],
        );
        if (running.isNotEmpty) {
          throw StateError('Pause or finish the other running activity first.');
        }
        changes.addAll({
          'status': 'running',
          'timer_started_at': row['timer_started_at'] ?? now.toIso8601String(),
          'start_time': row['timer_started_at'] == null
              ? now.toIso8601String()
              : row['start_time'],
          'timer_resumed_at': now.toIso8601String(),
        });
      } else if (action == 'pause') {
        if (status != 'running') return;
        changes['status'] = 'paused';
      } else if (action == 'finish') {
        if (row['timer_started_at'] == null) {
          throw StateError('Start the timer first.');
        }
        changes.addAll({
          'status': 'completed',
          'end_time': now.toIso8601String(),
          'start_time': row['timer_started_at'],
          'duration_minutes': seconds ~/ 60,
          'timer_started_at': null,
        });
      } else if (action == 'reset') {
        changes.addAll({
          'status': 'planned',
          'elapsed_seconds': 0,
          'active_intervals': '[]',
          'duration_minutes': 0,
          'timer_started_at': null,
          'end_time': null,
        });
      } else {
        throw ArgumentError('Unknown timer action.');
      }
      await txn.update('Activities', changes, where: 'id = ?', whereArgs: [id]);
    });
  }

  // Validate and save manual entries in a transaction. Pauses in other records
  // remain available for separate activities instead of blocking the whole span.
  Future<int> saveManualActivity({
    int? id,
    required String title,
    int? categoryId,
    required DateTime start,
    required DateTime end,
    required String notes,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Enter an activity name.');
    if (!end.isAfter(start)) {
      throw ArgumentError('Finish time must be after start time.');
    }
    if (end.isAfter(DateTime.now())) {
      throw ArgumentError('Recorded activities cannot end in the future.');
    }
    final db = await database;
    return db.transaction((txn) async {
      final all = await txn.query('Activities');
      final candidate = ActivePeriod(start, end);
      for (final row in all) {
        if (row['id'] == id || row['status'] == 'planned') continue;
        if (activityPeriods(row).any((p) => periodsOverlap(candidate, p))) {
          throw StateError(
            'This overlaps "${row['title']}". Adjust the times first.',
          );
        }
      }
      if (id != null) {
        final old = all.where((r) => r['id'] == id);
        if (old.isEmpty) throw StateError('Activity no longer exists.');
        if (old.first['status'] != 'completed') {
          throw StateError('Finish the timer before correcting its times.');
        }
      }
      final seconds = end.difference(start).inSeconds;
      final values = <String, Object?>{
        'title': title.trim(),
        'category_id': categoryId,
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
        'duration_minutes': seconds ~/ 60,
        'elapsed_seconds': seconds,
        'planned_duration_minutes': null,
        'timer_type': 'manual',
        'notes': notes.trim(),
        'status': 'completed',
        'timer_started_at': null,
        'timer_resumed_at': null,
        'active_intervals': jsonEncode([
          {'start': start.toIso8601String(), 'end': end.toIso8601String()},
        ]),
      };
      if (id == null) return txn.insert('Activities', values);
      final count = await txn.update(
        'Activities',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) throw StateError('Activity no longer exists.');
      return id;
    });
  }

  // Add or update a reflection for a specific day.
  Future<int> saveReflection(String date, int? mood, String notes) async {
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
