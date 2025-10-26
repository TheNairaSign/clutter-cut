import 'package:clutter_cut/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Background Scan'),
            value: settings.isBackgroundScanEnabled,
            onChanged: (value) {
              settingsNotifier.setBackgroundScanEnabled(value);
            },
          ),
          if (settings.isBackgroundScanEnabled)
            ListTile(
              title: const Text('Scan Interval'),
              trailing: DropdownButton<ScanInterval>(
                value: settings.scanInterval,
                items: ScanInterval.values.map((interval) {
                  return DropdownMenuItem(
                    value: interval,
                    child: Text(interval.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (interval) {
                  if (interval != null) {
                    settingsNotifier.setScanInterval(interval);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
