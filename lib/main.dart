import 'package:flutter/material.dart';

import 'screens/activity_form_screen.dart';
import 'screens/saved_activities_screen.dart';

void main() {
  runApp(const PlotApp());
}

class PlotApp extends StatelessWidget {
  const PlotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PlotHomeScreen(),
    );
  }
}

class PlotHomeScreen extends StatelessWidget {
  const PlotHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plot'),
        backgroundColor: Colors.green.shade100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavedActivitiesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Saved Activities'),
            ),
          ],
        ),
      ),
    );
  }
}
