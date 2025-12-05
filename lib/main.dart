import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'models/biometric_reading.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'widgets/biometric_chart.dart';
import 'pages/settings_page.dart';
import 'l10n/app_localizations.dart';
import 'services/bluetooth_service.dart';
import 'services/notification_service.dart';
import 'pages/notifications_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// TODO: Add "About" button to AppBar/settings to explain how the app functions

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  // Note: you can't show a local notification here, but you can handle data
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Load persisted settings before launching the app so initial theme/locale are correct
  await SettingsService.instance.load();
  // Initialize BLE service (loads last-known battery from SharedPreferences)
  await BleService.instance.init();
  // Initialize notification service (local notifications + persistence)
  await NotificationService.instance.init();
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
    final textTheme = ThemeData(brightness: brightness)
        .textTheme
        .apply(
          bodyColor: _settings.isDarkMode ? Colors.white : Colors.black,
          displayColor: _settings.isDarkMode ? Colors.white : Colors.black,
        )
        .copyWith(
          bodySmall: TextStyle(fontSize: _settings.fontSize),
          bodyMedium: TextStyle(fontSize: _settings.fontSize),
          bodyLarge: TextStyle(fontSize: _settings.fontSize + 2),
        );

    return MaterialApp(
      title: 'Aura Alert',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de')
      ],
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

  Future<List<BiometricReading>> _loader(
      String type, DateTime from, DateTime to) async {
    return await _db.queryReadings(type: type, from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 28, 88, 253),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(AppLocalizations.of(context).t('dashboard.title')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ValueListenableBuilder<int?>(
              valueListenable: BleService.instance.latestBattery,
              builder: (context, bat, _) {
                if (bat == null) {
                  return const Text('Bat: --%',
                    style: TextStyle(color: Colors.white, fontSize: 20));
                }
                return Text('Bat: $bat%',
                    style: TextStyle(color: Colors.white, fontSize: 20));
              },
            ),
          ),
        ),
        actions: [
          // test notification button (orange plus)
          IconButton(
            icon: const Icon(Icons.add, color: Colors.orange),
            tooltip: AppLocalizations.of(context).t('tooltip.send_test_notification'),
            onPressed: () async {
              final msg = AppLocalizations.of(context).t('notification.test_message');
              await NotificationService.instance.sendNotification(msg);
            },
          ),

          // inbox with unread badge
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.instance.unreadCount,
            builder: (context, unread, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.inbox, color: Colors.white),
                    tooltip: AppLocalizations.of(context).t('tooltip.notifications'),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const NotificationsPage()));
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text(unread.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    )
                ],
              );
            },
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Colors.green),
              tooltip: AppLocalizations.of(context).t('tooltip.add_dummy'),
              onPressed: () async {
                try {
                  final count = await _db.insertDummyData(1000);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).t('db.inserted_rows').replaceAll('{count}', count.toString()))));
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).t('db.insert_failed').replaceAll('{error}', e.toString()))));
                }
              },
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'settings') {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()));
                return;
              }
              if (v == 'export') {
                try {
                  final path = await _db.exportToCsv();
                  final result =
                      await SharePlus.instance.share(ShareParams(
                          files: [XFile(path)],
                          subject: AppLocalizations.of(context).t('email.subject'),
                          text: AppLocalizations.of(context).t('email.body')));
                  
                  if (result.status == ShareResultStatus.success &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).t('export.success').replaceAll('{path}', path))));
                  } else if (result.status == ShareResultStatus.dismissed &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).t('export.canceled'))));
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context).t('export.unavailable'))));
                    }
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).t('export.failed').replaceAll('{error}', e.toString()))));
                }
                return;
              }
              if (v == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppLocalizations.of(context).t('dialog.confirm_delete_title')),
                    content: Text(AppLocalizations.of(context).t('dialog.confirm_delete_content')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(AppLocalizations.of(context).t('dialog.cancel'))),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(AppLocalizations.of(context).t('dialog.delete'))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _db.deleteAllReadings();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).t('snackbar.all_readings_deleted'))));
                  // Refresh the dashboard by rebuilding this page
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DashboardPage()));
                }
                return;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'settings', child: Text(AppLocalizations.of(context).t('menu.settings'))),
              PopupMenuItem(value: 'export', child: Text(AppLocalizations.of(context).t('menu.export'))),
              PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context).t('menu.delete'))),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemHeight = constraints.maxHeight / 3;
                  return ListView(
                    // We don't want internal scrolling — charts fill the screen
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      SizedBox(
                        height: itemHeight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: BiometricChart(
                            title: AppLocalizations.of(context).t('chart.hr'),
                            loader: (from, to) => _loader('hr', from, to),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: itemHeight,
                        child: BiometricChart(
                          title: AppLocalizations.of(context).t('chart.o2'),
                          loader: (from, to) => _loader('o2', from, to),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}