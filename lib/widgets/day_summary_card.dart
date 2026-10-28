import 'package:flutter/material.dart';

import '../services/activity_time.dart';

class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({
    super.key,
    required this.day,
    required this.total,
    required this.count,
    required this.segments,
    required this.onAdd,
  });
  final DateTime day;
  final Duration total;
  final int count;
  final List<({ActivePeriod period, Color color})> segments;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.tertiaryContainer],
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: colors.onPrimaryContainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MAKE ROOM FOR YOUR DAY',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Your day,\nin color.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onPrimaryContainer,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _stat(
                  context,
                  Icons.schedule,
                  '${recordedDuration(total)} recorded',
                ),
                _stat(
                  context,
                  Icons.layers_outlined,
                  '$count ${count == 1 ? 'activity' : 'activities'}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Semantics(
              label: '24-hour overview. Category colors show recorded activity times. Details are listed below.',
              child: ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 18,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _DayPainter(
                        day,
                        segments,
                        colors.onPrimaryContainer.withValues(alpha: .12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00'),
                Text('06'),
                Text('12'),
                Text('18'),
                Text('24'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              count == 0
                  ? 'A fresh canvas. Start with one activity.'
                  : 'Every block is part of your bigger picture.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add activity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .65),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 7), Text(label)],
    ),
  );
}

class _DayPainter extends CustomPainter {
  _DayPainter(this.day, this.segments, this.background);
  final DateTime day;
  final List<({ActivePeriod period, Color color})> segments;
  final Color background;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    final length = end.difference(start).inMilliseconds;
    for (final segment in segments) {
      final left =
          (segment.period.start.difference(start).inMilliseconds / length)
              .clamp(0.0, 1.0)
              .toDouble();
      final right =
          (segment.period.end.difference(start).inMilliseconds / length).clamp(
            0.0,
            1.0,
          );
      canvas.drawRect(
        Rect.fromLTRB(left * size.width, 0, right * size.width, size.height),
        Paint()..color = segment.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DayPainter oldDelegate) => true;
}
