import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'algorithm_service.dart';

/// BLE Service: scans, connects, subscribes to a characteristic, receives JSON
/// payloads from the peripheral, parses them and inserts the readings into
/// the local database using DatabaseService.
class BleService {
  BleService._private();
  static final BleService instance = BleService._private();

  // Persisted key for the last known battery percentage
  static const String _kLastBatteryKey = 'ble_last_battery';

  bool _inited = false;
  bool _persistListenerAttached = false;

  FlutterReactiveBle? _flutterReactiveBle;
  FlutterReactiveBle get flutterReactiveBle => _flutterReactiveBle ??= FlutterReactiveBle();
  final DatabaseService _db = DatabaseService();

  // UUIDs are placeholders — replace with your device's service/characteristic UUIDs
  final Uuid serviceUuid = Uuid.parse('0000180d-0000-1000-8000-00805f9b34fb');
  final Uuid characteristicUuid = Uuid.parse('00002a37-0000-1000-8000-00805f9b34fb');

  StreamSubscription<DiscoveredDevice>? _scanSub;
  late StreamSubscription<ConnectionStateUpdate> _connection;
  StreamSubscription<List<int>>? _notifySub;

  String? connectedDeviceId;
  /// Latest battery percentage reported by the connected device (0-100).
  /// Null when unknown.
  final ValueNotifier<int?> latestBattery = ValueNotifier<int?>(null);

  /// Initialize the service. Loads the last-known battery percentage from
  /// SharedPreferences and attaches a listener to persist updates.
  Future<void> init() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
    // debugPrint('Skipping BLE initialization in test mode');
    return;
  }

    if (_inited) return;
    _inited = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kLastBatteryKey);
      if (saved != null) latestBattery.value = saved.clamp(0, 100);

      if (!_persistListenerAttached) {
        latestBattery.addListener(() async {
          final val = latestBattery.value;
          try {
            final p = await SharedPreferences.getInstance();
            if (val == null) {
              await p.remove(_kLastBatteryKey);
            } else {
              await p.setInt(_kLastBatteryKey, val);
            }
          } catch (e) {
            debugPrint('Failed to persist latestBattery: $e');
          }
        });
        _persistListenerAttached = true;
      }
    } catch (e) {
      debugPrint('BleService.init() failed to load preferences: $e');
    }
  }

  /// Start scanning for devices that advertise the given service UUID.
  Stream<DiscoveredDevice> scanForDevices() async* {
    final controller = StreamController<DiscoveredDevice>();
    _scanSub = flutterReactiveBle.scanForDevices(withServices: [serviceUuid]).listen((device) {
      controller.add(device);
    }, onError: (err) {
      controller.addError(err);
    });
    yield* controller.stream;
  }

  /// Stop an active scan started by scanForDevices().
  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
  }

  /// Connect to a device by id.
  Future<void> connect(String deviceId) async {
    _connection = flutterReactiveBle.connectToDevice(id: deviceId).listen((event) {
      if (event.connectionState == DeviceConnectionState.connected) {
        connectedDeviceId = deviceId;
        // subscribe to notifications after connection
        _subscribeToCharacteristic(deviceId);
      }
    }, onError: (e) {
      debugPrint('Connection error: $e');
    });
  }

  Future<void> _subscribeToCharacteristic(String deviceId) async {
    final characteristic = QualifiedCharacteristic(characteristicId: characteristicUuid, serviceId: serviceUuid, deviceId: deviceId);
    _notifySub = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      // data is a list of bytes; assume UTF-8 JSON string
      try {
        final jsonStr = utf8.decode(data);
        final Map<String, dynamic> parsed = jsonDecode(jsonStr);
        _handleImportedJson(parsed);
      } catch (e) {
        debugPrint('Failed to decode/parse incoming BLE payload: $e');
      }
    }, onError: (e) {
      debugPrint('Notify error: $e');
    });
  }

  Future<void> disconnect() async {
  await _notifySub?.cancel();
  await _connection.cancel();
  _scanSub?.cancel();
  connectedDeviceId = null;
  }

  Future<void> _handleImportedJson(Map<String, dynamic> json) async {
    // The logic mirrors the earlier ImportService: insert readings with computed timestamps
    final db = await _db.database;
    if (!json.containsKey('ts')) return;
    final importTs = DateTime.fromMillisecondsSinceEpoch((json['ts'] * 1000).toInt());

    Future<void> insertReadings(String type, List<dynamic> readings) async {
      for (var reading in readings) {
        final value = reading[0] as num;
        final offsetSeconds = reading[1] as num;
        final timestamp = importTs.add(Duration(seconds: offsetSeconds.toInt()));
        await db.insert('readings', {
          'timestamp': timestamp.toIso8601String(),
          'value': value,
          'type': type,
        });
        // Update fast in-memory algorithm so we can react immediately
        try {
          AlgorithmService.instance.addReading(type, value.toDouble(), timestamp);
        } catch (e) {
          debugPrint('AlgorithmService.addReading error: $e');
        }
      }
    }

    if (json.containsKey('hr')) {
      await insertReadings('hr', json['hr']);
    }
    if (json.containsKey('temp')) {
      await insertReadings('temp', json['temp']);
    }
    if (json.containsKey('o2')) {
      await insertReadings('o2', json['o2']);
    }
    // Battery percentage handling: update the latestBattery notifier
    if (json.containsKey('bat')) {
      try {
        final batVal = (json['bat'] as num).toInt();
        latestBattery.value = batVal.clamp(0, 100);
      } catch (e) {
        debugPrint('Invalid battery value: $e');
      }
    }
  }
}