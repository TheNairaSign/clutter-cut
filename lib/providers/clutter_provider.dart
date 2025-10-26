// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:clutter_cut/core/events.dart';
import 'package:clutter_cut/providers/state/clutter_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class ClutterNotifier extends StateNotifier<ClutterState> {
  final Ref ref;
  
  ClutterNotifier(this.ref): super(ClutterState(
    selectedFiles: [],
    duplicateFiles: {},
    isScanning: false, 
    totalFiles: 0,
    scannedFiles: 0, 
    currentAction: '',
    isFullScan: false,
  ));

  Future<void> requestPermissions() async {
    print('Requesting storage permissions...');
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        print('Permissions permanently denied, opening settings...');
        await openAppSettings();
        return;
      }
    }
  }

  Future<void> scanEntireDevice() async {
    state = state.copyWith(isFullScan: true);
    await requestPermissions();
    await _scanDirectory('/storage/emulated/0');
    state = state.copyWith(isFullScan: false);
  }

  Future<void> selectDirectory() async {
    state = state.copyWith(isFullScan: false);
    await requestPermissions();
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath != null) {
        await _scanDirectory(directoryPath);
      }
    } catch (e) {
      ref.read(uiEventProvider.notifier).state = ShowSnackbar('Error selecting directory: $e', isError: true);
      state = state.copyWith(
        isScanning: false,
        currentAction: "Error selecting directory: $e"
      );
    }
  }

  Future<void> _scanDirectory(String directoryPath) async {
    print('Directory selected: $directoryPath');
    state = state.copyWith(
      selectedFiles: [],
      duplicateFiles: {},
      isScanning: true,
      currentAction: "Optimized scanning: Grouping files by size...",
      scannedFiles: 0,
      totalFiles: 0
    );
    print('State after directory selection: $state');
    
    try {
      final directory = Directory(directoryPath);
      print('Starting to scan directory: $directoryPath');
      print('Directory exists: ${await directory.exists()}');
      
      // First, collect all files to avoid stream issues
      final List<FileSystemEntity> allEntities = [];
      final stream = directory.list(recursive: true);
      await for (final entity in stream.handleError((e) {
        print('Error listing directory contents: $e');
      })) {
        if (entity is File) {
          // print('Found file: ${entity.path}');
          allEntities.add(entity);
        }
      }
      
      print('Total files found: ${allEntities.length}');
      
      // Now process the collected files
      final Map<int, List<File>> filesBySize = {};
      for (final entity in allEntities) {
        if (entity is File) {
          try {
            final size = await entity.length();
            if (size > 0) {
              // print('Processing file: ${entity.path} (${size} bytes)');
              filesBySize.putIfAbsent(size, () => []).add(entity);
            }
          } catch (e) {
            print('Error processing file ${entity.path}: $e');
            continue;
          }
        }
      }

      // Get only the groups of files with the same size (potential duplicates)
      final potentialDuplicateGroups = filesBySize.values.where((files) => files.length > 1);
      final List<File> filesToHash = potentialDuplicateGroups.expand((files) => files).toList();
      
      print('Found ${filesToHash.length} potential duplicates in ${filesBySize.length} size groups');
      
      if (filesToHash.isEmpty) {
        print('No potential duplicates found');
      } else {
        print('First potential duplicate: ${filesToHash.first.path}');
      }

      // Update state with the files to be scanned
      final newState = state.copyWith(
        selectedFiles: filesToHash,
        totalFiles: filesToHash.length,
        isScanning: false,
        currentAction: filesToHash.isEmpty 
          ? "No potential duplicates found."
          : "Ready to scan ${filesToHash.length} potential duplicates."
      );
      
      print('Updating state: selectedFiles: ${filesToHash.length} files');
      state = newState;
    } catch (e) {
      print('Error accessing directory: $e');
      ref.read(uiEventProvider.notifier).state = ShowSnackbar('Error accessing directory: $e', isError: true);
      state = state.copyWith(
        isScanning: false,
        currentAction: "Error accessing directory: $e"
      );
    }
  }
}

final clutterNotifierProvider = StateNotifierProvider<ClutterNotifier, ClutterState>((ref) => ClutterNotifier(ref));
