import 'dart:io';
import 'dart:ui';

import 'package:clutter_cut/providers/clutter_provider.dart';
import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:clutter_cut/utils/confirm_dialog.dart';
import 'package:clutter_cut/utils/get_file_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FileDuplicateRemoverScreen extends ConsumerStatefulWidget {
  const FileDuplicateRemoverScreen({super.key});

  @override
  ConsumerState<FileDuplicateRemoverScreen> createState() => _FileDuplicateRemoverScreenState();
}

class _FileDuplicateRemoverScreenState extends ConsumerState<FileDuplicateRemoverScreen> {
  final Map<int, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    ref.read(clutterNotifierProvider(context).notifier).requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final duplicateState = ref.watch(duplicateRemoverNotifierProvider(context));
    final duplicateRemover = ref.watch(duplicateRemoverNotifierProvider(context).notifier);

    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;
    final errorColor = colorScheme.error;
    final iconColor = colorScheme.onSurface;

    debugPrint('Scanned Files Display: ${duplicateState.scannedFiles}');

    final duplicateCount = duplicateState.duplicateFiles.keys.length;
    debugPrint('Duplicate Files Display: $duplicateCount');
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text('ClutterCut', style: TextStyle().copyWith(fontWeight: FontWeight.bold),),
              background: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(side: BorderSide.none),
                color: Theme.of(context).cardColor,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  elevation: .5,
                  shadowColor: Theme.of(context).scaffoldBackgroundColor,
                  color: Theme.of(context).cardColor,
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
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.secondary),
                                foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.secondaryContainer),
                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                              ),
                              onPressed: duplicateState.isScanning
                                  ? null 
                                  : () async {
                                    ref.read(clutterNotifierProvider(context).notifier).selectDirectory();
                                    // await duplicateRemover.findDuplicates();
                                  },
                              icon: SvgPicture.asset('assets/svgs/dir.svg', color: Theme.of(context).colorScheme.secondaryContainer),
                              label: const Text('Select Directory'),
                            ),
                            const SizedBox(width: 8),
                            if (duplicateCount > 0)
                              ElevatedButton.icon(
                                iconAlignment: IconAlignment.end,
                                onPressed: duplicateState.isScanning
                                    ? null 
                                    : () async {
                                      duplicateRemover.removeAllDuplicates(context);
                                      // await duplicateRemover.findDuplicates();
                                    },
                                icon: const Icon(Icons.cleaning_services),
                                label: const Text('Remove All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: errorColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          borderRadius: BorderRadius.circular(5),
                          backgroundColor: primaryColor.withOpacity(0.1),
                          color: primaryColor,
                          value: duplicateState.totalFiles > 0 
                              ? duplicateState.scannedFiles / duplicateState.totalFiles 
                              : 0,
                        ),
                        const SizedBox(height: 4),
                        Text('${duplicateState.scannedFiles} / ${duplicateState.totalFiles}'),
                      ],
                    ),
                  ),
                
                duplicateState.duplicateFiles.isEmpty
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      key: ValueKey('no-duplicates'),
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
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: AnimationLimiter(
                      key: ValueKey('duplicate-list-${duplicateState.duplicateFiles.length}'),
                      child: ListView.separated(
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: duplicateState.duplicateFiles.length,
                        itemBuilder: (context, index) {
                          final hash = duplicateState.duplicateFiles.keys.elementAt(index);
                          final files = duplicateState.duplicateFiles[hash]!;
                          
                          // Safely get file size with error handling
                          String totalSize = 'Unknown';
                          if (files.isNotEmpty) {
                            try {
                              final fileSize = files.first.lengthSync() / 1024;
                              totalSize = '${fileSize.toStringAsFixed(2)} KB';
                            } catch (e) {
                              // File might have been deleted or is inaccessible
                              debugPrint('Error getting file size: $e');
                            }
                          }
                          
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 450),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Card(
                                  elevation: .5,
                                  color: Theme.of(context).cardColor,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ExpansionTile(
                                    iconColor: iconColor,
                                    backgroundColor: Theme.of(context).cardColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
                                    title: Text('Duplicate Group ${index + 1}'),
                                    subtitle: Text('${files.length} identical files • Size: $totalSize'),
                                    leading: _expandedStates[index] == true 
                                      ? SvgPicture.asset('assets/svgs/folder-open.svg', color: iconColor)
                                      : SvgPicture.asset('assets/svgs/dir.svg', color: iconColor),
                                    onExpansionChanged: (value) {
                                      setState(() {
                                        _expandedStates[index] = value;
                                      });
                                    },
                                    children: files.map((file) {
                                      final isOriginal = files.indexOf(file) == 0;
                                      
                                      // Check if file still exists before displaying
                                      bool fileExists = false;
                                      try {
                                        fileExists = file.existsSync();
                                      } catch (e) {
                                        debugPrint('Error checking if file exists: $e');
                                      }
                                      
                                      if (!fileExists) {
                                        // Return an error placeholder for missing files
                                        return ListTile(
                                          title: Text(
                                            file.path.split(Platform.pathSeparator).last,
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                          subtitle: Text(
                                            'File no longer exists',
                                            style: TextStyle(fontSize: 12, color: errorColor),
                                          ),
                                          leading: Icon(Icons.error_outline, color: errorColor),
                                        );
                                      }
                                      
                                      return ListTile(
                                        title: Text(
                                          file.path.split(Platform.pathSeparator).last, 
                                          style: TextStyle(fontWeight: isOriginal ? FontWeight.bold : FontWeight.normal)
                                        ),
                                        subtitle: Text(
                                          file.path, 
                                          style: const TextStyle(fontSize: 12)
                                        ),
                                        leading: Container(
                                          padding: EdgeInsets.all(5),
                                          width: 33,
                                          height: 33,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isOriginal? Colors.grey.shade100 : Colors.grey.shade200,
                                          ),
                                          child: getFileIcon(context, getFileExtension(file.path))),
                                        trailing: isOriginal
                                          ? SizedBox(
                                            height: 33,
                                            child: TextButton(
                                              style: ButtonStyle(
                                                foregroundColor: WidgetStatePropertyAll(secondaryColor),
                                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                                backgroundColor: WidgetStatePropertyAll(secondaryColor.withOpacity(0.1)),
                                              ),
                                                onPressed: null,
                                                child: Text('Original',),
                                              ),
                                          )
                                          : SizedBox(
                                            height: 33,
                                            child: TextButton(
                                              style: ButtonStyle(
                                                foregroundColor: WidgetStatePropertyAll(errorColor),
                                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                                backgroundColor: WidgetStatePropertyAll(errorColor.withOpacity(0.1)),
                                              ),
                                                child: Text('Delete',),
                                                onPressed: () async {
                                                  final confirm = await confirmRemoval(context, file.path);
                                                  if (confirm) {
                                                    // Delete the file
                                                    file.deleteSync();
                                                    
                                                    // Update the state locally
                                                    setState(() {
                                                      // Remove the file from the duplicates list
                                                      final filesList = duplicateState.duplicateFiles[hash]!.toList();
                                                      filesList.remove(file);
                                                      
                                                      // If there's only one file left, it's no longer a duplicate
                                                      if (filesList.length <= 1) {
                                                        duplicateRemover.removeDuplicateGroup(hash);
                                                      }
                                                    });
                                                    
                                                    // Show a snackbar to confirm deletion
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('File deleted'),
                                                        backgroundColor: errorColor,
                                                        duration: Duration(seconds: 1),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                          ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                            )));
                                  },
                                ),
                    ))
              ],
            ),
        ),
      ),
    ])
    );
  }
}

