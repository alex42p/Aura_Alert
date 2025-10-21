import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_alert/services/bluetooth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BleService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // ensure init will read mock prefs
      await BleService.instance.init();
    });

    test('loads saved battery and persists updates', () async {
      final svc = BleService.instance;
      // initially null
      expect(svc.latestBattery.value, isNull);

      // simulate an update
      svc.latestBattery.value = 77;
      // give the listener time to write
      await Future.delayed(const Duration(milliseconds: 50));

      // create a fresh instance (singleton) and re-init to read saved value
      await svc.init();
      expect(svc.latestBattery.value, 77);

      // clearing should remove pref
      svc.latestBattery.value = null;
      await Future.delayed(const Duration(milliseconds: 50));
      await svc.init();
      expect(svc.latestBattery.value, isNull);
    });
  });
}
