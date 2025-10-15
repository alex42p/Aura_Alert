import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings.title': 'Settings',
      'settings.dark_mode': 'Dark Mode',
      'settings.font_size': 'Font Size',
      'settings.language': 'Language',
      'settings.back': 'Back',
      'app.title': 'Aura Alert',
      'dashboard.title': 'Aura Alert Dashboard',
      'chart.hr': 'Heart Rate (BPM)',
      'chart.temp': 'Skin Temperature (°C)',
      'chart.o2': 'O₂ Level (%)',
      'chart.no_data': 'No data',
    },
    'es': {
      'settings.title': 'Ajustes',
      'settings.dark_mode': 'Modo oscuro',
      'settings.font_size': 'Tamaño de fuente',
      'settings.language': 'Idioma',
      'settings.back': 'Atrás',
      'app.title': 'Aura Alert',
      'dashboard.title': 'Panel de Aura Alert',
      'chart.hr': 'Frecuencia cardíaca (BPM)',
      'chart.temp': 'Temperatura de la piel (°C)',
      'chart.o2': 'Nivel de O₂ (%)',
      'chart.no_data': 'Sin datos',
    },
    'fr': {
      'settings.title': 'Paramètres',
      'settings.dark_mode': 'Mode sombre',
      'settings.font_size': 'Taille de la police',
      'settings.language': 'Langue',
      'settings.back': 'Retour',
      'app.title': 'Aura Alert',
      'dashboard.title': 'Tableau de bord Aura Alert',
      'chart.hr': 'Fréquence cardiaque (BPM)',
      'chart.temp': 'Température de la peau (°C)',
      'chart.o2': 'Taux d\'O₂ (%)',
      'chart.no_data': 'Pas de données',
    },
    'de': {
      'settings.title': 'Einstellungen',
      'settings.dark_mode': 'Dunkler Modus',
      'settings.font_size': 'Schriftgröße',
      'settings.language': 'Sprache',
      'settings.back': 'Zurück',
      'app.title': 'Aura Alert',
      'dashboard.title': 'Aura Alert Übersicht',
      'chart.hr': 'Herzfrequenz (BPM)',
      'chart.temp': 'Hauttemperatur (°C)',
      'chart.o2': 'O₂-Wert (%)',
      'chart.no_data': 'Keine Daten',
    },
  };

  String t(String key) {
    final code = locale.languageCode;
    return _localizedValues[code]?[key] ?? _localizedValues['en']![key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations._localizedValues.keys.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    // For simplicity this is synchronous
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
