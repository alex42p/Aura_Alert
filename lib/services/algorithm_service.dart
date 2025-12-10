import 'dart:collection';
import 'notification_service.dart';

enum StressLevel { normal, mild, moderate, high }

class _TimedValue {
  final DateTime ts;
  final double value;
  _TimedValue(this.ts, this.value);
}

/// Algorithm Service: processes incoming biometric readings and runs a
/// lightweight, low-latency stress calculation on the most recent window
/// (default: 5 minutes). The service maintains in-memory sliding windows
/// for HR, O2 and Temp so it can compute averages quickly (O(1) per sample)
/// and decide whether to send a notification when stress is detected.
class AlgorithmService {
  AlgorithmService._private();
  static final AlgorithmService instance = AlgorithmService._private();

  // --- configuration ---
  Duration window = const Duration(minutes: 5);
  Duration notificationCooldown = const Duration(minutes: 3);

  double w1 = 0.8; // HR weight
  double w2 = 0.2; // O2 weight
  double w3 = 0.0; // Temp weight

  // normalization config (reasonable defaults; app should allow per-user config)
  double hrMax = 190.0;
  double hrBaseline = 60.0;

  double o2Min = 90.0;
  double o2Max = 100.0;

  double tempBaseline = 33.0;
  double tempMax = 40.0;

  // --- runtime state ---
  final Queue<_TimedValue> _hr = Queue();
  double _hrSum = 0.0;

  final Queue<_TimedValue> _o2 = Queue();
  double _o2Sum = 0.0;

  final Queue<_TimedValue> _temp = Queue();
  double _tempSum = 0.0;

  NotificationService notifier = NotificationService.instance;

  DateTime? _lastNotificationTime;
  StressLevel? _lastNotifiedLevel;

  /// Add a single reading. This will update the sliding window and optionally
  /// compute stress and trigger notifications if thresholds are reached.
  void addReading(String type, double value, DateTime timestamp) {
    switch (type) {
      case 'hr':
        _push(_hr, timestamp, value, (v) => _hrSum += v, (v) => _hrSum -= v);
        break;
      case 'o2':
        _push(_o2, timestamp, value, (v) => _o2Sum += v, (v) => _o2Sum -= v);
        break;
      case 'temp':
        _push(_temp, timestamp, value, (v) => _tempSum += v, (v) => _tempSum -= v);
        break;
      default:
        return; // ignore unknown types
    }

    // After updating windows, recompute SI and trigger notifications if needed.
    final si = _computeSI();
    if (si != null) {
      final level = _classify(si);
      _maybeNotify(level, si);
    }
  }

  void _push(Queue<_TimedValue> q, DateTime ts, double value, void Function(double) onAdd, void Function(double) onRemove) {
    final tv = _TimedValue(ts, value);
    q.addLast(tv);
    onAdd(value);

    // Evict old values outside the window
    final cutoff = ts.subtract(window);
    while (q.isNotEmpty && q.first.ts.isBefore(cutoff)) {
      final removed = q.removeFirst();
      onRemove(removed.value);
    }
  }

  double? _avg(Queue<_TimedValue> q, double sum) {
    if (q.isEmpty) return null;
    return sum / q.length;
  }

  /// Returns SI value for the current windows, or null if any metric is missing
  double? _computeSI() {
    final hrAvg = _avg(_hr, _hrSum);
    final o2Avg = _avg(_o2, _o2Sum);
    final tAvg = _avg(_temp, _tempSum);

    if (hrAvg == null || o2Avg == null || tAvg == null) return null;

    // Normalize and clamp between 0..1
    final hrNorm = _clamp((hrAvg - hrBaseline) / (hrMax - hrBaseline));
    final o2Norm = _clamp((o2Avg - o2Min) / (o2Max - o2Min));
    final tempNorm = _clamp((tAvg - tempBaseline) / (tempMax - tempBaseline));

    final si = w1 * hrNorm + w2 * (1.0 - o2Norm) + w3 * tempNorm;
    return si;
  }

  double _clamp(double v) => v.isNaN ? 0.0 : (v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v));

  StressLevel _classify(double si) {
    if (si < 0.3) return StressLevel.normal;
    if (si < 0.6) return StressLevel.mild;
    if (si < 0.8) return StressLevel.moderate;
    return StressLevel.high;
  }

  void _maybeNotify(StressLevel level, double si) {
    final shouldNotify = level == StressLevel.moderate || level == StressLevel.high;
    if (!shouldNotify) return;

    final now = DateTime.now();
    if (_lastNotificationTime != null) {
      final elapsed = now.difference(_lastNotificationTime!);
      if (elapsed < notificationCooldown && _lastNotifiedLevel == level) {
        // avoid spamming if same level recently notified
        return;
      }
    }

    _lastNotificationTime = now;
    _lastNotifiedLevel = level;

    final severity = level == StressLevel.high ? 'HIGH' : 'MODERATE';
    final msg = 'Detected $severity stress (SI=${si.toStringAsFixed(2)}). Please check in.';
    notifier.sendNotification(msg);
  }

  /// Useful for tests and debugging: reset internal state
  void clear() {
    _hr.clear();
    _hrSum = 0.0;
    _o2.clear();
    _o2Sum = 0.0;
    _temp.clear();
    _tempSum = 0.0;
    _lastNotificationTime = null;
    _lastNotifiedLevel = null;
  }

  /// Read-only helpers for introspection / tests
  double? get currentSI => _computeSI();

  StressLevel? get currentStressLevel {
    final si = _computeSI();
    if (si == null) return null;
    return _classify(si);
  }
}