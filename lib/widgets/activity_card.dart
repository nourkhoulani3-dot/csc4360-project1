import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/activity_time.dart';
import '../screens/activity_form_screen.dart';
import '../screens/activity_timer_screen.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.categories,
    required this.onChanged,
    this.period,
  });
  final Map<String, Object?> activity;
  final List<Map<String, Object?>> categories;
  final Future<void> Function() onChanged;
  final ActivePeriod? period;

  Future<void> _open(BuildContext context, bool edit) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => edit
            ? ActivityFormScreen(activityId: activity['id'] as int)
            : ActivityTimerScreen(activityId: activity['id'] as int),
      ),
    );
    await onChanged();
  }

  Future<void> _delete(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity?'),
        content: Text(
          'Delete "${activity['title']}" and its recorded time? This cannot be undone.',
        ),
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
    if (yes != true || !context.mounted) return;
    try {
      await DatabaseHelper.instance.deleteActivity(activity['id'] as int);
      await onChanged();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete activity. Please retry.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = categories
        .where((c) => c['id'] == activity['category_id'])
        .firstOrNull;
    final color = category == null
        ? Colors.grey
        : Color(category['color'] as int);
    final status = activity['status']?.toString() ?? 'completed';
    final duration =
        period?.duration ??
        activityPeriods(activity)
            .fold<Duration>(Duration.zero, (sum, p) => sum + p.duration);
    final time = period == null
        ? ''
        : '${TimeOfDay.fromDateTime(period!.start).format(context)} - ${TimeOfDay.fromDateTime(period!.end).format(context)}\n';
    final colors = Theme.of(context).colorScheme;
    final running = status == 'running';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Color.alphaBlend(
        color.withValues(alpha: running ? .20 : .09),
        colors.surface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: running ? color : colors.outlineVariant,
          width: running ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, status == 'completed'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (running)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              color: colors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'HAPPENING NOW',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      activity['title']?.toString() ?? 'Activity',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${category?['name'] ?? 'Uncategorized'} • ${recordedDuration(duration)}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    if (time.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          time.trim(),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'planned'
                            ? 'Ready to start'
                            : status[0].toUpperCase() + status.substring(1),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Activity actions',
                onSelected: (value) {
                  if (value == 'delete') {
                    _delete(context);
                  } else {
                    _open(context, value == 'edit');
                  }
                },
                itemBuilder: (_) => [
                  if (status != 'completed')
                    const PopupMenuItem(
                      value: 'timer',
                      child: Text('Open timer'),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit activity'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete activity'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
