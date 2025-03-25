import 'dart:io';

import 'package:clutter_cut/providers/clutter_provider.dart';
import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:clutter_cut/utils/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileDuplicateRemoverScreen extends ConsumerStatefulWidget {
  const FileDuplicateRemoverScreen({super.key});

  @override
  ConsumerState<FileDuplicateRemoverScreen> createState() => _FileDuplicateRemoverScreenState();
}

class _FileDuplicateRemoverScreenState extends ConsumerState<FileDuplicateRemoverScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(clutterNotifierProvider(context).notifier).requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final duplicateState = ref.watch(duplicateRemoverNotifierProvider(context));
    final duplicateRemover = ref.watch(duplicateRemoverNotifierProvider(context).notifier);

    debugPrint('Scanned Files Display: ${duplicateState.scannedFiles}');

    final duplicateCount = duplicateState.duplicateFiles.keys.length;
    debugPrint('Duplicate Files Display: $duplicateCount');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClutterCut'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Files: ${duplicateState.selectedFiles.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Duplicates Found: $duplicateCount'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: duplicateState.isScanning
                              ? null 
                              : () async {
                                ref.read(clutterNotifierProvider(context).notifier).selectDirectory();
                                await duplicateRemover.findDuplicates();
                              },
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Select Directory'),
                        ),
                        const SizedBox(width: 8),
                        if (duplicateCount > 0)
                          ElevatedButton.icon(
                            onPressed: duplicateState.isScanning 
                                ? null 
                                : () async {
                                  duplicateRemover.removeAllDuplicates(context);
                                  await duplicateRemover.findDuplicates();
                                },
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('Remove All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (duplicateState.isScanning)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(duplicateState.currentAction),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: duplicateState.totalFiles > 0 
                          ? duplicateState.scannedFiles / duplicateState.totalFiles 
                          : 0,
                    ),
                    const SizedBox(height: 4),
                    Text('${duplicateState.scannedFiles} / ${duplicateState.totalFiles}'),
                  ],
                ),
              ),
            
            Expanded(
              child: duplicateState.duplicateFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.find_in_page,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No duplicates found',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select a directory to scan for duplicates',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: duplicateState.duplicateFiles.length,
                      itemBuilder: (context, index) {
                        final hash = duplicateState.duplicateFiles.keys.elementAt(index);
                        final files = duplicateState.duplicateFiles[hash]!;
                        final totalSize = files.isNotEmpty 
                            ? '${(files.first.lengthSync() / 1024).toStringAsFixed(2)} KB'
                            : 'Unknown';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ExpansionTile(
                            title: Text('Duplicate Group #${index + 1}'),
                            subtitle: Text(
                              '${files.length} identical files • Size: $totalSize',
                            ),
                            leading: const Icon(Icons.file_copy),
                            children: files.map((file) {
                              final isOriginal = files.indexOf(file) == 0;
                              
                              return ListTile(
                                title: Text(
                                  file.path.split(Platform.pathSeparator).last,
                                  style: TextStyle(
                                    fontWeight: isOriginal ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  file.path,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                leading: Icon(
                                  Icons.description,
                                  color: isOriginal ? Colors.green : Colors.red,
                                ),
                                trailing: isOriginal
                                    ? const Chip(
                                        label: Text('Original'),
                                        backgroundColor: Colors.green,
                                        labelStyle: TextStyle(color: Colors.white),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await confirmRemoval(context, file.path);
                                          if (confirm) {
                                            await file.delete();
                                            await duplicateRemover.findDuplicates();
                                          }
                                        },
                                      ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}