import 'dart:io';

import 'package:clutter_cut/core/events.dart';
import 'package:clutter_cut/providers/clutter_provider.dart';
import 'package:clutter_cut/providers/recycle_bin_provider.dart';
import 'package:clutter_cut/providers/state/clutter_state.dart';
import 'package:clutter_cut/utils/calculate_md5.dart';
import 'package:clutter_cut/utils/is_file_valid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;

/// Manages the state and logic for finding and removing duplicate files.
///
/// This provider is responsible for hashing files to identify duplicates,
/// and for handling the removal of these files (by moving them to the recycle bin).
class DuplicateRemoverProvider extends StateNotifier<ClutterState> {
  final Ref ref;

  DuplicateRemoverProvider(this.ref): super(ClutterState(
    selectedFiles: [],
    duplicateFiles: {},
    isScanning: false, 
    totalFiles: 0, 
    scannedFiles: 0, 
    currentAction: '',
    isFullScan: false,
  ));

  /// Hashes a list of files to find duplicates based on their MD5 checksum.
  ///
  /// This method is typically called after a preliminary scan has identified
  /// files of the same size.
  Future<void> findDuplicatesByHashing() async {
    debugPrint('Hashing potential duplicates...');
    
    // Get selected files and ensure they are all File objects
    final selectedFiles = ref.read(clutterNotifierProvider).selectedFiles;
    final filesToHash = selectedFiles.whereType<File>().toList();
    
    try {
      if (filesToHash.isEmpty) {
        state = state.copyWith(
          isScanning: false,
          currentAction: "No duplicates found.",
        );
        ref.read(uiEventProvider.notifier).state = const ShowSnackbar('No potential duplicates found after filtering by size.');
        return;
      }

      state = state.copyWith(
        isScanning: true,
        totalFiles: filesToHash.length,
        scannedFiles: 0,
        currentAction: "Hashing ${filesToHash.length} potential duplicates...",
        duplicateFiles: {}, // Reset
      );

      final Map<String, List<File>> fileHashes = {};
      for (int i = 0; i < filesToHash.length; i++) {
        final file = filesToHash[i];
        
        final isValid = await isFileValid(file);
        if (!isValid) {
          state = state.copyWith(scannedFiles: i + 1);
          continue;
        }

        state = state.copyWith(
          scannedFiles: i + 1,
          currentAction: "Hashing: ${file.path}",
        );
        
        final checksum = await calculateMD5(file);
        
        if (!fileHashes.containsKey(checksum)) {
          fileHashes[checksum] = [];
        }
        fileHashes[checksum]?.add(file);
      }
      
      final duplicates = Map<String, List<File>>.fromEntries(fileHashes.entries.where((entry) => entry.value.length > 1));

      state = state.copyWith(
        isScanning: false,
        currentAction: "Found ${duplicates.length} groups of duplicates",
        duplicateFiles: duplicates,
      );
      ref.read(uiEventProvider.notifier).state = ShowSnackbar('Scan complete. Found ${duplicates.length} groups of duplicates.');

    } catch (e) {
      ref.read(uiEventProvider.notifier).state = ShowSnackbar('Error finding duplicates: $e', isError: true);
      state = state.copyWith(
        isScanning: false,
        currentAction: "Error finding duplicates: $e",
        duplicateFiles: {}, // Clear duplicates on error
      );
    }
  }
  
  /// Requests the removal of a single file by showing a confirmation dialog.
  void requestRemoveFile(File file) {
    ref.read(uiEventProvider.notifier).state = ShowFileDeleteConfirmation(file);
  }

