import 'dart:convert';

// Saved intervals are the periods actually spent on an activity, not its pauses.
class ActivePeriod {
  const ActivePeriod(this.start, this.end);
  final DateTime start;
  final DateTime end;
  Duration get duration => end.difference(start);
}

List<ActivePeriod> activityPeriods(Map<String, Object?> row, {DateTime? now}) {
  final result = <ActivePeriod>[];
  final encoded = row['active_intervals']?.toString();
  if (encoded != null) {
    final values = jsonDecode(encoded) as List<dynamic>;
    for (final value in values) {
      final pair = value as Map<String, dynamic>;
      final start = DateTime.parse(pair['start'] as String).toLocal();
      final end = DateTime.parse(pair['end'] as String).toLocal();
      if (end.isAfter(start)) result.add(ActivePeriod(start, end));
    }
  } else if (row['status'] != 'planned') {
    // Old records have no exact pause positions. Display an estimated interval.
    final start = DateTime.tryParse(row['start_time']?.toString() ?? '');
    final seconds = (row['elapsed_seconds'] as num?)?.toInt() ?? 0;
    final minutes = (row['duration_minutes'] as num?)?.toInt() ?? 0;
    if (start != null) {
      final duration = Duration(seconds: seconds > 0 ? seconds : minutes * 60);
      if (duration > Duration.zero) {
        result.add(
          ActivePeriod(start.toLocal(), start.toLocal().add(duration)),
        );
      }
    }
  }
  if (row['status'] == 'running') {
    final start = DateTime.tryParse(row['timer_resumed_at']?.toString() ?? '');
    final end = now ?? DateTime.now();
    if (start != null && end.isAfter(start)) {
      result.add(ActivePeriod(start.toLocal(), end.toLocal()));
    }
  }
  return result;
}

List<ActivePeriod> periodsOnDay(
  Map<String, Object?> row,
  DateTime day, {
  DateTime? now,
}) {
  final start = DateTime(day.year, day.month, day.day);
  final end = DateTime(day.year, day.month, day.day + 1);
  return activityPeriods(row, now: now).expand((period) {
    final left = period.start.isBefore(start) ? start : period.start;
    final right = period.end.isAfter(end) ? end : period.end;
    return right.isAfter(left) ? [ActivePeriod(left, right)] : <ActivePeriod>[];
  }).toList();
}

bool periodsOverlap(ActivePeriod a, ActivePeriod b) =>
    a.start.isBefore(b.end) && b.start.isBefore(a.end);

String dateKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

String recordedDuration(Duration value) {
  final seconds = value.inSeconds;
  if (seconds < 60) return '$seconds sec';
  final minutes = value.inMinutes;
  return minutes < 60
      ? '$minutes min'
      : '${minutes ~/ 60} hr ${minutes % 60} min';
}
