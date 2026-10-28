import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../widgets/activity_card.dart';
import 'activity_form_screen.dart';

class SavedActivitiesScreen extends StatefulWidget {
  const SavedActivitiesScreen({super.key});
  @override
  State<SavedActivitiesScreen> createState() => _SavedActivitiesScreenState();
}

class _SavedActivitiesScreenState extends State<SavedActivitiesScreen> {
  List<Map<String, Object?>> _rows = [], _categories = [];
  bool _loading = true;
  String? _error;
  int? _category;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseHelper.instance.getActivities();
      final categories = await DatabaseHelper.instance.getCategories();
      if (mounted) {
        setState(() {
          _rows = rows;
          _categories = categories;
          _loading = false;
          _error = null;
          if (_category != null &&
              !categories.any((c) => c['id'] == _category)) {
            _category = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load activities.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows
        .where((r) => _category == null || r['category_id'] == _category)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('All activities')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add activity',
        onPressed: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const ActivityFormScreen()),
          );
          await _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: TextButton(onPressed: _load, child: Text('$_error Retry')),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey(_category),
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Filter by category',
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ..._categories.map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name'].toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 12),
                  Text('${rows.length} activities'),
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No activities match this filter.'),
                    ),
                  ...rows.map(
                    (row) => ActivityCard(
                      activity: row,
                      categories: _categories,
                      onChanged: _load,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
