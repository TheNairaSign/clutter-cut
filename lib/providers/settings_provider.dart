
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ScanInterval {
  daily,
  every3days,
  weekly,
}

class SettingsState {
  final bool isBackgroundScanEnabled;
  final ScanInterval scanInterval;

  SettingsState({
    required this.isBackgroundScanEnabled,
    required this.scanInterval,
  });

  SettingsState copyWith({
    bool? isBackgroundScanEnabled,
    ScanInterval? scanInterval,
  }) {
    return SettingsState(
      isBackgroundScanEnabled: isBackgroundScanEnabled ?? this.isBackgroundScanEnabled,
      scanInterval: scanInterval ?? this.scanInterval,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(isBackgroundScanEnabled: false, scanInterval: ScanInterval.weekly)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('isBackgroundScanEnabled') ?? false;
    final intervalIndex = prefs.getInt('scanInterval') ?? ScanInterval.weekly.index;
    state = SettingsState(
      isBackgroundScanEnabled: isEnabled,
      scanInterval: ScanInterval.values[intervalIndex],
    );
  }

  Future<void> setBackgroundScanEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBackgroundScanEnabled', isEnabled);
    state = state.copyWith(isBackgroundScanEnabled: isEnabled);
  }

  Future<void> setScanInterval(ScanInterval interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scanInterval', interval.index);
    state = state.copyWith(scanInterval: interval);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
