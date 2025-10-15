import 'package:flutter/material.dart';

class SettingsService extends ChangeNotifier {
  // Singleton
  SettingsService._privateConstructor();
  static final SettingsService instance = SettingsService._privateConstructor();

  bool _isDarkMode = false;
  double _fontSize = 14.0;
  Locale _locale = const Locale('en');

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  Locale get locale => _locale;

  void setDarkMode(bool v) {
    if (_isDarkMode == v) return;
    _isDarkMode = v;
    notifyListeners();
  }

  void setFontSize(double v) {
    // Enforce slider min/max bounds (10-24). If caller passes outside range, clamp to limits.
    final double minFont = 10.0;
    final double maxFont = 24.0;
    final double newV = v.clamp(minFont, maxFont);
    if (_fontSize == newV) return;
    _fontSize = newV;
    notifyListeners();
  }

  void setLocale(Locale l) {
    if (_locale == l) return;
    _locale = l;
    notifyListeners();
  }
}
