import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saving = false;

  // Prevent repeated saves and show feedback if saving fails.
  Future<void> _save(Future<void> Function() update) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await update();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your setting. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, child) {
        final settings = widget.settings;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: const Text('Use a darker app appearance.'),
                value: settings.darkMode,
                onChanged: _saving
                    ? null
                    : (value) => _save(() => settings.setDarkMode(value)),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: DropdownButtonFormField<int>(
                  key: ValueKey(settings.defaultMinutes),
                  initialValue: settings.defaultMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Default session length',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(36, (index) {
                    final minutes = (index + 1) * 5;
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes minutes'),
                    );
                  }),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            _save(() => settings.setDefaultMinutes(value));
                          }
                        },
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Animations'),
                subtitle: const Text('Allow optional visual animations.'),
                value: settings.animationsEnabled,
                onChanged: _saving
                    ? null
                    : (value) =>
                          _save(() => settings.setAnimationsEnabled(value)),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Manage categories'),
                subtitle: const Text(
                  'Add, rename, recolor, or delete a category.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
              if (_saving) const LinearProgressIndicator(),
            ],
          ),
        );
      },
    );
  }
}
