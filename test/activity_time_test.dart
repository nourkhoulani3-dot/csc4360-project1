import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plot/services/activity_time.dart';

Map<String, Object?> record(List<List<String>> intervals) => {
  'status': 'completed',
  'active_intervals': jsonEncode(
    intervals.map((p) => {'start': p[0], 'end': p[1]}).toList(),
  ),
};
void main() {
  test('Midnight splits display time without duplicating records', () {
    final row = record([
      ['2026-10-27T23:30:00', '2026-10-28T01:00:00'],
    ]);
    expect(
      periodsOnDay(row, DateTime(2026, 10, 27)).single.duration.inMinutes,
      30,
    );
    expect(
      periodsOnDay(row, DateTime(2026, 10, 28)).single.duration.inMinutes,
      60,
    );
  });
  test('Paused intervals remain unlogged', () {
    final row = record([
      ['2026-10-28T10:00:00', '2026-10-28T10:10:00'],
      ['2026-10-28T10:20:00', '2026-10-28T10:30:00'],
    ]);
    final periods = activityPeriods(row);
    expect(periods.fold<int>(0, (sum, p) => sum + p.duration.inMinutes), 20);
    expect(
      periods.any(
        (p) => periodsOverlap(
          p,
          ActivePeriod(
            DateTime(2026, 10, 28, 10, 12),
            DateTime(2026, 10, 28, 10, 18),
          ),
        ),
      ),
      isFalse,
    );
  });
  test('Running timer recovers elapsed period from persisted timestamp', () {
    final periods = activityPeriods({
      'status': 'running',
      'active_intervals': '[]',
      'timer_resumed_at': '2026-10-28T10:00:00',
    }, now: DateTime(2026, 10, 28, 10, 45));
    expect(periods.single.duration.inMinutes, 45);
  });
  test('Touching endpoints are allowed but intersecting intervals overlap', () {
    final a = ActivePeriod(
      DateTime(2026, 10, 28, 10),
      DateTime(2026, 10, 28, 11),
    );
    expect(
      periodsOverlap(a, ActivePeriod(a.end, DateTime(2026, 10, 28, 12))),
      isFalse,
    );
    expect(
      periodsOverlap(a, ActivePeriod(DateTime(2026, 10, 28, 10, 30), a.end)),
      isTrue,
    );
  });
}
