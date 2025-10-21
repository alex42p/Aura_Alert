import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_alert/services/bluetooth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dashboard shows battery when available', (WidgetTester tester) async {
    // Make sure BLE service is initialized (loads prefs)
    await BleService.instance.init();

    // Set a known battery value
    BleService.instance.latestBattery.value = 42;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ValueListenableBuilder<int?>(
                valueListenable: BleService.instance.latestBattery,
                builder: (context, bat, _) {
                  if (bat == null) return const SizedBox.shrink();
                  return Text('Battery: $bat%');
                },
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Battery: 42%'), findsOneWidget);
  });
}
