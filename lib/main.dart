import 'package:flutter/material.dart';

import 'screens/activity_form_screen.dart';
import 'screens/saved_activities_screen.dart';
import 'screens/history_screen.dart';

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

// Stateful because the selected tab changes.
class PlotHomeScreen extends StatefulWidget {
  const PlotHomeScreen({super.key});

  @override
  State<PlotHomeScreen> createState() => _PlotHomeScreenState();
}

class _PlotHomeScreenState extends State<PlotHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Build the selected screen when switching tabs.
      body: switch (_selectedTab) {
        0 => const TodayScreen(),
        1 => const HistoryScreen(),
        _ => const Scaffold(
            appBar: null,
            body: SafeArea(
              child: Center(
                child: Text('Settings — next step'),
              ),
            ),
          ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// We'll add your timeline and reflection here next.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  Future<void> _openScreen(
    BuildContext context,
    Widget screen,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plot • Today'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your day, in color.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Record an activity to start seeing where your time goes.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openScreen(
              context,
              const ActivityFormScreen(),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Activity'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openScreen(
              context,
              const SavedActivitiesScreen(),
            ),
            icon: const Icon(Icons.list_alt),
            label: const Text('Saved Activities'),
          ),
        ],
      ),
    );
  }
}