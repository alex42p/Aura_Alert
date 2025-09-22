import 'package:flutter/material.dart';
import 'models/biometric_reading.dart';
import 'services/database_service.dart';
import 'widgets/biometric_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Alert',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent)),
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
        title: const Text('Aura Alert Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              // handle navigation selection
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'sync', child: Text('Sync')),
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
                    title: 'Heart Rate (BPM)',
                    loader: (from, to) => _loader('hr', from, to),
                  ),
                  BiometricChart(
                    title: 'Skin Temperature (°C)',
                    loader: (from, to) => _loader('temp', from, to),
                  ),
                  BiometricChart(
                    title: 'O₂ Level (%)',
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
