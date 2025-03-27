// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:clutter_cut/providers/state/clutter_state.dart';
import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class ClutterNotifier extends StateNotifier<ClutterState> {
  final BuildContext context;
  final Ref ref;
  
  ClutterNotifier(this.context, this.ref): super(ClutterState(
    selectedFiles: [],
    duplicateFiles: {},
    isScanning: false, 
    totalFiles: 0, 
    scannedFiles: 0, 
    currentAction: ''
  ));



  Future<void> requestPermissions() async {
    await Permission.storage.request();
    final permissionStatus = await Permission.storage.status;
    if (permissionStatus.isDenied) {
      await Permission.storage.request();
    } if (permissionStatus.isPermanentlyDenied || permissionStatus.isRestricted || permissionStatus.isLimited) {
      await openAppSettings();
    }
    // await Permission.storage.request();
    // if (await Permission.storage.isDenied) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Storage permission is required')),
    //   );
  }

  Future<void> selectDirectory() async {
    await requestPermissions();
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      
      if (directoryPath != null) {
        state = state.copyWith(
          selectedFiles: [],
          duplicateFiles: {},
          isScanning: true,
          currentAction: "Gathering files...",
          scannedFiles: 0
        );
        
        final directory = Directory(directoryPath);
        final List<FileSystemEntity> entities = await directory
            .list(recursive: true)
            .where((entity) => entity is File)
            .toList();
        
        state = state.copyWith(
          selectedFiles: entities,
          totalFiles: entities.length,
          currentAction: "Scanning for duplicates..."
        );
        
        await ref.read(duplicateRemoverNotifierProvider(context).notifier).findDuplicates();
        // context.read<TestProvider>().duplicatesLength(state);
        
        // state = state.copyWith(isScanning: false);
      }
    } catch (e) {
      state = state.copyWith(isScanning: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting directory: $e')),
      );
    }
  }
}

final clutterNotifierProvider = StateNotifierProvider.family<ClutterNotifier, ClutterState, BuildContext>(
  (ref, context) => ClutterNotifier(context, ref)
);
