import 'dart:io';
import 'dart:math';

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
    // Confirmation dialog
    final shouldRemoveAll = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Removal'),
        content: const Text('Are you want to delete ALL duplicate files? This will keep the original file from each group and remove all duplicates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All Duplicates'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (shouldRemoveAll != true) return;
    
    // Initialize deletion progress
    final totalDuplicates = state.duplicateFiles.values.fold<int>(
      0, (prev, files) => prev + files.length - 1
    );
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Removing Duplicates'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sliding animation for duplicates
                  SizedBox(
                    height: 150,
                    width: 250,
                    child: Stack(
                      children: [
                        // Static icon at the top
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                            size: 48,
                          ),
                        ),
                        
                        // Animated sliding items
                        AnimatedBuilder(
                          animation: ValueNotifier<int>(state.scannedFiles),
                          builder: (context, child) {
                            return Stack(
                              children: List.generate(
                                min(5, totalDuplicates - state.scannedFiles + 5),
                                (index) => TweenAnimationBuilder(
                                  tween: Tween<Offset>(
                                    begin: Offset(0, 0),
                                    end: index == 0 ? Offset(1.5, 0) : Offset(0, 0),
                                  ),
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeOutQuad,
                                  onEnd: () {
                                    if (index == 0) {
                                      setDialogState(() {});
                                    }
                                  },
                                  builder: (context, Offset offset, child) {
                                    return Positioned(
                                      left: 20 + (offset.dx * 200),
                                      bottom: 20 + (index * 20),
                                      child: Transform.translate(
                                        offset: offset,
                                        child: Container(
                                          width: 180,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator
                  LinearProgressIndicator(
                    value: state.scannedFiles / max(totalDuplicates, 1),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${state.scannedFiles} / $totalDuplicates files deleted',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    // Update state to start deletion process
    state = state.copyWith(
      isScanning: true,
      currentAction: "Removing duplicates...",
      scannedFiles: 0,
      totalFiles: totalDuplicates
    );
    
    int count = 0;
    final failedRemoval = <String>[];
    
    // Process each duplicate group
    int processed = 0;
    for (final entry in state.duplicateFiles.entries) {
      final files = entry.value;
      
      for (int i = 1; i < files.length; i++) {
        try {
          // Update state with current file being processed
          state = state.copyWith(
            scannedFiles: processed + 1,
            currentAction: "Removing: ${files[i].path}"
          );
          
          // Delete file with a small delay for smoother animation
          await Future.delayed(const Duration(milliseconds: 100));
          await files[i].delete();
          count++;
        } catch (e) {
          failedRemoval.add(files[i].path);
        }
        processed++;
      }
    }
    
    // Dismiss progress dialog
    Navigator.of(context, rootNavigator: true).pop();
    
    // Final state update
    state = state.copyWith(isScanning: false);
    
    // Show results snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Removed $count duplicate files. '
          '${failedRemoval.isNotEmpty ? "${failedRemoval.length} files failed to delete." : ""}',
        ),
        backgroundColor: count > 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
    
    // Clear duplicates
    clearDuplicates();
  }

  void clearDuplicates() {
    state = state.copyWith(
      duplicateFiles: {},
    );
  }

  void removeDuplicateGroup(String hash,) {
    state = state.copyWith(
      duplicateFiles: Map.from(state.duplicateFiles)..remove(hash),
    );
  }
}
  

final duplicateRemoverNotifierProvider = StateNotifierProvider.family<DuplicateRemoverProvider, ClutterState, BuildContext>(
  (ref, context) {
    final clutterState = ref.watch(clutterNotifierProvider(context));
    return DuplicateRemoverProvider(context, clutterState);
  }
);


