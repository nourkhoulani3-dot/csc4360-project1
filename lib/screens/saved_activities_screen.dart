import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'activity_form_screen.dart';
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

  Future<void> _openTimer(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActivityTimerScreen(activityId: id)),
    );

    if (mounted) _refresh();
  }

  Future<void> _editActivity(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActivityFormScreen(activityId: id)),
    );

    if (mounted) _refresh();
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
                onTap: () => _openTimer(id),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit activity',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editActivity(id),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
