import '../database/database_helper.dart';

// Stores the suggestion and the reason behind it.
class SmartHelperResult {
  final int suggestedMinutes;
  final String explanation;
  final bool hasEnoughHistory;

  const SmartHelperResult({
    required this.suggestedMinutes,
    required this.explanation,
    required this.hasEnoughHistory,
  });
}

class SmartHelper {
  // Suggest a duration using completed sessions in this category.
  static Future<SmartHelperResult> suggestDuration(int categoryId) async {
    final activities = await DatabaseHelper.instance
        .getRecentCompletedActivities(categoryId);

    // Fewer than 3 completed sessions means limited history.
    if (activities.length < 3) {
      return const SmartHelperResult(
        suggestedMinutes: 10,
        explanation:
            'Not enough completed sessions in this category yet. '
            'Try starting with 10 minutes.',
        hasEnoughHistory: false,
      );
    }

    // Sort the three recorded durations.
    final durations =
        activities
            .map((activity) => (activity['duration_minutes'] as num).toInt())
            .toList()
          ..sort();

    // The middle duration is the median.
    final median = durations[1];

    // Keep suggestions between 10 and 60 minutes.
    final suggestion = median.clamp(10, 60).toInt();

    return SmartHelperResult(
      suggestedMinutes: suggestion,
      explanation:
          'Your last 3 completed sessions were '
          '${durations.join(', ')} minutes. '
          'The suggested duration is $suggestion minutes.',
      hasEnoughHistory: true,
    );
  }

  // Simple comparison baseline from our proposal.
  static int baselineMinutes() {
    return 25;
  }
}
