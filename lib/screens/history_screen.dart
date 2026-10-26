import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, Object?>> _activities = [];
  List<Map<String, Object?>> _categories = [];

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Load saved activities and categories from SQLite.
  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final database = DatabaseHelper.instance;

      final activities = await database.getActivities();
      final categories = await database.getCategories();

      if (!mounted) return;

      setState(() {
        _activities = activities;
        _categories = categories;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  // Filter activities by the selected category.
  List<Map<String, Object?>> get _filteredActivities {
    if (_selectedCategoryId == null) {
      return _activities;
    }

    return _activities.where((activity) {
      return activity['category_id'] == _selectedCategoryId;
    }).toList();
  }

  // Only completed activities count toward recorded time.
  int get _totalMinutes {
    int total = 0;

    for (final activity in _filteredActivities) {
      if (activity['status'] == 'completed') {
        total += (activity['duration_minutes'] as num?)?.toInt() ?? 0;
      }
    }

    return total;
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '$minutes min';
    }

    return '$hours hr $minutes min';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    final date = DateTime.tryParse(dateString);

    if (date == null) return 'Unknown date';

    return '${date.month}/${date.day}/${date.year}';
  }

  String _categoryName(Object? categoryId) {
    for (final category in _categories) {
      if (category['id'] == categoryId) {
        return category['name']?.toString() ?? 'Uncategorized';
      }
    }

    return 'Uncategorized';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredActivities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History / Statistics'),
        backgroundColor: Colors.green.shade100,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load history: $_error'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Activity History',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // Filter activities by category.
                  DropdownButtonFormField<int?>(
                    key: ValueKey(_selectedCategoryId),
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem<int?>(
                          value: category['id'] as int,
                          child: Text(
                            category['name']?.toString() ?? 'Category',
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Show the total completed activity time.
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Total Recorded Time',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatMinutes(_totalMinutes),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Activities (${filtered.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No activities found for this category.'),
                      ),
                    ),

                  // Display each saved activity.
                  ...filtered.map((activity) {
                    final title = activity['title']?.toString() ?? 'Activity';

                    final status = activity['status']?.toString() ?? 'planned';

                    final duration =
                        (activity['duration_minutes'] as num?)?.toInt() ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.access_time,
                          color: Colors.green,
                        ),
                        title: Text(title),
                        subtitle: Text(
                          '${_categoryName(activity['category_id'])}\n'
                          '${_formatDate(activity['start_time']?.toString())}'
                          ' • $status',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          _formatMinutes(duration),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
