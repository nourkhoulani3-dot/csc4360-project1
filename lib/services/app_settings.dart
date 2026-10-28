import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Holds preferences and tells the UI when they change.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._preferences);

  final SharedPreferences _preferences;

  bool get darkMode => _preferences.getBool('darkMode') ?? false;

  int get defaultMinutes {
    final value = _preferences.getInt('defaultMinutes') ?? 25;
    return value >= 5 && value <= 180 && value % 5 == 0 ? value : 25;
  }

  bool get animationsEnabled =>
      _preferences.getBool('animationsEnabled') ?? true;

  bool suggestionsEnabledFor(int categoryId) =>
      _preferences.getBool('helper_category_$categoryId') ?? true;

  Future<void> setSuggestionsEnabledFor(int categoryId, bool value) async {
    if (!await _preferences.setBool('helper_category_$categoryId', value)) {
      throw Exception('Could not save suggestion preference.');
    }
    notifyListeners();
  }

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  // Load saved preferences before displaying the app.
  static Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSettings._(preferences);
  }

  Future<void> setDarkMode(bool value) async {
    final saved = await _preferences.setBool('darkMode', value);
    if (!saved) {
      throw Exception('Could not save theme.');
    }
    notifyListeners();
  }

  Future<void> setDefaultMinutes(int value) async {
    if (value < 5 || value > 180 || value % 5 != 0) {
      throw ArgumentError('Choose between 5 and 180 minutes.');
    }

    final saved = await _preferences.setInt('defaultMinutes', value);

    if (!saved) {
      throw Exception('Could not save default duration.');
    }
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool value) async {
    final saved = await _preferences.setBool('animationsEnabled', value);

    if (!saved) {
      throw Exception('Could not save animation preference.');
    }
    notifyListeners();
  }
}
