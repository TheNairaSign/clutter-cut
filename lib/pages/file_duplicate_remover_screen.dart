import 'package:clutter_cut/core/events.dart';
import 'package:clutter_cut/providers/clutter_provider.dart';
import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:clutter_cut/widgets/duplicate_files_list.dart';
import 'package:clutter_cut/widgets/scanning_progress_indicator.dart';
import 'package:clutter_cut/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class FileDuplicateRemoverScreen extends ConsumerStatefulWidget {
  const FileDuplicateRemoverScreen({super.key});

  @override
  ConsumerState<FileDuplicateRemoverScreen> createState() => _FileDuplicateRemoverScreenState();
}

class _FileDuplicateRemoverScreenState extends ConsumerState<FileDuplicateRemoverScreen> {

  @override
  void initState() {
    super.initState();
    ref.read(clutterNotifierProvider.notifier).requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final duplicateState = ref.watch(duplicateRemoverNotifierProvider);
    final duplicateRemover = ref.watch(duplicateRemoverNotifierProvider.notifier);

    // Listener for UI events (Snackbars, Dialogs)
    ref.listen<UiEvent?>(uiEventProvider, (previous, next) {
      if (next != null) {
        final event = next;
        if (event is ShowSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event.message),
              backgroundColor: event.isError ? Colors.red : Colors.green,
            ),
          );
        } else if (event is ShowBulkDeleteConfirmation) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Bulk Removal'),
              content: const Text('Are you sure you want to delete ALL duplicate files? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    duplicateRemover.confirmBulkDelete();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete All'),
                ),
              ],
            ),
          );
        } else if (event is ShowFileDeleteConfirmation) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text('Are you sure you want to delete ${event.file.path}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    duplicateRemover.confirmRemoveFile(event.file);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        }
        // Reset the event provider so the event isn't handled again
        ref.read(uiEventProvider.notifier).state = null;
      }
    });

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
              title: Text('ClutterCut', style: TextStyle().copyWith(fontWeight: FontWeight.bold)),
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
                SummaryCard(),
                
                if (duplicateState.isScanning)
                  ScanningProgressIndicator(),
                
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
                      child: DuplicateFilesList(),
                    )
                  )
                ],
              ),
            ),
          ),
        ]
      )
    );
  }
}

