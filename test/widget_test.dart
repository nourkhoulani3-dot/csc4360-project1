import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plot/services/app_settings.dart';
import 'package:plot/screens/settings_screen.dart';

void main() {
  testWidgets('Dark mode can be changed and reloaded', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(settings: settings)),
    );
    expect(settings.darkMode, isFalse);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Dark mode'));
    await tester.pumpAndSettle();
    expect(settings.darkMode, isTrue);
    final reloaded = await AppSettings.load();
    expect(reloaded.darkMode, isTrue);
    settings.dispose();
    reloaded.dispose();
  });
  test('Default duration rejects values outside selectable steps', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    await expectLater(settings.setDefaultMinutes(3), throwsArgumentError);
    await expectLater(settings.setDefaultMinutes(17), throwsArgumentError);
    await settings.setDefaultMinutes(40);
    expect((await AppSettings.load()).defaultMinutes, 40);
    settings.dispose();
  });
}
