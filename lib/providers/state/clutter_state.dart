import 'dart:io';

class ClutterState {
  List<FileSystemEntity> selectedFiles;
  Map<String, List<File>> duplicateFiles;
  bool isScanning;
  int totalFiles;
  int scannedFiles;
  String currentAction;
  bool isFullScan;

  ClutterState({
    required this.selectedFiles, 
    required this.duplicateFiles, 
    required this.isScanning,
    required this.totalFiles,
    required this.scannedFiles,
    required this.currentAction,
    this.isFullScan = false,
  });

  

  ClutterState copyWith({
    List<FileSystemEntity>? selectedFiles,
    Map<String, List<File>>? duplicateFiles,
    bool? isScanning,
    int? totalFiles,
    int? scannedFiles,
    String? currentAction,
    bool? isFullScan,
  }) {
    return ClutterState(
      selectedFiles: selectedFiles ?? this.selectedFiles,
      duplicateFiles: duplicateFiles ?? this.duplicateFiles,
      isScanning: isScanning ?? this.isScanning,
      totalFiles: totalFiles ?? this.totalFiles,
      scannedFiles: scannedFiles ?? this.scannedFiles,
      currentAction: currentAction ?? this.currentAction, 
      isFullScan: isFullScan ?? this.isFullScan,
    );
  }
}
