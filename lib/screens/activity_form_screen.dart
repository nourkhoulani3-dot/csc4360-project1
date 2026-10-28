import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/app_settings.dart';
import '../services/smart_helper.dart';
import 'activity_timer_screen.dart';
import 'categories_screen.dart';

class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({
    super.key,
    this.activityId,
    this.manual = false,
    this.initialStart,
    this.initialEnd,
  });
  final int? activityId;
  final bool manual;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  List<Map<String, Object?>> _categories = [];
  int? _categoryId;
  int _minutes = 25;
  bool _openTimer = false;
  bool _manual = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, Object?>? _existing;
  SmartHelperResult? _suggestion;
  AppSettings? _settings;
  late DateTime _start;
  late DateTime _end;

  bool get _editing => widget.activityId != null;
  bool get _locked => _existing != null && _existing!['status'] != 'planned';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = widget.initialStart ?? now.subtract(const Duration(minutes: 25));
    _end = widget.initialEnd ?? now;
    _manual = widget.manual;
    _load();
  }

  Future<void> _load() async {
    try {
      final db = DatabaseHelper.instance;
      final settings = await AppSettings.load();
      final categories = await db.getCategories();
      final row = _editing
          ? await db.getActivityById(widget.activityId!)
          : null;
      if (_editing && row == null) throw StateError('Activity not found.');
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _categories = categories;
        _minutes = settings.defaultMinutes;
        _categoryId = categories.isEmpty ? null : categories.first['id'] as int;
        if (row != null) {
          _existing = row;
          _name.text = row['title']?.toString() ?? '';
          _notes.text = row['notes']?.toString() ?? '';
          _categoryId = row['category_id'] as int?;
          _minutes =
              (row['planned_duration_minutes'] as num?)?.toInt() ?? _minutes;
          _openTimer = row['planned_duration_minutes'] == null;
          _manual = row['status'] == 'completed';
          _start = DateTime.parse(row['start_time'] as String).toLocal();
          _end =
              DateTime.tryParse(row['end_time']?.toString() ?? '')?.toLocal() ??
              _end;
        }
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the form. Tap Retry.';
        });
      }
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _manageCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
    );
    try {
      final rows = await DatabaseHelper.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = rows;
        if (!rows.any((r) => r['id'] == _categoryId)) _categoryId = null;
        _suggestion = null;
      });
    } catch (_) {
      _message('Could not refresh categories.');
    }
  }

  Future<void> _suggest() async {
    final id = _categoryId;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      final value = await SmartHelper.suggestDuration(id);
      if (mounted && id == _categoryId) setState(() => _suggestion = value);
    } catch (_) {
      _message('Could not load a suggestion. You can choose your own time.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(bool start) async {
    final old = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: old,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(old),
    );
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  String _timeLabel(DateTime value) =>
      '${value.month}/${value.day}/${value.year} ${TimeOfDay.fromDateTime(value).format(context)}';

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      _message('Enter an activity name.');
      return;
    }
    setState(() => _saving = true);
    try {
      final db = DatabaseHelper.instance;
      int id;
      // Completed records can keep their exact saved pause intervals unless
      // the user deliberately changes their start or finish time.
      final unchangedTimes =
          _existing != null &&
          _manual &&
          DateTime.parse(_existing!['start_time'] as String)
              .isAtSameMomentAs(_start) &&
          DateTime.tryParse(_existing!['end_time']?.toString() ?? '')
                  ?.isAtSameMomentAs(_end) ==
              true;
      if (_manual && !unchangedTimes) {
        id = await db.saveManualActivity(
          id: widget.activityId,
          title: _name.text,
          categoryId: _categoryId,
          start: _start,
          end: _end,
          notes: _notes.text,
        );
      } else if (_editing) {
        id = widget.activityId!;
        final values = <String, Object?>{
          'title': _name.text.trim(),
          'category_id': _categoryId,
          'notes': _notes.text.trim(),
        };
        if (!_locked) {
          values.addAll({
            'planned_duration_minutes': _openTimer ? null : _minutes,
            'timer_type': _openTimer ? 'open' : 'timed',
          });
        }
        if (await db.updateActivity(id, values) == 0) {
          throw StateError('Activity not found.');
        }
      } else {
        id = await db.addActivity({
          'title': _name.text.trim(),
          'category_id': _categoryId,
          'notes': _notes.text.trim(),
          'start_time': DateTime.now().toIso8601String(),
          'status': 'planned',
          'duration_minutes': 0,
          'active_intervals': '[]',
          'planned_duration_minutes': _openTimer ? null : _minutes,
          'timer_type': _openTimer ? 'open' : 'timed',
        });
      }
      if (!mounted) return;
      if (!_editing && !_manual) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ActivityTimerScreen(activityId: id),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _message(
        error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Invalid argument(s): ', ''),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activity')),
        body: Center(
          child: TextButton(onPressed: _load, child: Text(_error!)),
        ),
      );
    }
    final choices = <int>{
      _minutes,
      for (int n = 5; n <= 180; n += 5) n,
    }.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit activity' : 'Add activity')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _name,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Activity name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey(_categoryId),
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Uncategorized'),
                ),
                ..._categories.map(
                  (r) => DropdownMenuItem(
                    value: r['id'] as int,
                    child: Text(r['name'].toString()),
                  ),
                ),
              ],
              onChanged: (id) => setState(() {
                _categoryId = id;
                _suggestion = null;
              }),
            ),
            TextButton.icon(
              onPressed: _manageCategories,
              icon: const Icon(Icons.category_outlined),
              label: const Text('Manage categories and colors'),
            ),
            if (!_editing)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Log something I already did'),
                value: _manual,
                onChanged: (value) => setState(() {
                  _manual = value;
                  _suggestion = null;
                }),
              ),
            if (_manual) ...[
              OutlinedButton.icon(
                onPressed: () => _pickTime(true),
                icon: const Icon(Icons.schedule),
                label: Text('Start: ${_timeLabel(_start)}'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickTime(false),
                icon: const Icon(Icons.schedule),
                label: Text('Finish: ${_timeLabel(_end)}'),
              ),
              if (_existing != null)
                const Text(
                  'Changing times replaces any saved pauses with one continuous interval.',
                ),
            ] else if (!_locked) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open timer'),
                subtitle: const Text('Track without a time goal'),
                value: _openTimer,
                onChanged: (value) => setState(() => _openTimer = value),
              ),
              if (!_openTimer)
                DropdownButtonFormField<int>(
                  key: ValueKey('duration-$_minutes'),
                  initialValue: _minutes,
                  decoration: const InputDecoration(
                    labelText: 'Planned minutes',
                  ),
                  items: choices
                      .map(
                        (n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n minutes'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _minutes = value);
                  },
                ),
              if (_categoryId != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Duration suggestions for this category'),
                  value: _settings?.suggestionsEnabledFor(_categoryId!) ?? true,
                  onChanged: (value) async {
                    try {
                      await _settings!.setSuggestionsEnabledFor(
                        _categoryId!,
                        value,
                      );
                      if (mounted) setState(() => _suggestion = null);
                    } catch (_) {
                      _message('Could not save suggestion preference.');
                    }
                  },
                ),
              OutlinedButton.icon(
                onPressed:
                    _categoryId == null ||
                        !(_settings?.suggestionsEnabledFor(_categoryId!) ??
                            true)
                    ? null
                    : _suggest,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Suggest a duration'),
              ),
              if (_suggestion != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_suggestion!.explanation),
                        Wrap(
                          spacing: 12,
                          children: [
                            TextButton(
                              onPressed: () => setState(() {
                                _minutes = _suggestion!.suggestedMinutes;
                                _openTimer = false;
                              }),
                              child: Text(
                                'Apply ${_suggestion!.suggestedMinutes} minutes',
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _suggestion = null),
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ] else
              const Text(
                'Finish or reset the timer before changing its duration.',
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (_saving) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
