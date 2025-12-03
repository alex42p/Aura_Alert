import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../models/biometric_reading.dart';

typedef ReadingsLoader = Future<List<BiometricReading>> Function(DateTime from, DateTime to);

enum ChartRange { last24h, last7d, last30d, all }

enum MeasurementType { heartRate, spo2, skinTemp, generic }

class BiometricChart extends StatefulWidget {
  final String title;
  final ReadingsLoader loader;
  final MeasurementType? measurementType;

  const BiometricChart({super.key, required this.title, required this.loader, this.measurementType});

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

  MeasurementType _inferTypeFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('heart') || t.contains('hr') || t.contains('bpm')) return MeasurementType.heartRate;
    if (t.contains('o2') || t.contains('spO2'.toLowerCase())) return MeasurementType.spo2;
    if (t.contains('temp') || t.contains('temperature')) return MeasurementType.skinTemp;
    return MeasurementType.generic;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BiometricReading>>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data ?? [];

        // Compute spots and start timestamp (seconds since first)
        double startMs = data.isEmpty ? DateTime.now().millisecondsSinceEpoch.toDouble() : data.first.timestamp.millisecondsSinceEpoch.toDouble();
        final spots = data.map((d) {
          final x = (d.timestamp.millisecondsSinceEpoch.toDouble() - startMs) / 1000.0; // seconds since first
          return FlSpot(x, d.value);
        }).toList();

        // Helper to map ChartRange to default seconds (used when there's no data)
        double rangeSecondsFor(ChartRange r) {
          switch (r) {
            case ChartRange.last24h:
              return 24 * 3600.0;
            case ChartRange.last7d:
              return 7 * 24 * 3600.0;
            case ChartRange.last30d:
              return 30 * 24 * 3600.0;
            case ChartRange.all:
              return 30 * 24 * 3600.0; // fallback to 30 days for 'all'
          }
        }

        // X axis range: use data span when available, otherwise range-based default
        double xMax = spots.isEmpty ? rangeSecondsFor(_range) : (spots.last.x - (spots.isNotEmpty ? spots.first.x : 0.0));
        if (xMax <= 0) xMax = 1.0; // avoid zero interval for single-point data
        final double xInterval = xMax / 4.0; // 4 intervals -> 5 labels

        final mType = widget.measurementType ?? _inferTypeFromTitle(widget.title);

        // Colors per measurement
        final Color seriesColor;
        switch (mType) {
          case MeasurementType.heartRate:
            seriesColor = Colors.red;
            break;
          case MeasurementType.spo2:
            seriesColor = const Color(0xFF0D47A1); // dark blue
            break;
          case MeasurementType.skinTemp:
            seriesColor = Colors.green;
            break;
          default:
            seriesColor = Theme.of(context).colorScheme.primary;
        }

        // Determine Y axis min/max
        double minY, maxY, yInterval;
        if (mType == MeasurementType.heartRate) {
          minY = 40;
          maxY = 180;
        } else if (mType == MeasurementType.spo2) {
          minY = 80;
          maxY = 100;
        } else if (mType == MeasurementType.skinTemp) {
          minY = 30;
          maxY = 40;
        } else {
          // generic: compute from data
          if (spots.isEmpty) {
            minY = 0;
            maxY = 100;
          } else {
            final ys = spots.map((s) => s.y);
            final minVal = ys.reduce((a, b) => a < b ? a : b);
            final maxVal = ys.reduce((a, b) => a > b ? a : b);
            final padding = (maxVal - minVal) * 0.1;
            minY = (minVal - padding).floorToDouble();
            maxY = (maxVal + padding).ceilToDouble();
          }
        }

        // Ensure non-zero span and compute uniform 4 intervals => 5 labels
        if (maxY <= minY) {
          // add small padding if constant
          maxY = minY + 1.0;
        }
        yInterval = (maxY - minY) / 4.0;
        if (yInterval <= 0) yInterval = 1.0;

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
                      items: [
                        DropdownMenuItem(value: ChartRange.last24h, child: Text(AppLocalizations.of(context).t('chart.range.24h'))),
                        DropdownMenuItem(value: ChartRange.last7d, child: Text(AppLocalizations.of(context).t('chart.range.1w'))),
                        DropdownMenuItem(value: ChartRange.last30d, child: Text(AppLocalizations.of(context).t('chart.range.1m'))),
                        DropdownMenuItem(value: ChartRange.all, child: Text(AppLocalizations.of(context).t('chart.range.all'))),
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
                            minY: minY,
                            maxY: maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: seriesColor,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(show: true, color: seriesColor.withAlpha((0.15 * 255).toInt())),
                              )
                            ],
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: xInterval,
                                  getTitlesWidget: (value, meta) {
                                    final ts = DateTime.fromMillisecondsSinceEpoch(startMs.toInt() + (value * 1000).toInt()).toLocal();
                                    String label;
                                    if (_range == ChartRange.last24h) {
                                      label = '${ts.hour}:${ts.minute.toString().padLeft(2, '0')}';
                                    } else {
                                      label = '${ts.month}/${ts.day}';
                                    }
                                    return Text(label, style: const TextStyle(fontSize: 14));
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: yInterval,
                                  getTitlesWidget: (value, meta) {
                                    // Format Y labels depending on measurement
                                    String label;
                                    if (mType == MeasurementType.spo2) {
                                      label = '${value.toInt()}%';
                                    } else if (mType == MeasurementType.heartRate) {
                                      label = '${value.toInt()}';
                                    } else if (mType == MeasurementType.skinTemp) {
                                      label = '${value.toStringAsFixed(1)}°C';
                                    } else {
                                      label = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
                                    }
                                    return Text(label, style: const TextStyle(fontSize: 14));
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
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
