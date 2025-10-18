import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'database_service.dart';

/// BLE Service: scans, connects, subscribes to a characteristic, receives JSON
/// payloads from the peripheral, parses them and inserts the readings into
/// the local database using DatabaseService.
class BleService {
  final flutterReactiveBle = FlutterReactiveBle();
  final DatabaseService _db = DatabaseService();

  // UUIDs are placeholders — replace with your device's service/characteristic UUIDs
  final Uuid serviceUuid = Uuid.parse('0000180d-0000-1000-8000-00805f9b34fb');
  final Uuid characteristicUuid = Uuid.parse('00002a37-0000-1000-8000-00805f9b34fb');

  StreamSubscription<DiscoveredDevice>? _scanSub;
  late StreamSubscription<ConnectionStateUpdate> _connection;
  StreamSubscription<List<int>>? _notifySub;

  String? connectedDeviceId;

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
  }
}