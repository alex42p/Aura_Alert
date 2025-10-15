import 'package:flutter/material.dart';
import 'models/biometric_reading.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'widgets/biometric_chart.dart';
import 'pages/settings_page.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsService _settings = SettingsService.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final brightness = _settings.isDarkMode ? Brightness.dark : Brightness.light;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 59, 209, 246),
      brightness: brightness,
    );
    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: _settings.isDarkMode ? Colors.white : Colors.black,
          displayColor: _settings.isDarkMode ? Colors.white : Colors.black,
        ).copyWith(
          bodySmall: TextStyle(fontSize: _settings.fontSize),
          bodyMedium: TextStyle(fontSize: _settings.fontSize),
          bodyLarge: TextStyle(fontSize: _settings.fontSize + 2),
        );

    return MaterialApp(
      title: 'Aura Alert',
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es'), Locale('fr'), Locale('de')],
      theme: ThemeData(
        colorScheme: baseScheme,
        brightness: brightness,
        textTheme: textTheme,
      ),
      locale: _settings.locale,
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseService _db = DatabaseService();

  Future<List<BiometricReading>> _loader(String type, DateTime from, DateTime to) async {
    return await _db.queryReadings(type: type, from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 28, 88, 253),
        iconTheme: const IconThemeData(color: Colors.white),
  title: Text(AppLocalizations.of(context).t('dashboard.title')),
        actions: [
            PopupMenuButton<String>(
              // iconColor: Colors.black,
              onSelected: (v) {
                if (v == 'settings') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                }
                // other menu items can be handled here
                if (v == 'export') {
                  // export data as CSV
                }
                if (v == 'delete') {
                  // delete all data from database
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuItem(value: 'export', child: Text('Export')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                childAspectRatio: 3,
                mainAxisSpacing: 12,
                children: [
                  BiometricChart(
                    title: AppLocalizations.of(context).t('chart.hr'),
                    loader: (from, to) => _loader('hr', from, to),
                  ),
                  BiometricChart(
                    title: AppLocalizations.of(context).t('chart.temp'),
                    loader: (from, to) => _loader('temp', from, to),
                  ),
                  BiometricChart(
                    title: AppLocalizations.of(context).t('chart.o2'),
                    loader: (from, to) => _loader('o2', from, to),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
