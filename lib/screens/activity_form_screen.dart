import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/smart_helper.dart';
import 'activity_timer_screen.dart';

class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({super.key, this.activityId});

  final int? activityId;

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _category = 'Studying';

  bool _timed = true;
  bool _startNow = true;
  bool _isSaving = false;
  bool _isLoading = false;
  bool _timerStarted = false;
  bool _isLoadingSuggestion = false;

  int _hours = 1;
  int _minutes = 0;
  int _suggestionRequest = 0;

  DateTime? _customStartTime;
  Color _selectedColor = Colors.green;

  SmartHelperResult? _suggestion;

  final List<String> _categories = [
    'Studying',
    'Work',
    'Break',
    'Personal',
    'Sleep',
  ];

  final List<Color> _colors = [
    Colors.green,
    Colors.purple,
    Colors.red,
    Colors.amber,
  ];

  bool get _isEditing => widget.activityId != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _loadActivity();
    }
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoading = true);

    try {
      final database = DatabaseHelper.instance;
      final activity = await database.getActivityById(widget.activityId!);

      if (activity == null) {
        if (!mounted) return;
        _showMessage('Activity not found.');
        Navigator.pop(context);
        return;
      }

      final categories = await database.getCategories();
      final categoryId = activity['category_id'] as int?;

      Map<String, Object?>? matchingCategory;

      for (final category in categories) {
        if (category['id'] == categoryId) {
          matchingCategory = category;
          break;
        }
      }

      final savedCategory = matchingCategory?['name']?.toString() ?? 'Personal';

      final savedColor = matchingCategory?['color'] as int?;

      final plannedMinutes = (activity['planned_duration_minutes'] as num?)
          ?.toInt();

      final startTime = DateTime.tryParse(
        activity['start_time']?.toString() ?? '',
      );

      final status = activity['status']?.toString() ?? 'planned';

      if (!mounted) return;

      setState(() {
        _nameController.text = activity['title']?.toString() ?? '';
        _notesController.text = activity['notes']?.toString() ?? '';

        if (!_categories.contains(savedCategory)) {
          _categories.add(savedCategory);
        }

        _category = savedCategory;

        if (savedColor != null) {
          _selectedColor = Color(savedColor);
        }

        _timed = plannedMinutes != null;
        _hours = (plannedMinutes ?? 60) ~/ 60;
        _minutes = (plannedMinutes ?? 60) % 60;

        _timerStarted = status != 'planned';

        _startNow = true;
        _customStartTime = startTime;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Could not load activity: $error');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Clear the previous suggestion when changing categories.
  void _changeCategory(String category) {
    setState(() {
      _category = category;
      _suggestion = null;
      _isLoadingSuggestion = false;
      _suggestionRequest++;
    });
  }

  // Get a duration suggestion using completed activities.
  Future<void> _loadSuggestion() async {
    if (_timerStarted || _isLoadingSuggestion) return;

    final requestedCategory = _category;
    final requestId = ++_suggestionRequest;

    setState(() {
      _isLoadingSuggestion = true;
      _suggestion = null;
    });

    try {
      final categories = await DatabaseHelper.instance.getCategories();

      final matches = categories.where(
        (category) => category['name'] == requestedCategory,
      );

      final int? categoryId = matches.isEmpty
          ? null
          : matches.first['id'] as int;

      SmartHelperResult result;

      if (categoryId == null) {
        result = SmartHelperResult(
          suggestedMinutes: 10,
          explanation:
              'There are no completed sessions for $requestedCategory '
              'yet, so 10 minutes is a starting suggestion.',
          hasEnoughHistory: false,
        );
      } else {
        result = await SmartHelper.suggestDuration(categoryId);
      }

      if (!mounted ||
          requestId != _suggestionRequest ||
          requestedCategory != _category) {
        return;
      }

      setState(() {
        _suggestion = result;
        _isLoadingSuggestion = false;
      });
    } catch (error) {
      if (!mounted || requestId != _suggestionRequest) return;

      setState(() {
        _suggestion = null;
        _isLoadingSuggestion = false;
      });

      _showMessage('Could not load suggestion: $error');
    }
  }

  // Only apply a suggestion when the user chooses to.
  void _applySuggestion() {
    if (_suggestion == null || _timerStarted) return;

    final suggestedMinutes = _suggestion!.suggestedMinutes;

    setState(() {
      _timed = true;
      _hours = suggestedMinutes ~/ 60;
      _minutes = suggestedMinutes % 60;
    });

    _showMessage('Duration updated. You can still change it.');
  }

  Future<void> _chooseCustomStartTime() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _customStartTime ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_customStartTime ?? now),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _customStartTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      _startNow = false;
    });
  }

  Future<void> _saveActivity() async {
    final activityName = _nameController.text.trim();

    if (activityName.isEmpty) {
      _showMessage('Enter an activity name');
      return;
    }

    final plannedMinutes = (_hours * 60) + _minutes;

    if (!_timerStarted && _timed && plannedMinutes == 0) {
      _showMessage('Choose a duration');
      return;
    }

    if (!_timerStarted && !_startNow && _customStartTime == null) {
      _showMessage('Choose a custom start time');
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final database = DatabaseHelper.instance;
      final categories = await database.getCategories();

      final matchingCategories = categories.where(
        (category) => category['name'] == _category,
      );

      int categoryId;

      if (matchingCategories.isNotEmpty) {
        categoryId = matchingCategories.first['id'] as int;

        await database.updateCategory(
          categoryId,
          _category,
          _selectedColor.toARGB32(),
        );
      } else {
        categoryId = await database.addCategory(
          _category,
          _selectedColor.toARGB32(),
        );
      }

      if (_isEditing) {
        final changes = <String, Object?>{
          'category_id': categoryId,
          'title': activityName,
          'notes': _notesController.text.trim(),
        };

        // Keep the timer history if the activity already started.
        if (!_timerStarted) {
          final startTime = _startNow ? DateTime.now() : _customStartTime!;

          changes.addAll({
            'start_time': startTime.toIso8601String(),
            'planned_duration_minutes': _timed ? plannedMinutes : null,
            'timer_type': _timed ? 'timed' : 'open',
          });
        }

        await database.updateActivity(widget.activityId!, changes);

        if (!mounted) return;

        _showMessage('Activity updated successfully!');
        Navigator.pop(context, true);
      } else {
        final startTime = _startNow ? DateTime.now() : _customStartTime!;

        final activity = <String, Object?>{
          'category_id': categoryId,
          'title': activityName,
          'start_time': startTime.toIso8601String(),
          'end_time': null,
          'duration_minutes': 0,
          'planned_duration_minutes': _timed ? plannedMinutes : null,
          'notes': _notesController.text.trim(),
          'timer_type': _timed ? 'timed' : 'open',
          'status': 'planned',
        };

        final activityId = await database.addActivity(activity);

        if (!mounted) return;

        if (activityId > 0) {
          _showMessage('Activity saved successfully!');

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityTimerScreen(activityId: activityId),
            ),
          );

          if (!mounted) return;

          _nameController.clear();
          _notesController.clear();

          setState(() {
            _category = 'Studying';
            _selectedColor = Colors.green;
            _timed = true;
            _startNow = true;
            _customStartTime = null;
            _hours = 1;
            _minutes = 0;
            _suggestion = null;
            _isLoadingSuggestion = false;
            _suggestionRequest++;
          });
        } else {
          _showMessage('Activity could not be saved.');
        }
      }
    } catch (error) {
      _showMessage('Error saving activity: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Activity' : 'Add / Edit Activity'),
        backgroundColor: Colors.green.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Name'),
            const SizedBox(height: 8),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Studying',
              ),
            ),

            const SizedBox(height: 20),
            const Text('Category'),

            DropdownButtonFormField<String>(
              key: ValueKey(_category),
              initialValue: _category,
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _changeCategory(value);
                }
              },
            ),

            const SizedBox(height: 20),
            const Text('Color'),
            const SizedBox(height: 10),

            Wrap(
              spacing: 12,
              children: _colors.map((color) {
                return InkWell(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  child: CircleAvatar(
                    backgroundColor: color,
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Local Smart Helper
            const Text(
              'Smart Helper',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Get a suggested session length based on your '
              'previously completed activities.',
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _timerStarted || _isLoadingSuggestion
                  ? null
                  : _loadSuggestion,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Get Duration Suggestion'),
            ),

            if (_isLoadingSuggestion) ...[
              const SizedBox(height: 12),
              const CircularProgressIndicator(),
            ],

            if (_suggestion != null && !_timerStarted) ...[
              const SizedBox(height: 12),

              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested Duration: '
                        '${_suggestion!.suggestedMinutes} minutes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(_suggestion!.explanation),

                      const SizedBox(height: 8),

                      const Text(
                        'This is only a suggestion, not a guarantee. '
                        'You can change the duration or use an open timer.',
                        style: TextStyle(fontSize: 12),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: _applySuggestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Apply ${_suggestion!.suggestedMinutes} Minutes',
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          setState(() => _suggestion = null);
                        },
                        child: const Text('Dismiss Suggestion'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_timerStarted) ...[
              const SizedBox(height: 8),
              const Text(
                'Suggestions are unavailable after the timer starts.',
                style: TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 24),
            const Text('Duration'),
            const SizedBox(height: 8),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Timed')),
                ButtonSegment(value: false, label: Text('Open Timer')),
              ],
              selected: {_timed},
              onSelectionChanged: _timerStarted
                  ? null
                  : (value) {
                      setState(() => _timed = value.first);
                    },
            ),

            if (_timed) ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('hours-$_hours'),
                      initialValue: _hours,
                      decoration: const InputDecoration(labelText: 'Hours'),
                      items: List.generate(13, (i) {
                        return DropdownMenuItem(value: i, child: Text('$i hr'));
                      }),
                      onChanged: _timerStarted
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _hours = value);
                              }
                            },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('minutes-$_minutes'),
                      initialValue: _minutes,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                      items: List.generate(60, (i) {
                        return DropdownMenuItem(
                          value: i,
                          child: Text('$i min'),
                        );
                      }),
                      onChanged: _timerStarted
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _minutes = value);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            if (!_timerStarted) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Now')),
                  ButtonSegment(value: false, label: Text('Custom')),
                ],
                selected: {_startNow},
                onSelectionChanged: (value) {
                  final useNow = value.first;

                  setState(() => _startNow = useNow);

                  if (!useNow) {
                    _chooseCustomStartTime();
                  }
                },
              ),

              if (!_startNow) ...[
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _chooseCustomStartTime,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _customStartTime == null
                        ? 'Choose date and time'
                        : 'Selected: ${_customStartTime!.month}/'
                              '${_customStartTime!.day}/'
                              '${_customStartTime!.year} '
                              '${TimeOfDay.fromDateTime(_customStartTime!).format(context)}',
                  ),
                ),
              ],
            ] else ...[
              const Text(
                'Timer settings are locked because this activity '
                'has already started.',
                style: TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 20),
            const Text('Notes (optional)'),
            const SizedBox(height: 8),

            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter notes...',
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
