import 'package:flutter/material.dart';

import 'screens/today_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PlotApp());
}

class PlotApp extends StatefulWidget {
  const PlotApp({super.key});

  @override
  State<PlotApp> createState() => _PlotAppState();
}

class _PlotAppState extends State<PlotApp> {
  late Future<AppSettings> _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: _settings,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: snapshot.hasError
                    ? TextButton(
                        onPressed: () {
                          setState(() {
                            _settings = AppSettings.load();
                          });
                        },
                        child: const Text(
                          'Settings failed to load. Tap to retry.',
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          );
        }

        final settings = snapshot.data!;

        return AnimatedBuilder(
          animation: settings,
          builder: (context, child) {
            return MaterialApp(
              title: 'Plot',
              debugShowCheckedModeBanner: false,
              themeMode: settings.themeMode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.green,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              builder: (context, child) {
                final media = MediaQuery.of(context);

                return MediaQuery(
                  data: media.copyWith(
                    disableAnimations:
                        media.disableAnimations || !settings.animationsEnabled,
                  ),
                  child: child!,
                );
              },
              home: PlotHomeScreen(settings: settings),
            );
          },
        );
      },
    );
  }
}

class PlotHomeScreen extends StatefulWidget {
  const PlotHomeScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<PlotHomeScreen> createState() => _PlotHomeScreenState();
}

class _PlotHomeScreenState extends State<PlotHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_selectedTab) {
        0 => const TodayScreen(),
        1 => const HistoryScreen(),
        _ => SettingsScreen(settings: widget.settings),
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
