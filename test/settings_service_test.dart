import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:aura_alert/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // reset singleton internal state by reloading prefs in tests
      await SettingsService.instance.load();
    });

    test('default values and persistence', () async {
      final s = SettingsService.instance;
      expect(s.isDarkMode, false);
      expect(s.fontSize, 14.0);
      expect(s.locale, const Locale('en'));

      s.setDarkMode(true);
      s.setFontSize(18.0);
      s.setLocale(const Locale('fr'));

      // Give async prefs writes a moment
      await Future.delayed(const Duration(milliseconds: 50));

      // Make a fresh instance read from prefs
      await s.load();
      expect(s.isDarkMode, true);
      expect(s.fontSize, 18.0);
      expect(s.locale.languageCode, 'fr');
    });

    test('font clamping', () async {
      final s = SettingsService.instance;
      s.setFontSize(1000.0); // too large
      await Future.delayed(const Duration(milliseconds: 20));
      expect(s.fontSize <= 24.0, true);

      s.setFontSize(5.0); // too small
      await Future.delayed(const Duration(milliseconds: 20));
      expect(s.fontSize >= 10.0, true);
    });
  });
}
