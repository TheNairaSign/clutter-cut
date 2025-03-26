import 'dart:io';

import 'package:clutter_cut/providers/clutter_provider.dart';
import 'package:clutter_cut/providers/state/clutter_state.dart';
import 'package:clutter_cut/utils/calculate_md5.dart';
import 'package:clutter_cut/utils/confirm_dialog.dart';
import 'package:clutter_cut/utils/is_file_valid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;

class DuplicateRemoverProvider extends StateNotifier<ClutterState> {
  final BuildContext context;
  
  DuplicateRemoverProvider(this.context, ClutterState initialState) : super(initialState);

  Future<void> findDuplicates() async {
    debugPrint('Finding Duplicates...');
    try {
      state = state.copyWith(
        isScanning: true,
        currentAction: "Scanning for duplicates...",
        totalFiles: state.selectedFiles.length,
        scannedFiles: 0,
        duplicateFiles: {}, // Reset duplicates before new scan
      );

      final Map<String, List<File>> fileHashes = {};

      for (int i = 0; i < state.selectedFiles.length; i++) {
        debugPrint('Scanning file: ${state.selectedFiles[i].path}');
        final entity = state.selectedFiles[i];
        
        if (entity is File) {
          state = state.copyWith(
            scannedFiles: i + 1,
            currentAction: "Scanning: ${entity.path}",
            isScanning: true, // Preserve scanning state
            duplicateFiles: state.duplicateFiles, // Preserve existing duplicates
            totalFiles: state.totalFiles, // Preserve total files count
          );
          
          final isValid = await isFileValid(entity);
          if (!isValid) continue;
          
          final checksum = await calculateMD5(entity);
          
          if (!fileHashes.containsKey(checksum)) {
            fileHashes[checksum] = [];
          }
          fileHashes[checksum]?.add(entity);
        }
      }
      
      // Filter and update duplicate files
      final duplicates = Map<String, List<File>>.fromEntries(
        fileHashes.entries.where((entry) => entry.value.length > 1)
      );

      debugPrint('Before state update - Current duplicates: ${state.duplicateFiles}');
      
      state = state.copyWith(
        isScanning: false,
        currentAction: "Found ${duplicates.length} groups of duplicates",
        duplicateFiles: duplicates,
      );

      debugPrint('After state update - New duplicates: ${state.duplicateFiles}');
      debugPrint('Found ${duplicates.length} groups of duplicates');
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        currentAction: "",
        duplicateFiles: {}, // Clear duplicates on error
      );
      debugPrint('Error finding duplicates: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding duplicates: $e')),
      );
    }
  }
  
  Future<void> removeDuplicates() async {
    int count = 0;
    final failedRemoval = <String>[];
    
    for (final entry in state.duplicateFiles.entries) {
      final files = entry.value;
      
      // Keep the first file, remove duplicates
      for (int i = 1; i < files.length; i++) {
        // Show confirmation dialog before removal
        // ignore: use_build_context_synchronously
        final shouldRemove = await confirmRemoval(context, files[i].path);
        
        if (shouldRemove) {
          try {
            await files[i].delete();
            count++;
          } catch (e) {
            failedRemoval.add(files[i].path);
          }
        }
      }
    }
    
    // Show results
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed $count duplicate files. ${failedRemoval.isNotEmpty ? "${failedRemoval.length} files failed to delete." : ""}'),
        duration: const Duration(seconds: 5),
      ),
    );
    
    // Rescan to update the UI
    await findDuplicates();
  }

  Future<void> removeAllDuplicates(BuildContext context) async {
    // Confirm before bulk deletion
    final shouldRemoveAll = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Removal'),
        content: const Text('Are you sure you want to delete ALL duplicate files? This will keep the original file from each group and remove all duplicates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All Duplicates'),
          ),
        ],
      ),
    );
    
    if (shouldRemoveAll != true) return;
    
    int count = 0;
    final failedRemoval = <String>[];
    
    state = state.copyWith(
      isScanning: true,
      currentAction: "Removing duplicates...",
      scannedFiles: 0,
      totalFiles: state.duplicateFiles.values.fold<int>(
        0, (prev, files) => prev + files.length - 1)
    );
    
    int processed = 0;
    for (final entry in state.duplicateFiles.entries) {
      final files = entry.value;
      
      for (int i = 1; i < files.length; i++) {
        try {
          state = state.copyWith(
            scannedFiles: processed + 1,
            currentAction: "Removing: ${files[i].path}"
          );
          
          await files[i].delete();
          count++;
        } catch (e) {
          failedRemoval.add(files[i].path);
        }
        processed++;
      }
    }
    
    // After deleting all files
    state = state.copyWith(isScanning: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed $count duplicate files. ${failedRemoval.isNotEmpty ? "${failedRemoval.length} files failed to delete." : ""}'),
        duration: const Duration(seconds: 5),
      ),
    );
    
    // Clear duplicates instead of rescanning
    clearDuplicates();
  }

  void removeDuplicateGroup(String hash,) {
    state = state.copyWith(
      duplicateFiles: Map.from(state.duplicateFiles)..remove(hash),
    );
  }
  
  void clearDuplicates() {
    state = state.copyWith(
      duplicateFiles: {},
    );
  }
}

final duplicateRemoverNotifierProvider = StateNotifierProvider.family<DuplicateRemoverProvider, ClutterState, BuildContext>(
  (ref, context) {
    final clutterState = ref.watch(clutterNotifierProvider(context));
    return DuplicateRemoverProvider(context, clutterState);
  }
);


