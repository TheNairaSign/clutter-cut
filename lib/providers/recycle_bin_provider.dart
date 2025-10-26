import 'dart:convert';
import 'dart:io';

import 'package:clutter_cut/core/events.dart';
import 'package:clutter_cut/models/recycled_file.dart';
import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Represents the state of the recycle bin, including the list of recycled files,
/// loading status, and the current action being performed.
class RecycleBinState {
  final List<RecycledFile> recycledFiles;
  final bool isLoading;
  final String currentAction;

  const RecycleBinState({
    required this.recycledFiles,
    this.isLoading = false,
    this.currentAction = '',
  });

  RecycleBinState copyWith({
    List<RecycledFile>? recycledFiles,
    bool? isLoading,
    String? currentAction,
  }) {
    return RecycleBinState(
      recycledFiles: recycledFiles ?? this.recycledFiles,
      isLoading: isLoading ?? this.isLoading,
      currentAction: currentAction ?? this.currentAction,
    );
  }
}

/// Manages the state and logic for the recycle bin feature.
///
/// This notifier handles moving files to the recycle bin, restoring them,
/// permanently deleting them, and managing the recycle bin's lifecycle.
class RecycleBinNotifier extends StateNotifier<RecycleBinState> {
  final Ref ref;
  
  RecycleBinNotifier(this.ref) : super(const RecycleBinState(recycledFiles: [])) {
    // Load recycled files when the notifier is created
    _loadRecycledFiles();
  }

  /// Gets the path to the recycle bin directory within the app's documents directory.
  /// Creates the directory if it doesn't exist.
  Future<String> get _recycleBinPath async {
    final appDir = await getApplicationDocumentsDirectory();
    final binPath = path.join(appDir.path, 'recycle_bin');
    debugPrint('Recycle bin path: $binPath');
    
    // Ensure the directory exists
    final binDir = Directory(binPath);
    if (!await binDir.exists()) {
      debugPrint('Creating recycle bin directory');
      await binDir.create(recursive: true);
    }
    
    return binPath;
  }

  /// Gets the path to the JSON file that stores the index of recycled files.
  Future<String> get _recycleBinIndexPath async {
    final appDir = await getApplicationDocumentsDirectory();
    final indexPath = path.join(appDir.path, 'recycle_bin_index.json');
    debugPrint('Recycle bin index path: $indexPath');
    return indexPath;
  }

  /// Loads the list of recycled files from the JSON index file.
  /// This method is called when the notifier is initialized.
  Future<void> _loadRecycledFiles() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final indexPath = await _recycleBinIndexPath;
      final indexFile = File(indexPath);
      
      if (!await indexFile.exists()) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final String jsonContent = await indexFile.readAsString();
      final List<dynamic> jsonList = json.decode(jsonContent);
      
      final List<RecycledFile> files = jsonList
          .map((json) => RecycledFile.fromJson(json))
          .where((file) => !file.isExpired)  // Filter out expired files
          .toList();

      state = state.copyWith(
        recycledFiles: files,
        isLoading: false,
      );

