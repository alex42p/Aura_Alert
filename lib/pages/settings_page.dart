import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../services/bluetooth_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final BleService _bleService = BleService();

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = SettingsService.instance;
  late final TextEditingController _fontController;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _fontController = TextEditingController(text: _settings.fontSize.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _fontController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    // Keep the font text box in sync when settings change elsewhere (e.g., slider)
    if (_fontController.text != _settings.fontSize.toStringAsFixed(0)) {
      _fontController.text = _settings.fontSize.toStringAsFixed(0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 28, 88, 253),
        title: Text(AppLocalizations.of(context).t('app.title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IconButton(
            //   icon: const Icon(Icons.arrow_back),
            //   onPressed: () => Navigator.of(context).pop(),
            // ),
            Text(
              t.t('settings.title'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(t.t('settings.dark_mode')),
              value: _settings.isDarkMode,
              onChanged: (v) => _settings.setDarkMode(v),
            ),
            ListTile(
              title: Text(t.t('settings.font_size')),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 10,
                      max: 24,
                      divisions: 14,
                      label: _settings.fontSize.toStringAsFixed(0),
                      value: _settings.fontSize,
                      onChanged: (v) => _settings.setFontSize(v),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      controller: _fontController,
                      keyboardType: TextInputType.number,
                      onFieldSubmitted: (s) {
                        final v = double.tryParse(s);
                        if (v != null) {
                          final clamped = v.clamp(10.0, 24.0);
                          _settings.setFontSize(clamped); // keep the controller text in sync (no decimals)
                          _fontController.text = clamped.toStringAsFixed(0);
                        } else { // reset to current value if parse fails
                          _fontController.text = _settings.fontSize.toStringAsFixed(0);
                        }
                      },
                      onEditingComplete: () {
                        // ensure value is applied when editing finishes
                        final v = double.tryParse(_fontController.text);
                        if (v != null) {
                          final clamped = v.clamp(10.0, 24.0);
                          _settings.setFontSize(clamped);
                          _fontController.text = clamped.toStringAsFixed(0);
                        } else {
                          _fontController.text = _settings.fontSize.toStringAsFixed(0);
                        }
                        // remove focus
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(t.t('settings.language')),
              trailing: DropdownButton<String>(
                value: _settings.locale.languageCode,
                items: const [
                  DropdownMenuItem(value: 'de', child: Text('Deutsch')),      // German
                  DropdownMenuItem(value: 'en', child: Text('English')),      // English
                  DropdownMenuItem(value: 'es', child: Text('Español')),      // Spanish
                  DropdownMenuItem(value: 'fr', child: Text('Français')),     // French
                ],
                onChanged: (v) {
                  if (v != null) _settings.setLocale(Locale(v));
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Bluetooth Device'),
              subtitle: Text(_bleService.connectedDeviceId ?? 'Not connected'),
              trailing: ElevatedButton(
                child: const Text('Choose'),
                onPressed: () async {
                  // open modal with device list
                  final selected = await showModalBottomSheet<DiscoveredDevice>(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) {
                      final discovered = <String, DiscoveredDevice>{};
                      final scanStream = _bleService.scanForDevices();
                      final sub = scanStream.listen((d) {
                        discovered[d.id] = d;
                      }, onError: (e) {
                        debugPrint('Scan error: $e');
                      });

                      return StatefulBuilder(builder: (c, setModalState) {
                        return SizedBox(
                          height: 400,
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  children: discovered.values.map((device) {
                                    return ListTile(
                                      title: Text(device.name.isNotEmpty ? device.name : device.id),
                                      subtitle: Text(device.id),
                                      onTap: () {
                                        sub.cancel();
                                        Navigator.of(ctx).pop(device);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                              TextButton(
                                child: const Text('Stop scan'),
                                onPressed: () async {
                                  await sub.cancel();
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                },
                              )
                            ],
                          ),
                        );
                      });
                    },
                  );

                  if (selected != null) {
                    // connect to the chosen device
                    await _bleService.connect(selected.id);
                    setState(() {});
                  } else {
                    // user dismissed the sheet
                    await _bleService.stopScan();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
