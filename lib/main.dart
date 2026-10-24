import 'package:flutter/material.dart';

import 'database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PlotApp());
}

class PlotApp extends StatelessWidget {
  const PlotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DatabaseTestPage(),
    );
  }
}

class DatabaseTestPage extends StatefulWidget {
  const DatabaseTestPage({super.key});

  @override
  State<DatabaseTestPage> createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends State<DatabaseTestPage> {
  String result = 'Press the button to test SQLite.';
  bool isTesting = false;

  Future<void> testDatabase() async {
    setState(() {
      isTesting = true;
      result = 'Testing database...';
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Add a category.
      final categoryId = await db.insert('Categories', {
        'name': 'School',
        'color': Colors.blue.toARGB32(),
      });

      // Check that the category was saved.
      final saved = await db.query(
        'Categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      if (saved.length != 1 || saved.first['name'] != 'School') {
        throw Exception('Create or read test failed');
      }

      // Change the category name.
      await db.update(
        'Categories',
        {'name': 'Studying'},
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      final updated = await db.query(
        'Categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      if (updated.length != 1 || updated.first['name'] != 'Studying') {
        throw Exception('Update test failed');
      }

      // Delete the test category.
      await db.delete('Categories', where: 'id = ?', whereArgs: [categoryId]);

      final deleted = await db.query(
        'Categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      if (deleted.isNotEmpty) {
        throw Exception('Delete test failed');
      }

      if (!mounted) return;

      setState(() {
        result =
            'SQLite test passed!\n\n'
            'Create: Passed\n'
            'Read: Passed\n'
            'Update: Passed\n'
            'Delete: Passed';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        result = 'Database test failed:\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plot - Database Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storage, size: 70, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                result,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isTesting ? null : testDatabase,
                child: const Text('Test SQLite Database'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
