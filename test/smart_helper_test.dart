import 'package:flutter_test/flutter_test.dart';
import 'package:plot/services/smart_helper.dart';

void main() {
  test('No history: fallback 10, baseline 25, explanation', () {
    final result = SmartHelper.fromDurations([]);
    expect(result.suggestedMinutes, 10);
    expect(result.hasEnoughHistory, isFalse);
    expect(result.explanation, contains('Fewer than three'));
    expect(SmartHelper.baselineMinutes(), 25);
  });
  test('One or two sessions still use fallback', () {
    for (final values in [
      [45],
      [15, 45],
    ]) {
      expect(SmartHelper.fromDurations(values).suggestedMinutes, 10);
    }
  });
  test('Normal history uses median instead of outlier-sensitive mean', () {
    final result = SmartHelper.fromDurations([15, 20, 45]);
    expect(result.suggestedMinutes, 20);
    expect(result.explanation, contains('15, 20, 45'));
  });
  test('Extreme sessions clamp to bounds', () {
    expect(SmartHelper.fromDurations([1, 2, 3]).suggestedMinutes, 10);
    expect(SmartHelper.fromDurations([90, 120, 180]).suggestedMinutes, 60);
    expect(SmartHelper.fromDurations([0, 0, 0]).suggestedMinutes, 10);
  });
  test('Counterexample: history cannot know todays available time', () {
    final result = SmartHelper.fromDurations([40, 45, 50]);
    expect(result.suggestedMinutes, 45);
    // The UI override still requires a device interaction test.
    expect(result.suggestedMinutes > 10, isTrue);
    expect(SmartHelper.baselineMinutes(), 25);
  });
}
