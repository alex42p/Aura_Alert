import 'package:flutter/material.dart';
import 'models/biometric_reading.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'widgets/biometric_chart.dart';
import 'pages/settings_page.dart';
import 'l10n/app_localizations.dart';
import 'services/bluetooth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted settings before launching the app so initial theme/locale are correct
  await SettingsService.instance.load();
  // Initialize BLE service (loads last-known battery from SharedPreferences)
  await BleService.instance.init();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ValueListenableBuilder<int?>(
              valueListenable: BleService.instance.latestBattery,
              builder: (context, bat, _) {
                if (bat == null) return const SizedBox.shrink();
                return Text('Battery: $bat%', style: const TextStyle(color: Colors.white));
              },
            ),
          ),
        ),
        actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: Colors.green),
                tooltip: 'Add dummy data',
                onPressed: () async {
                  try {
                    final count = await _db.insertDummyData(1000);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Inserted $count rows')));
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DashboardPage()),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Insert failed: $e')));
                  }
                },
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'settings') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                  return;
                }
                if (v == 'export') {
                  try {
                    final path = await _db.exportToCsv();
                    final result = await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(path)], 
                        subject: 'Aura Alert Data Export', 
                        text: 'Your scanned biometric data has been turned into a CSV file for your convenience!'
                      ));

                    if (result.status == ShareResultStatus.success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported CSV to: $path')));
                    } else if (result.status == ShareResultStatus.dismissed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share canceled by user.')));
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing not available.')));
                      }
                    }

                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                  }
                  return;
                }
                if (v == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm delete'),
                      content: const Text('Delete all readings from the local database? This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await _db.deleteAllReadings();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All readings deleted')));
                    // Refresh the dashboard by rebuilding this page
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardPage()));
                  }
                  return;
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuItem(value: 'export', child: Text('Export')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
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
