import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'activity_timer_screen.dart';

class SavedActivitiesScreen extends StatefulWidget {
  const SavedActivitiesScreen({super.key});

  @override
  State<SavedActivitiesScreen> createState() => _SavedActivitiesScreenState();
}

class _SavedActivitiesScreenState extends State<SavedActivitiesScreen> {
  late Future<List<Map<String, Object?>>> _activities;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _activities = DatabaseHelper.instance.getActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Activities'),
        backgroundColor: Colors.green.shade100,
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _activities,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load activities: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data!;

          if (activities.isEmpty) {
            return const Center(child: Text('No saved activities yet.'));
          }

          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final id = activity['id'] as int;
              final title = activity['title']?.toString() ?? 'Activity';
              final status = activity['status']?.toString() ?? 'planned';

              return ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(title),
                subtitle: Text('Status: $status'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityTimerScreen(activityId: id),
                    ),
                  );

                  if (context.mounted) {
                    _refresh();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
