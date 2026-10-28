import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plot/database/database_helper.dart';

void main() {
  late Directory folder;
  final helper = DatabaseHelper.instance;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('plot_test_');
    await databaseFactory.setDatabasesPath(folder.path);
  });
  tearDown(() async {
    await helper.close();
    await folder.delete(recursive: true);
  });

  test(
    'Category deletion preserves its activity and both entities support CRUD',
    () async {
      final category = await helper.addCategory('Test', 0xFF1976D2);
      final id = await helper.addActivity({
        'title': 'Read',
        'category_id': category,
        'start_time': DateTime.now().toIso8601String(),
        'status': 'planned',
      });
      await helper.updateCategory(category, 'Reading', 0xFF6750A4);
      await helper.updateActivity(id, {'title': 'Read chapter 1'});
      expect((await helper.getActivityById(id))!['title'], 'Read chapter 1');
      expect(
        (await helper.getCategories()).any((r) => r['name'] == 'Reading'),
        isTrue,
      );
      await helper.deleteCategory(category);
      expect((await helper.getActivityById(id))!['category_id'], isNull);
      await helper.deleteActivity(id);
      expect(await helper.getActivityById(id), isNull);
    },
  );
  test(
    'Timer recovers, rejects two running timers, pauses, resets and finishes',
    () async {
      Future<int> add() => helper.addActivity({
        'title': 'Focus',
        'start_time': DateTime.now().toIso8601String(),
        'status': 'planned',
        'active_intervals': '[]',
      });
      final first = await add();
      final second = await add();
      await helper.changeTimer(first, 'start');
      await expectLater(helper.changeTimer(second, 'start'), throwsStateError);
      await helper.updateActivity(first, {
        'timer_resumed_at': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      });
      await helper.close();
      expect((await helper.getActivityById(first))!['status'], 'running');
      await helper.changeTimer(first, 'pause');
      expect(
        (await helper.getActivityById(first))!['elapsed_seconds'] as int,
        greaterThanOrEqualTo(300),
      );
      await helper.changeTimer(first, 'reset');
      expect((await helper.getActivityById(first))!['elapsed_seconds'], 0);
      await helper.changeTimer(first, 'start');
      await helper.changeTimer(first, 'finish');
      expect((await helper.getActivityById(first))!['status'], 'completed');
    },
  );
  test(
    'Manual validation, touching intervals, and optional reflection',
    () async {
      final now = DateTime.now().subtract(const Duration(hours: 2));
      await helper.saveManualActivity(
        title: 'Read',
        start: now,
        end: now.add(const Duration(minutes: 30)),
        notes: '',
      );
      await expectLater(
        helper.saveManualActivity(
          title: 'Overlap',
          start: now,
          end: now.add(const Duration(minutes: 10)),
          notes: '',
        ),
        throwsStateError,
      );
      await helper.saveManualActivity(
        title: 'Next',
        start: now.add(const Duration(minutes: 30)),
        end: now.add(const Duration(minutes: 45)),
        notes: '',
      );
      await expectLater(
        helper.saveManualActivity(
          title: 'Invalid',
          start: now,
          end: now,
          notes: '',
        ),
        throwsArgumentError,
      );
      await helper.saveReflection('2026-10-28', null, 'A long journal entry.');
      await helper.saveReflection('2026-10-28', 4, 'Updated');
      final rows = await helper.getReflections();
      expect(rows.length, 1);
      expect(rows.single['mood'], 4);
      await helper.deleteReflection(rows.single['id'] as int);
      expect(await helper.getReflections(), isEmpty);
    },
  );
  test('v3 migration keeps existing records and makes mood optional', () async {
    final old = await databaseFactory.openDatabase(
      '${folder.path}/plot.db',
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, v) async {
          await db.execute(
            'CREATE TABLE Categories (id INTEGER PRIMARY KEY, name TEXT NOT NULL, color INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE Activities (id INTEGER PRIMARY KEY, category_id INTEGER, title TEXT NOT NULL, start_time TEXT NOT NULL, end_time TEXT, duration_minutes INTEGER DEFAULT 0, planned_duration_minutes INTEGER, notes TEXT, timer_type TEXT, timer_started_at TEXT, timer_resumed_at TEXT, elapsed_seconds INTEGER DEFAULT 0, status TEXT)',
          );
          await db.execute(
            'CREATE TABLE DailyReflections (id INTEGER PRIMARY KEY, date TEXT UNIQUE NOT NULL, mood INTEGER NOT NULL, notes TEXT)',
          );
          await db.insert('Categories', {
            'id': 1,
            'name': 'Old category',
            'color': 0xFF1976D2,
          });
          await db.insert('Activities', {
            'id': 1,
            'title': 'Old entry',
            'start_time': '2026-10-27T10:00:00',
            'status': 'completed',
            'duration_minutes': 20,
          });
          await db.insert('DailyReflections', {
            'id': 1,
            'date': '2026-10-27',
            'mood': 4,
            'notes': 'Keep me',
          });
        },
      ),
    );
    await old.close();
    expect((await helper.getActivityById(1))!['title'], 'Old entry');
    expect((await helper.getReflections()).single['notes'], 'Keep me');
    await helper.saveReflection('2026-10-28', null, 'No emoji needed');
    expect((await helper.getReflections()).length, 2);
  });
}
