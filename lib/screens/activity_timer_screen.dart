import 'dart:async';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class ActivityTimerScreen extends StatefulWidget {
  const ActivityTimerScreen({super.key, required this.activityId});

  final int activityId;

  @override
  State<ActivityTimerScreen> createState() => _ActivityTimerScreenState();
}

class _ActivityTimerScreenState extends State<ActivityTimerScreen> {
  Timer? _timer;

  Map<String, Object?>? _activity;

  DateTime? _startedAt;
  DateTime? _resumedAt;

  // Saved elapsed time, excluding the current running segment.
  Duration _elapsed = Duration.zero;

  bool _loading = true;
  bool _running = false;
  bool _finished = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Duration get _currentElapsed {
    if (!_running || _resumedAt == null) {
      return _elapsed;
    }

    final extra = DateTime.now().difference(_resumedAt!);
    return _elapsed + (extra.isNegative ? Duration.zero : extra);
  }

  Future<void> _loadActivity() async {
    try {
      final activity = await DatabaseHelper.instance.getActivityById(
        widget.activityId,
      );

      if (!mounted) return;

      if (activity == null) {
        setState(() => _loading = false);
        return;
      }

      final status = activity['status']?.toString() ?? 'planned';
      final savedSeconds = (activity['elapsed_seconds'] as num?)?.toInt() ?? 0;

      DateTime? startedAt;
      DateTime? resumedAt;

      final savedStart = activity['timer_started_at']?.toString();
      final savedResume = activity['timer_resumed_at']?.toString();

      if (savedStart != null) {
        startedAt = DateTime.tryParse(savedStart);
      }

      if (savedResume != null) {
        resumedAt = DateTime.tryParse(savedResume);
      }

      // Recover older completed records as well.
      if (status == 'completed' && savedSeconds == 0) {
        final minutes = (activity['duration_minutes'] as num?)?.toInt() ?? 0;

        _elapsed = Duration(minutes: minutes);
      } else {
        _elapsed = Duration(seconds: savedSeconds);
      }

      setState(() {
        _activity = activity;
        _startedAt = startedAt;
        _resumedAt = resumedAt;
        _running = status == 'running' && resumedAt != null;
        _finished = status == 'completed';
        _loading = false;
      });

      if (_running) {
        _startTicker();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('Could not load activity: $error');
    }
  }

  void _startTicker() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _running) {
        setState(() {});
      }
    });
  }

  Future<void> _action(String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await DatabaseHelper.instance.changeTimer(widget.activityId, action);
      _timer?.cancel();
      await _loadActivity();
      if (action == 'finish' && mounted) {
        _message('Activity finished and saved.');
      }
    } catch (error) {
      _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _action('start');
  Future<void> _pause() => _action('pause');
  Future<void> _finish() => _action('finish');

  Future<void> _reset() async {
    if (_busy || _finished) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset timer?'),
        content: const Text(
          'Clear this session? Completed history stays saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _action('reset');
  }

  String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;

    final hours = safe.inHours.toString().padLeft(2, '0');
    final minutes = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_activity == null) {
      return const Scaffold(body: Center(child: Text('Activity not found.')));
    }

    final title = _activity!['title']?.toString() ?? 'Activity';

    final plannedMinutes = (_activity!['planned_duration_minutes'] as num?)
        ?.toInt();

    final isTimed = plannedMinutes != null && plannedMinutes > 0;

    final elapsed = _currentElapsed;

    final plannedDuration = Duration(minutes: plannedMinutes ?? 0);

    final remaining = isTimed ? plannedDuration - elapsed : Duration.zero;

    final progress = isTimed
        ? (elapsed.inMilliseconds / plannedDuration.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble()
        : null;

    final displayDuration = isTimed
        ? (remaining.isNegative ? Duration.zero : remaining)
        : elapsed;

    final status = _finished
        ? 'Completed'
        : _running
        ? 'Running'
        : _startedAt == null
        ? 'Ready to start'
        : 'Paused';

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Timer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 28),

              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                isTimed ? 'Planned: $plannedMinutes minutes' : 'Open Timer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 48),

              // Keep the circular timer from your wireframe.
              Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: isTimed
                              ? progress
                              : _finished
                              ? 1.0
                              : 0.0,
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,

                          valueColor: AlwaysStoppedAnimation<Color>(
                            _finished ? Colors.green.shade700 : Colors.green,
                          ),
                        ),
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatDuration(displayDuration),
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            isTimed ? 'Remaining' : 'Elapsed',
                            style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              if (isTimed)
                Text(
                  '${(progress! * 100).round()}% of goal - active time: ${_formatDuration(elapsed)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

              if (isTimed)
                const Text(
                  'Tracking continues after the goal until you tap Finish.',
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 36),

              if (!_finished)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _busy || _running ? null : _start,
                      icon: Icon(
                        _startedAt == null
                            ? Icons.play_arrow
                            : Icons.play_circle,
                      ),
                      label: Text(_startedAt == null ? 'Start' : 'Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),

                    OutlinedButton.icon(
                      onPressed: _busy || !_running ? null : _pause,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    ),

                    OutlinedButton.icon(
                      onPressed: _busy || _startedAt == null ? null : _finish,
                      icon: const Icon(Icons.check),
                      label: const Text('Finish'),
                    ),

                    TextButton.icon(
                      onPressed: _busy || _startedAt == null ? null : _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),

              AnimatedSwitcher(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                child: !_finished
                    ? const SizedBox.shrink()
                    : const Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: Colors.green,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Activity completed!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
