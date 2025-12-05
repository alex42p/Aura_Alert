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
      'dashboard.title': 'Aura Alert',
      'chart.hr': 'Heart Rate (BPM)',
      'chart.temp': 'Skin Temperature (°C)',
      'chart.o2': 'O₂ Level (%)',
      'chart.no_data': 'No data',
      'settings.bluetooth_device': 'Bluetooth Device',
      'settings.bluetooth_choose': 'Choose',
      'settings.bluetooth_not_connected': 'Not connected',
      'settings.bluetooth_stop_scan': 'Stop scan',
      'chart.range.24h': '24h',
      'chart.range.1w': '1w',
      'chart.range.1m': '1m',
      'chart.range.all': 'All',
      'menu.settings': 'Settings',
      'menu.export': 'Export',
      'menu.delete': 'Delete',
      'tooltip.send_test_notification': 'Send test notification',
      'notification.test_message': 'Triggered test notification',
      'tooltip.notifications': 'Notifications',
      'tooltip.add_dummy': 'Add dummy data',
      'db.inserted_rows': 'Inserted {count} rows',
      'db.insert_failed': 'Insert failed: {error}',
      'export.success': 'Exported CSV to: {path}',
      'export.canceled': 'Share canceled by user.',
      'export.unavailable': 'Sharing not available.',
      'export.failed': 'Export failed: {error}',
      'dialog.confirm_delete_title': 'Confirm delete',
      'dialog.confirm_delete_content': 'Delete all readings from the local database? This cannot be undone.',
      'dialog.cancel': 'Cancel',
      'dialog.delete': 'Delete',
      'snackbar.all_readings_deleted': 'All readings deleted',
      'email.subject': 'Aura Alert Data Export',
      'email.body': 'Your scanned biometric data has been turned into a CSV file for your convenience!'
    },
    'es': {
      'settings.title': 'Ajustes',
      'settings.dark_mode': 'Modo oscuro',
      'settings.font_size': 'Tamaño de fuente',
      'settings.language': 'Idioma',
      'settings.back': 'Atrás',
      'app.title': 'Aura Alert',
      'dashboard.title': 'Aura Alert',
      'chart.hr': 'Frecuencia cardíaca (BPM)',
      'chart.temp': 'Temperatura de la piel (°C)',
      'chart.o2': 'Nivel de O₂ (%)',
      'chart.no_data': 'Sin datos',
      'settings.bluetooth_device': 'Dispositivo Bluetooth',
      'settings.bluetooth_choose': 'Elegir',
      'settings.bluetooth_not_connected': 'No conectado',
      'settings.bluetooth_stop_scan': 'Detener búsqueda',
      'chart.range.24h': '24h',
      'chart.range.1w': '1s',
      'chart.range.1m': '1m',
      'chart.range.all': 'Todos',
      'menu.settings': 'Ajustes',
      'menu.export': 'Exportar',
      'menu.delete': 'Eliminar',
      'tooltip.send_test_notification': 'Enviar notificación de prueba',
      'notification.test_message': 'Notificación de prueba activada',
      'tooltip.notifications': 'Notificaciones',
      'tooltip.add_dummy': 'Agregar datos de ejemplo',
      'db.inserted_rows': 'Insertadas {count} filas',
      'db.insert_failed': 'Inserción fallida: {error}',
      'export.success': 'CSV exportado a: {path}',
      'export.canceled': 'Compartir cancelado por el usuario.',
      'export.unavailable': 'Compartir no disponible.',
      'export.failed': 'Exportación fallida: {error}',
      'dialog.confirm_delete_title': 'Confirmar eliminación',
      'dialog.confirm_delete_content': '¿Eliminar todas las lecturas de la base de datos local? Esto no se puede deshacer.',
      'dialog.cancel': 'Cancelar',
      'dialog.delete': 'Eliminar',
      'snackbar.all_readings_deleted': 'Todas las lecturas eliminadas',
      'email.subject': 'Aura Alert Exportación de Datos',
      'email.body': 'Tus datos biométricos escaneados se han convertido en un archivo CSV para tu conveniencia.'
    },
    'fr': {
      'settings.title': 'Paramètres',
      'settings.dark_mode': 'Mode sombre',
      'settings.font_size': 'Taille de la police',
      'settings.language': 'Langue',
      'settings.back': 'Retour',
      'app.title': 'Aura Alert',
      'dashboard.title': 'Aura Alert',
      'chart.hr': 'Fréquence cardiaque (BPM)',
      'chart.temp': 'Température de la peau (°C)',
      'chart.o2': 'Taux d\'O₂ (%)',
      'chart.no_data': 'Pas de données',
      'settings.bluetooth_device': 'Appareil Bluetooth',
      'settings.bluetooth_choose': 'Choisir',
      'settings.bluetooth_not_connected': 'Non connecté',
      'settings.bluetooth_stop_scan': 'Arrêter la recherche',
      'chart.range.24h': '24h',
      'chart.range.1w': '1s',
      'chart.range.1m': '1m',
      'chart.range.all': 'Tout',
      'menu.settings': 'Paramètres',
      'menu.export': 'Exporter',
      'menu.delete': 'Supprimer',
      'tooltip.send_test_notification': 'Envoyer une notification de test',
      'notification.test_message': 'Notification de test déclenchée',
      'tooltip.notifications': 'Notifications',
      'tooltip.add_dummy': 'Ajouter des données factices',
      'db.inserted_rows': '{count} lignes insérées',
      'db.insert_failed': 'Échec de l\'insertion: {error}',
      'export.success': 'CSV exporté vers : {path}',
      'export.canceled': 'Partage annulé par l\'utilisateur.',
      'export.unavailable': 'Partage non disponible.',
      'export.failed': 'Échec de l\'exportation : {error}',
      'dialog.confirm_delete_title': 'Confirmer la suppression',
      'dialog.confirm_delete_content': 'Supprimer toutes les lectures de la base de données locale ? Cela ne peut pas être annulé.',
      'dialog.cancel': 'Annuler',
      'dialog.delete': 'Supprimer',
      'snackbar.all_readings_deleted': 'Toutes les lectures supprimées',
      'email.subject': 'Aura Alert Exportation de Données',
      'email.body': 'Vos données biométriques scannées ont été converties en fichier CSV pour votre commodité.'
    },
    'de': {
      'settings.title': 'Einstellungen',
      'settings.dark_mode': 'Dunkler Modus',
      'settings.font_size': 'Schriftgröße',
      'settings.language': 'Sprache',
      'settings.back': 'Zurück',
      'app.title': 'Aura Alert',
      'dashboard.title': 'Aura Alert',
      'chart.hr': 'Herzfrequenz (BPM)',
      'chart.temp': 'Hauttemperatur (°C)',
      'chart.o2': 'O₂-Wert (%)',
      'chart.no_data': 'Keine Daten',
      'settings.bluetooth_device': 'Bluetooth-Gerät',
      'settings.bluetooth_choose': 'Auswählen',
      'settings.bluetooth_not_connected': 'Nicht verbunden',
      'settings.bluetooth_stop_scan': 'Scan beenden',
      'chart.range.24h': '24h',
      'chart.range.1w': '1W',
      'chart.range.1m': '1M',
      'chart.range.all': 'Alle',
      'menu.settings': 'Einstellungen',
      'menu.export': 'Exportieren',
      'menu.delete': 'Löschen',
      'tooltip.send_test_notification': 'Testbenachrichtigung senden',
      'notification.test_message': 'Testbenachrichtigung ausgelöst',
      'tooltip.notifications': 'Benachrichtigungen',
      'tooltip.add_dummy': 'Dummy-Daten hinzufügen',
      'db.inserted_rows': '{count} Zeilen eingefügt',
      'db.insert_failed': 'Einfügen fehlgeschlagen: {error}',
      'export.success': 'CSV exportiert nach: {path}',
      'export.canceled': 'Teilen vom Benutzer abgebrochen.',
      'export.unavailable': 'Teilen nicht verfügbar.',
      'export.failed': 'Export fehlgeschlagen: {error}',
      'dialog.confirm_delete_title': 'Löschen bestätigen',
      'dialog.confirm_delete_content': 'Alle Messwerte aus der lokalen Datenbank löschen? Dies kann nicht rückgängig gemacht werden.',
      'dialog.cancel': 'Abbrechen',
      'dialog.delete': 'Löschen',
      'snackbar.all_readings_deleted': 'Alle Messwerte gelöscht',
      'email.subject': 'Aura Alert Datenexport',
      'email.body': 'Ihre gescannten biometrischen Daten wurden in eine CSV-Datei umgewandelt und stehen Ihnen zur Verfügung.'
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
