
import 'package:background_fetch/background_fetch.dart';
import 'package:clutter_cut/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void onBackgroundFetch(String taskId) async {
  print('[BackgroundFetch] Event received: $taskId');
  await performBackgroundScan();
  BackgroundFetch.finish(taskId);
}

Future<void> performBackgroundScan() async {
  final container = ProviderContainer();
  final settings = container.read(settingsProvider);

  if (settings.isBackgroundScanEnabled) {
    // final clutterNotifier = container.read(clutterNotifierProvider.notifier);
    // await clutterNotifier.scanDevice(); // This will trigger the scan
  }
}

Future<void> initBackgroundFetch() async {
  final container = ProviderContainer();
  final settings = container.read(settingsProvider);

  int interval = 15;
  switch (settings.scanInterval) {
    case ScanInterval.daily:
      interval = 1440;
      break;
    case ScanInterval.every3days:
      interval = 4320;
      break;
    case ScanInterval.weekly:
      interval = 10080;
      break;
  }

  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: interval, // minutes
      stopOnTerminate: false,
      enableHeadless: true,
      startOnBoot: true,
      requiredNetworkType: NetworkType.ANY,
    ),
    onBackgroundFetch,
  ).then((int status) {
    print('[BackgroundFetch] configure success: $status');
  }).catchError((e) {
    print('[BackgroundFetch] configure ERROR: $e');
  });
}