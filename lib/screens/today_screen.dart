import 'dart:async';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/activity_time.dart';
import '../widgets/activity_card.dart';
import '../widgets/day_summary_card.dart';
import 'activity_form_screen.dart';
import 'saved_activities_screen.dart';
import 'reflection_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.initialDay});
  final DateTime? initialDay;
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  late DateTime _day;
  List<Map<String, Object?>> _activities = [],
      _categories = [],
      _reflections = [];
  bool _loading = true;
  String? _error;
  Timer? _refresh;
  @override
  void initState() {
    super.initState();
    _day = widget.initialDay ?? DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseHelper.instance;
      final activities = await db.getActivities();
      final categories = await db.getCategories();
      final reflections = await db.getReflections();
      if (mounted) {
        setState(() {
          _activities = activities;
          _categories = categories;
          _reflections = reflections;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load your day.';
        });
      }
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    await _load();
  }

  Future<void> _pickDay() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _day = date);
  }

  Widget _gap(DateTime start, DateTime end) => Card(
    elevation: 0,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.more_time),
      title: const Text('Room to fill in'),
      subtitle: Text(
        '${TimeOfDay.fromDateTime(start).format(context)} - ${TimeOfDay.fromDateTime(end).format(context)}\n${recordedDuration(end.difference(start))} unlogged',
      ),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: () => _open(
        ActivityFormScreen(manual: true, initialStart: start, initialEnd: end),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayStart = DateTime(_day.year, _day.month, _day.day);
    final dayEnd = DateTime(_day.year, _day.month, _day.day + 1);
    final today = dateKey(_day) == dateKey(now);
    final cutoff = today ? now : dayEnd;
    final entries = <({Map<String, Object?> row, ActivePeriod period})>[];
    for (final row in _activities) {
      for (final period in periodsOnDay(row, _day, now: now)) {
        entries.add((row: row, period: period));
      }
    }
    entries.sort((a, b) => a.period.start.compareTo(b.period.start));
    final total = entries.fold<Duration>(
      Duration.zero,
      (sum, e) => sum + e.period.duration,
    );
    final reflection = _reflections
        .where((r) => r['date'] == dateKey(_day))
        .firstOrNull;
    final timeline = <Widget>[];
    var cursor = dayStart;
    for (final entry in entries) {
      if (entry.period.start.difference(cursor).inMinutes >= 1) {
        timeline.add(_gap(cursor, entry.period.start));
      }
      timeline.add(
        ActivityCard(
          activity: entry.row,
          categories: _categories,
          onChanged: _load,
          period: entry.period,
        ),
      );
      if (entry.period.end.isAfter(cursor)) cursor = entry.period.end;
    }
    if (cutoff.difference(cursor).inMinutes >= 1) {
      timeline.add(_gap(cursor, cutoff));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plot',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.5),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh day',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: Text('$_error Tap to retry.'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        onPressed: () => setState(
                          () => _day = DateTime(
                            _day.year,
                            _day.month,
                            _day.day - 1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _pickDay,
                          child: Text(
                            '${dateKey(_day)}${today ? ' • Today' : ''}',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next day',
                        onPressed: today
                            ? null
                            : () => setState(
                                () => _day = DateTime(
                                  _day.year,
                                  _day.month,
                                  _day.day + 1,
                                ),
                              ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  DaySummaryCard(
                    day: _day,
                    total: total,
                    count: entries.map((e) => e.row['id']).toSet().length,
                    segments: entries.map((e) {
                      final category = _categories
                          .where((c) => c['id'] == e.row['category_id'])
                          .firstOrNull;
                      return (
                        period: e.period,
                        color: category == null
                            ? Colors.grey
                            : Color(category['color'] as int),
                      );
                    }).toList(),
                    onAdd: () => _open(const ActivityFormScreen()),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _open(const SavedActivitiesScreen()),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Browse all activities'),
                    ),
                  ),
                  if (today) ...[
                    const SizedBox(height: 16),
                    ..._activities
                        .where(
                          (a) =>
                              a['status'] == 'running' ||
                              a['status'] == 'paused' ||
                              a['status'] == 'planned',
                        )
                        .map(
                          (row) => ActivityCard(
                            activity: row,
                            categories: _categories,
                            onChanged: _load,
                          ),
                        ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Daily timeline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'Tap a block to edit it. Tap a gap to fill it in.',
                  ),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.draw_outlined),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your first activity will bring this timeline to life.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...timeline,
                  if (entries.any((e) => e.row['active_intervals'] == null))
                    const Text(
                      'Older records use estimated positions because exact pause times were not saved.',
                    ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      textColor: Theme.of(context)
                          .colorScheme
                          .onTertiaryContainer,
                      iconColor: Theme.of(context)
                          .colorScheme
                          .onTertiaryContainer,
                      leading: const Icon(
                        Icons.auto_stories_outlined,
                        size: 30,
                      ),
                      title: Text(
                        reflection == null
                            ? 'Daily reflection'
                            : 'Daily reflection • ${reflectionMood(reflection['mood'])}',
                      ),
                      subtitle: Text(
                        reflection?['notes']?.toString().isNotEmpty == true
                            ? reflection!['notes'].toString()
                            : 'An optional mood and space to write about your day.',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _open(ReflectionScreen(day: _day)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