      // Clean up expired files
      _cleanupExpiredFiles();
      
    } catch (e) {
      debugPrint('Error loading recycled files: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Saves the current list of recycled files to the JSON index file.
  Future<void> _saveRecycledFiles() async {
    try {
      final indexPath = await _recycleBinIndexPath;
      final indexFile = File(indexPath);
      
      final jsonContent = json.encode(
        state.recycledFiles.map((file) => file.toJson()).toList(),
      );
      
      await indexFile.writeAsString(jsonContent);
    } catch (e) {
      debugPrint('Error saving recycled files: $e');
    }
  }

  /// Moves a file to the recycle bin.
  ///
  /// This involves copying the file to the recycle bin directory, deleting the original,
  /// and adding a record to the recycle bin index.
  Future<void> moveToRecycleBin(File file) async {
    try {
      debugPrint('Moving file to recycle bin: ${file.path}');
      
      // First check if the source file exists and is accessible
      if (!await file.exists()) {
        throw Exception('Source file does not exist: ${file.path}');
      }
      
      state = state.copyWith(
        isLoading: true,
        currentAction: 'Moving ${file.path} to recycle bin...',
      );

      // Get and create recycle bin path
      final recycleBinPath = await _recycleBinPath;
      debugPrint('Using recycle bin path: $recycleBinPath');
      
      final recycleBinDir = Directory(recycleBinPath);
      if (!await recycleBinDir.exists()) {
        debugPrint('Creating recycle bin directory');
        await recycleBinDir.create(recursive: true);
      }

      // Generate unique path for the file in recycle bin
      final String recyclePath = await _getRecyclePathForFile(file);
      debugPrint('Generated recycle path: $recyclePath');

      // Get file size before moving
      final fileSize = await file.length();
      debugPrint('File size: $fileSize bytes');

      // Copy file to recycle bin
      debugPrint('Copying file to recycle bin...');
      final recycledFile = await file.copy(recyclePath);
      
      if (!await recycledFile.exists()) {
        throw Exception('Failed to copy file to recycle bin');
      }

      // Verify the copied file size matches
      final recycledSize = await recycledFile.length();
      if (recycledSize != fileSize) {
        await recycledFile.delete();
        throw Exception('File size mismatch after copy');
      }

      // Delete original file
      debugPrint('Deleting original file...');
      await file.delete();

      // Create and save recycled file record
      final recycledRecord = RecycledFile(
        originalPath: file.path,
        recyclePath: recyclePath,
        deletedAt: DateTime.now(),
        fileSize: fileSize,
      );

      state = state.copyWith(
        recycledFiles: [...state.recycledFiles, recycledRecord],
        isLoading: false,
        currentAction: '',
      );

      debugPrint('Saving recycle bin index...');
      await _saveRecycledFiles();
      
      debugPrint('File successfully moved to recycle bin');
      ref.read(uiEventProvider.notifier).state = ShowSnackbar(
        'File moved to recycle bin: ${path.basename(file.path)}',
      );
      
    } catch (e, stackTrace) {
      debugPrint('Error moving file to recycle bin: $e');
      debugPrint('Stack trace: $stackTrace');
      ref.read(uiEventProvider.notifier).state = ShowSnackbar(
        'Error moving file to recycle bin: $e',
        isError: true,
      );
      state = state.copyWith(isLoading: false);
      rethrow; // Rethrow to let the caller handle the error
    }
  }

  /// Generates a unique path for a file in the recycle bin to avoid name collisions.
  Future<String> _getRecyclePathForFile(File file) async {
    final recycleBinPath = await _recycleBinPath;
    final fileName = path.basename(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(recycleBinPath, '${timestamp}_$fileName');
  }

  /// Restores a file from the recycle bin to its original location.
  Future<void> restoreFile(RecycledFile recycledFile) async {
    try {
      state = state.copyWith(
        isLoading: true,
        currentAction: 'Restoring ${recycledFile.originalPath}...',
      );

      final recycledFilePath = recycledFile.recyclePath;
      final originalPath = recycledFile.originalPath;

      // Ensure original directory exists
      final originalDir = Directory(path.dirname(originalPath));
      if (!await originalDir.exists()) {
        await originalDir.create(recursive: true);
      }

      // Restore file to original location
      await File(recycledFilePath).copy(originalPath);
      await File(recycledFilePath).delete();

      // Remove from recycled files list
      state = state.copyWith(
        recycledFiles: state.recycledFiles
            .where((file) => file.recyclePath != recycledFile.recyclePath)
            .toList(),
        isLoading: false,
        currentAction: '',
      );

      await _saveRecycledFiles();

      ref.read(uiEventProvider.notifier).state = ShowSnackbar(
        'File restored successfully',
      );
      
      ref.watch(duplicateRemoverNotifierProvider.notifier).findDuplicatesByHashing();
      
    } catch (e) {
      debugPrint('Error restoring file: $e');
      ref.read(uiEventProvider.notifier).state = ShowSnackbar(
        'Error restoring file: $e',
        isError: true,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Permanently deletes a file from the recycle bin.
  Future<void> permanentlyDeleteFile(RecycledFile recycledFile) async {
    try {
      state = state.copyWith(
        isLoading: true,
        currentAction: 'Permanently deleting ${recycledFile.originalPath}...',
      );

      // Delete the file from recycle bin
      await File(recycledFile.recyclePath).delete();

      // Remove from recycled files list
      state = state.copyWith(
        recycledFiles: state.recycledFiles
            .where((file) => file.recyclePath != recycledFile.recyclePath)
            .toList(),
        isLoading: false,
        currentAction: '',
      );

      await _saveRecycledFiles();

      ref.read(uiEventProvider.notifier).state = ShowSnackbar(
        'File permanently deleted',
      );
      
    } catch (e) {
      debugPrint('Error permanently deleting file: $e');
      ref.read(uiEventProvider.notifier).state = ShowSnackbar(
        'Error permanently deleting file: $e',
        isError: true,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Deletes files from the recycle bin that have passed their expiration date.
  Future<void> _cleanupExpiredFiles() async {
    try {
      final expiredFiles = state.recycledFiles.where((file) => file.isExpired);
      
      for (final file in expiredFiles) {
        try {
          await File(file.recyclePath).delete();
        } catch (e) {
          debugPrint('Error deleting expired file ${file.recyclePath}: $e');
        }
      }

      // Update state to remove expired files
      state = state.copyWith(
        recycledFiles: state.recycledFiles.where((file) => !file.isExpired).toList(),
      );

      await _saveRecycledFiles();
      
    } catch (e) {
      debugPrint('Error cleaning up expired files: $e');
    }
  }

  /// Permanently deletes all files currently in the recycle bin.
  Future<void> emptyRecycleBin() async {
    try {
      state = state.copyWith(
        isLoading: true,
        currentAction: 'Emptying recycle bin...',
      );

      // Delete all files in the recycle bin
      for (final file in state.recycledFiles) {
        try {
          await File(file.recyclePath).delete();
        } catch (e) {
          debugPrint('Error deleting file ${file.recyclePath}: $e');
        }
      }

      // Clear the recycled files list
      state = state.copyWith(
        recycledFiles: [],
        isLoading: false,
        currentAction: '',
      );

      await _saveRecycledFiles();

      ref.read(uiEventProvider.notifier).state = ShowSnackbar(
        'Recycle bin emptied',
      );
      
    } catch (e) {
      debugPrint('Error emptying recycle bin: $e');
      ref.read(uiEventProvider.notifier).state = ShowSnackbar(
        'Error emptying recycle bin: $e',
        isError: true,
      );
      state = state.copyWith(isLoading: false);
    }
  }
}

/// Provider for accessing the [RecycleBinNotifier].
final recycleBinProvider = StateNotifierProvider<RecycleBinNotifier, RecycleBinState>(
  (ref) => RecycleBinNotifier(ref),
);