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

class DurationSuggestion {
  static SmartHelperResult fromDurations(List<int> recentMinutes) {
    final durations = recentMinutes.where((n) => n > 0).take(3).toList()
      ..sort();
    if (durations.length < 3) {
      return const SmartHelperResult(
        suggestedMinutes: 10,
        explanation: 'Fewer than three completed sessions in this category. Try 10 minutes.',
        hasEnoughHistory: false,
      );
    }
    final suggestion = durations[1].clamp(10, 60).toInt();
    return SmartHelperResult(
      suggestedMinutes: suggestion,
      explanation:
          'Your recent sessions lasted ${durations.join(', ')} minutes. '
          'The middle duration, limited to 10-60 minutes, suggests $suggestion minutes.',
      hasEnoughHistory: true,
    );
  }
}
