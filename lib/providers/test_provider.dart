import 'package:clutter_cut/providers/state/clutter_state.dart';
import 'package:flutter/material.dart';

class TestProvider extends ChangeNotifier {
  int? len;

  void testDuplicateState(ClutterState state) {
    print('Duplicate Files: ${state.duplicateFiles.length}');
    print('Selected Files: ${state.selectedFiles.length}');
    print('Scanning?: ${state.isScanning}');
    print('Total files: ${state.totalFiles}');
    print('Scanned files: ${state.scannedFiles}');
    print('Current Action ${state.currentAction}');

    // Test the state of the ClutterState object
    notifyListeners();
  }

  int duplicatesLength(ClutterState state) {
    len = state.duplicateFiles.length;
    notifyListeners();
    return len ?? 0;
  }

  
}