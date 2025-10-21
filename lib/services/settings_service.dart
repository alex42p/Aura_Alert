import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._privateConstructor();
  static final SettingsService instance = SettingsService._privateConstructor();

  bool _isDarkMode = false;
  double _fontSize = 14.0;
  Locale _locale = const Locale('en');

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  Locale get locale => _locale;

  static const _KEY_DARK = 'settings.dark';
  static const _KEY_FONT = 'settings.font';
  static const _KEY_LOCALE = 'settings.locale';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _isDarkMode = p.getBool(_KEY_DARK) ?? _isDarkMode;
    _fontSize = p.getDouble(_KEY_FONT) ?? _fontSize;
    final lc = p.getString(_KEY_LOCALE);
    if (lc != null) _locale = Locale(lc);
    notifyListeners();
  }

  void setDarkMode(bool v) {
    if (_isDarkMode == v) return;
    _isDarkMode = v;
    SharedPreferences.getInstance().then((p) => p.setBool(_KEY_DARK, v));
    notifyListeners();
  }

  void setFontSize(double v) {
    // Enforce slider min/max bounds (10-24). If caller passes outside range, clamp to limits.
    final double minFont = 10.0;
    final double maxFont = 24.0;
    final double newV = v.clamp(minFont, maxFont);
    if (_fontSize == newV) return;
    _fontSize = newV;
    SharedPreferences.getInstance().then((p) => p.setDouble(_KEY_FONT, newV));
    notifyListeners();
  }

  void setLocale(Locale l) {
    if (_locale == l) return;
    _locale = l;
    SharedPreferences.getInstance().then((p) => p.setString(_KEY_LOCALE, l.languageCode));
    notifyListeners();
  }
}
