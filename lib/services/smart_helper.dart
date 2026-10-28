import '../database/database_helper.dart';
import 'duration_suggestion.dart';
export 'duration_suggestion.dart' show SmartHelperResult;

class SmartHelper {
  static SmartHelperResult fromDurations(List<int> minutes) =>
      DurationSuggestion.fromDurations(minutes);

  static Future<SmartHelperResult> suggestDuration(int categoryId) async {
    final rows = await DatabaseHelper.instance.getRecentCompletedActivities(
      categoryId,
    );
    return fromDurations(
      rows.map((r) => (r['duration_minutes'] as num).toInt()).toList(),
    );
  }

  static int baselineMinutes() => 25;
}
