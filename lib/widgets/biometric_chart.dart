import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../models/biometric_reading.dart';

typedef ReadingsLoader = Future<List<BiometricReading>> Function(DateTime from, DateTime to);

enum ChartRange { last24h, last7d, last30d, all }

class BiometricChart extends StatefulWidget {
  final String title;
  final ReadingsLoader loader;

  const BiometricChart({super.key, required this.title, required this.loader});

  @override
  State<BiometricChart> createState() => _BiometricChartState();
}

class _BiometricChartState extends State<BiometricChart> {
  ChartRange _range = ChartRange.last24h;
  late Future<List<BiometricReading>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadForRange(_range);
  }

  Future<List<BiometricReading>> _loadForRange(ChartRange r) {
    final now = DateTime.now();
    DateTime from;
    switch (r) {
      case ChartRange.last24h:
        from = now.subtract(const Duration(hours: 24));
        break;
      case ChartRange.last7d:
        from = now.subtract(const Duration(days: 7));
        break;
      case ChartRange.last30d:
        from = now.subtract(const Duration(days: 30));
        break;
      case ChartRange.all:
        from = DateTime.fromMillisecondsSinceEpoch(0);
        break;
    }
    return widget.loader(from, now);
  }

  List<FlSpot> _toSpots(List<BiometricReading> data) {
    if (data.isEmpty) return [];
    final start = data.first.timestamp.millisecondsSinceEpoch.toDouble();
    return data.map((d) {
      final x = (d.timestamp.millisecondsSinceEpoch.toDouble() - start) / 1000.0; // seconds since first
      return FlSpot(x, d.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BiometricReading>>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data ?? [];
        final spots = _toSpots(data);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.hardEdge,
          elevation: 3,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                    DropdownButton<ChartRange>(
                      value: _range,
                      items: const [
                        DropdownMenuItem(value: ChartRange.last24h, child: Text('24h')),
                        DropdownMenuItem(value: ChartRange.last7d, child: Text('1w')),
                        DropdownMenuItem(value: ChartRange.last30d, child: Text('1m')),
                        DropdownMenuItem(value: ChartRange.all, child: Text('All')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _range = v;
                          _future = _loadForRange(_range);
                        });
                      },
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
          child: data.isEmpty
            ? Center(
              child: snap.connectionState == ConnectionState.waiting
                ? const CircularProgressIndicator()
                : Text(AppLocalizations.of(context).t('chart.no_data')),
            )
                      : LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Theme.of(context).colorScheme.primary,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).toInt())),
                              )
                            ],
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
