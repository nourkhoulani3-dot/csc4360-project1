import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/activity_time.dart';

const moodFaces = ['😞', '🙁', '😐', '🙂', '😄'];
const moodNames = ['Very low', 'Low', 'Okay', 'Good', 'Great'];
String reflectionMood(Object? mood) => mood is int && mood >= 1 && mood <= 5
    ? moodFaces[mood - 1]
    : 'No mood selected';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key, required this.day});
  final DateTime day;
  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final _notes = TextEditingController();
  int? _mood;
  int? _id;
  bool _loading = true, _saving = false, _dirty = false;
  String? _error;
  static const _prompts = [
    'What went well today?',
    'Did someone do something kind for you?',
    'What is one small thing you appreciated?',
    'What would you like to do differently tomorrow?',
  ];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseHelper.instance.getReflections();
      final row = rows
          .where((r) => r['date'] == dateKey(widget.day))
          .firstOrNull;
      if (!mounted) return;
      setState(() {
        _notes.text = row?['notes']?.toString() ?? '';
        _mood = row?['mood'] as int?;
        _id = row?['id'] as int?;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load reflection.';
        });
      }
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _leave() {
    setState(() {
      _dirty = false;
      _saving = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DatabaseHelper.instance.saveReflection(
        dateKey(widget.day),
        _mood,
        _notes.text.trim(),
      );
      if (mounted) _leave();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save reflection. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this reflection?'),
        content: const Text('This removes the note and mood for this day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await DatabaseHelper.instance.deleteReflection(_id!);
      if (mounted) _leave();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete reflection.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && !_dirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || _saving) return;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave without saving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep writing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard == true && context.mounted) {
        setState(() => _dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(title: Text('Reflection • ${dateKey(widget.day)}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: TextButton(onPressed: _load, child: Text('$_error Retry')),
            )
          : AbsorbPointer(
              absorbing: _saving,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('How did your day feel? (optional)'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      5,
                      (i) => Semantics(
                        button: true,
                        selected: _mood == i + 1,
                        label: '${moodNames[i]} mood. Tap again to clear.',
                        child: ExcludeSemantics(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() {
                              _mood = _mood == i + 1 ? null : i + 1;
                              _dirty = true;
                            }),
                            child: AnimatedContainer(
                              duration: MediaQuery.of(context).disableAnimations
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              width: 88,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _mood == i + 1
                                    ? Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  width: _mood == i + 1 ? 2 : 1,
                                  color: _mood == i + 1
                                      ? Theme.of(context).colorScheme.tertiary
                                      : Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    moodFaces[i],
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    moodNames[i],
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_mood == i + 1)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Your journal'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notes,
                    minLines: 8,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() => _dirty = true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Write as much or as little as you like. Every kind of day is welcome.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Need a starting point? Tap a prompt to add it, or write freely.',
                  ),
                  ..._prompts.map(
                    (prompt) => TextButton(
                      onPressed: () {
                        _notes.text =
                            '${_notes.text}${_notes.text.isEmpty ? '' : '\n\n'}$prompt\n';
                        _notes.selection = TextSelection.collapsed(
                          offset: _notes.text.length,
                        );
                        _dirty = true;
                      },
                      child: Text(prompt),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _save,
                    child: Text(_saving ? 'Saving...' : 'Save reflection'),
                  ),
                  if (_id != null)
                    TextButton(
                      onPressed: _delete,
                      child: const Text('Delete reflection'),
                    ),
                ],
              ),
            ),
    ),
  );
}
