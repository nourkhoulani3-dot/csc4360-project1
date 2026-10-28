import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/activity_time.dart';
import 'today_screen.dart';
import 'reflection_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, Object?>> _rows = [], _categories = [], _reflections = [];
  bool _loading = true;
  int? _category;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseHelper.instance;
      final rows = await db.getActivities();
      final categories = await db.getCategories();
      final reflections = await db.getReflections();
      if (mounted) {
        setState(() {
          _rows = rows;
          _categories = categories;
          _reflections = reflections;
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
          _error = 'Could not load history.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows
        .where((r) => _category == null || r['category_id'] == _category)
        .toList();
    final dates = <String>{};
    final now = DateTime.now();
    for (final row in rows) {
      for (final period in activityPeriods(row, now: now)) {
        var day = DateTime(
          period.start.year,
          period.start.month,
          period.start.day,
        );
        while (day.isBefore(period.end)) {
          dates.add(dateKey(day));
          day = DateTime(day.year, day.month, day.day + 1);
        }
      }
    }
    if (_category == null) {
      dates.addAll(_reflections.map((r) => r['date'].toString()));
    }
    final days = dates.toList()..sort((a, b) => b.compareTo(a));
    final total = rows.fold<Duration>(
      Duration.zero,
      (sum, row) =>
          sum +
          activityPeriods(
            row,
            now: now,
          ).fold<Duration>(Duration.zero, (value, p) => value + p.duration),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('History / Insights')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: TextButton(onPressed: _load, child: Text('$_error Retry')),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 20),
                  Text(
                    '${recordedDuration(total)} recorded',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${rows.where((r) => r['status'] == 'completed').length} completed activities',
                  ),
                  const SizedBox(height: 20),
                  if (days.isEmpty)
                    const Text(
                      'Your recorded activities and reflections will appear here.',
                    ),
                  ...days.map((key) {
                    final date = DateTime.parse(key);
                    final duration = rows.fold<Duration>(
                      Duration.zero,
                      (sum, row) =>
                          sum +
                          periodsOnDay(row, date, now: now).fold<Duration>(
                            Duration.zero,
                            (v, p) => v + p.duration,
                          ),
                    );
                    final reflection = _reflections
                        .where((r) => r['date'] == key)
                        .firstOrNull;
                    return Card(
                      child: ListTile(
                        title: Text(key),
                        leading: Text(
                          reflectionMood(reflection?['mood']) ==
                                  'No mood selected'
                              ? '—'
                              : reflectionMood(reflection?['mood']),
                          style: const TextStyle(fontSize: 28),
                        ),
                        subtitle: Text(
                          '${recordedDuration(duration)} recorded${reflection == null ? '' : ' • Reflection saved'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TodayScreen(initialDay: date),
                            ),
                          );
                          await _load();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
