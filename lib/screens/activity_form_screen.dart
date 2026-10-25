import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'activity_timer_screen.dart';

class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({super.key});

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

  int _hours = 1;
  int _minutes = 0;

  DateTime? _customStartTime;
  Color _selectedColor = Colors.green;

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

  // Let the user select a custom date and time.
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

  // Save the activity to SQLite and open its timer.
  Future<void> _saveActivity() async {
    final activityName = _nameController.text.trim();

    if (activityName.isEmpty) {
      _showMessage('Enter an activity name');
      return;
    }

    final plannedMinutes = (_hours * 60) + _minutes;

    if (_timed && plannedMinutes == 0) {
      _showMessage('Choose a duration');
      return;
    }

    if (!_startNow && _customStartTime == null) {
      _showMessage('Choose a custom start time');
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final database = DatabaseHelper.instance;

      // Find the selected category in SQLite.
      final categories = await database.getCategories();

      final matchingCategories = categories.where(
        (category) => category['name'] == _category,
      );

      int categoryId;

      if (matchingCategories.isNotEmpty) {
        categoryId = matchingCategories.first['id'] as int;

        // Update the selected category color.
        await database.updateCategory(
          categoryId,
          _category,
          _selectedColor.toARGB32(),
        );
      } else {
        // Create the category if it doesn't exist.
        categoryId = await database.addCategory(
          _category,
          _selectedColor.toARGB32(),
        );
      }

      final startTime = _startNow ? DateTime.now() : _customStartTime!;

      // Save the activity as planned until the timer starts.
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

        // Open the timer for the activity we just saved.
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityTimerScreen(activityId: activityId),
          ),
        );

        if (!mounted) return;

        // Reset the form when returning from the timer.
        _nameController.clear();
        _notesController.clear();

        setState(() {
          _timed = true;
          _startNow = true;
          _customStartTime = null;
          _hours = 1;
          _minutes = 0;
        });
      } else {
        _showMessage('Activity could not be saved.');
      }
    } catch (error) {
      _showMessage('Error saving activity: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add / Edit Activity'),
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
              initialValue: _category,
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _category = value;
                  });
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
                    setState(() {
                      _selectedColor = color;
                    });
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

            const Text('Duration'),
            const SizedBox(height: 8),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Timed')),
                ButtonSegment(value: false, label: Text('Open Timer')),
              ],
              selected: {_timed},
              onSelectionChanged: (value) {
                setState(() {
                  _timed = value.first;
                });
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
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _hours = value;
                          });
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
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _minutes = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Now')),
                ButtonSegment(value: false, label: Text('Custom')),
              ],
              selected: {_startNow},
              onSelectionChanged: (value) {
                final useNow = value.first;

                setState(() {
                  _startNow = useNow;
                });

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
                        : const Text('Save'),
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