  /// Confirms the removal of a single file and moves it to the recycle bin.
  Future<void> confirmRemoveFile(File file) async {
    try {
      // Get the hash of the file to be deleted
      final checksum = await calculateMD5(file);

      // Move to recycle bin instead of deleting
      await ref.read(recycleBinProvider.notifier).moveToRecycleBin(file);

      // Get the current list of duplicates
      final currentDuplicates = Map<String, List<File>>.from(state.duplicateFiles);

      // Find the group of duplicates that the file belongs to
      if (currentDuplicates.containsKey(checksum)) {
        // Remove the file from the group
        currentDuplicates[checksum]!.removeWhere((f) => f.path == file.path);

        // If the group now has less than 2 files, remove the group
        if (currentDuplicates[checksum]!.length < 2) {
          currentDuplicates.remove(checksum);
        }

        // Update the state
        state = state.copyWith(duplicateFiles: currentDuplicates);
      }
    } catch (e) {
      ref.read(uiEventProvider.notifier).state = ShowSnackbar('Error removing ${file.path}: $e', isError: true);
    }
  }

  /// Requests the bulk deletion of all found duplicate files.
  void requestBulkDelete() {
    if (state.duplicateFiles.isEmpty) {
      ref.read(uiEventProvider.notifier).state = const ShowSnackbar('No duplicates to delete.');
      return;
    }
    ref.read(uiEventProvider.notifier).state = const ShowBulkDeleteConfirmation();
  }

  /// Confirms the bulk deletion and moves all duplicate files to the recycle bin.
  Future<void> confirmBulkDelete() async {
    final totalDuplicates = state.duplicateFiles.values.fold<int>(0, (prev, files) => prev + files.length - 1);
    
    state = state.copyWith(
      isScanning: true,
      currentAction: "Moving duplicates to recycle bin...",
      scannedFiles: 0,
      totalFiles: totalDuplicates
    );
    
    int count = 0;
    int failedCount = 0;
    
    int processed = 0;
    final entries = List.from(state.duplicateFiles.entries);
    final recycleBin = ref.read(recycleBinProvider.notifier);

    for (final entry in entries) {
      final files = entry.value;
      
      for (int i = 1; i < files.length; i++) {
        try {
          state = state.copyWith(
            scannedFiles: processed + 1,
            currentAction: "Moving to recycle bin: ${files[i].path}"
          );
          
          await recycleBin.moveToRecycleBin(files[i]);
          count++;
        } catch (e) {
          failedCount++;
          debugPrint('Failed to move ${files[i].path} to recycle bin: $e');
        }
        processed++;
      }
    }
    
    state = state.copyWith(
      isScanning: false,
      currentAction: "Removed $count duplicate files.",
      duplicateFiles: {}, // Clear duplicates from state
    );

    String message = 'Removed $count duplicate files.';
    if (failedCount > 0) {
      message += ' $failedCount files failed to delete.';
    }
    ref.read(uiEventProvider.notifier).state = ShowSnackbar(message, isError: failedCount > 0);
  }

  /// Clears the list of duplicate files from the state.
  void clearDuplicates() {
    state = state.copyWith(
      duplicateFiles: {},
      selectedFiles: [],
      currentAction: '',
    );
  }

  /// Removes a specific group of duplicate files from the state.
  void removeDuplicateGroup(String hash,) {
    state = state.copyWith(
      duplicateFiles: Map.from(state.duplicateFiles)..remove(hash),
    );
  }
}

/// Provider for accessing the [DuplicateRemoverProvider].
///
/// This provider also listens to the [clutterNotifierProvider] to automatically
/// trigger the hashing process when a new list of potential duplicates is available.
final duplicateRemoverNotifierProvider = StateNotifierProvider<DuplicateRemoverProvider, ClutterState>((ref) {
  final provider = DuplicateRemoverProvider(ref);

  // Listen to the clutter provider. When it produces a new, non-empty list of
  // files to scan, this provider will automatically start the hashing process.
  ref.listen(clutterNotifierProvider.select((state) => state.selectedFiles), (previous, next) {
    // The check for previous != next ensures it doesn't run unnecessarily on rebuilds.
    print('Selected files changed: $previous -> $next');
    if (next.isNotEmpty && previous != next) {
      provider.findDuplicatesByHashing();
    }
  });

  return provider;
});
