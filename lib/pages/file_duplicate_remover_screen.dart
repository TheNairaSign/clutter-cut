// Import necessary packages for the duplicate-remover screen
import 'package:clutter_cut/core/background_task.dart';
import 'package:clutter_cut/core/events.dart';
import 'package:clutter_cut/pages/settings_page.dart';
import 'package:clutter_cut/providers/clutter_provider.dart';
import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:clutter_cut/widgets/duplicate_files_list.dart';
import 'package:clutter_cut/widgets/full_screen_scanning_indicator.dart';
import 'package:clutter_cut/widgets/recycle_bin_view.dart';
import 'package:clutter_cut/widgets/scanning_progress_indicator.dart';
import 'package:clutter_cut/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';

/// Main screen for duplicate file removal functionality.
/// Uses Riverpod for state management and reacts to UI events.
class FileDuplicateRemoverScreen extends ConsumerStatefulWidget {
  const FileDuplicateRemoverScreen({super.key});

  @override
  ConsumerState<FileDuplicateRemoverScreen> createState() =>
      _FileDuplicateRemoverScreenState();
}

class _FileDuplicateRemoverScreenState extends ConsumerState<FileDuplicateRemoverScreen> {
  @override
  void initState() {
    super.initState();
    // Initialization logic can be added here if needed
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers to get current state
    final clutterState = ref.watch(clutterNotifierProvider);
    final duplicateState = ref.watch(duplicateRemoverNotifierProvider);
    final duplicateRemover =
        ref.watch(duplicateRemoverNotifierProvider.notifier);
    final clutterNotifier = ref.watch(clutterNotifierProvider.notifier);

    // Determine scanning state and progress based on which provider is active
    final isScanning = clutterState.isScanning || duplicateState.isScanning;
    final currentAction = clutterState.isScanning ? clutterState.currentAction : duplicateState.currentAction;
    final scannedFiles = clutterState.isScanning ? clutterState.scannedFiles : duplicateState.scannedFiles;
    final totalFiles = clutterState.isScanning ? clutterState.totalFiles : duplicateState.totalFiles;

    // Listener for UI events (Snackbars, Dialogs)
    ref.listen<UiEvent?>(uiEventProvider, (previous, next) {
      if (next != null) {
        final event = next;
        if (event is ShowSnackbar) {
          // Show a snackbar with the event message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event.message),
              backgroundColor: event.isError ? Colors.red : Colors.green,
            ),
          );
        } else if (event is ShowBulkDeleteConfirmation) {
          // Show confirmation dialog for bulk deletion of duplicates
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Bulk Removal'),
              content: const Text(
                  'Are you sure you want to delete ALL duplicate files? This cannot be undone.'),
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
          // Show confirmation dialog for deleting a single duplicate file
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
        } else if (event is ShowSettingsDialog) {
          // Show dialog prompting user to open app settings (e.g., for permissions)
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(event.title),
              content: Text(event.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        // Reset the event provider so the event isn't handled again
        ref.read(uiEventProvider.notifier).state = null;
      }
    });

    // Debug prints for development purposes
    debugPrint('Scanned Files Display: ${duplicateState.scannedFiles}');

    final duplicateCount = duplicateState.duplicateFiles.keys.length;
    debugPrint('Duplicate Files Display: $duplicateCount');

    // Determine theme brightness for adaptive UI
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Main UI structure using a Stack to overlay scanning indicator
    return Stack(
      children: [
        Scaffold(
            body: CustomScrollView(slivers: [
          // AppBar with title, recycle-bin shortcut, and settings button
          SliverAppBar(
            floating: true,
            pinned: true,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 15),
            actions: [
              // Recycle bin icon button
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RecycleBinView())),
                child: Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: .3),
                    shape: BoxShape.circle
                    ),
                  child: SvgPicture.asset(
                    isDarkMode
                      ? 'assets/svgs/bins/recycle-bin-white.svg'
                      : 'assets/svgs/bins/recycle-bin-black.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              // const SizedBox(width: 10),
              // GestureDetector(
              //   onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RecycleBinView())),
              //   child: Container(
              //     height: 35,
              //     width: 35,
              //     decoration: BoxDecoration(
              //       color: Colors.grey.withValues(alpha: .3),
              //       shape: BoxShape.circle
              //       ),
              //     child: SvgPicture.asset(
              //       isDarkMode
              //         ? 'assets/svgs/settings-white.svg'
              //         : 'assets/svgs/settings-black.svg',
              //       width: 24,
              //       height: 24,
              //       fit: BoxFit.scaleDown,
              //     ),
              //   ),
              // ),
              // Settings icon button
              IconButton(
                icon: Icon(Icons.settings_outlined),
                style: IconButton.styleFrom(
                  // padding: const EdgeInsets.symmetric(horizontal: 10),
                  // backgroundColor: Colors.grey.withValues(alpha: .3),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
                },
              ),
            ],
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text('ClutterCut', style: const TextStyle().copyWith(fontWeight: FontWeight.bold)),
              background: Card(
                elevation: 0,
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                color: Theme.of(context).cardColor,
              ),
            ),
          ),
          // Main content area with summary, scan buttons, and results
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary card showing scan statistics
                SummaryCard(),
                const SizedBox(height: 16),
                // Row of scan action buttons
                
                const SizedBox(height: 16),
                // Show progress indicator if scanning (non-fullscreen)
                if (isScanning && !clutterState.isFullScan)
                  ScanningProgressIndicator(
                    currentAction: currentAction,
                    scannedFiles: scannedFiles,
                    totalFiles: totalFiles,
                  ),
                // Show results or empty state when not scanning
                if (!isScanning)
                  duplicateState.duplicateFiles.isEmpty
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            key: const ValueKey('no-duplicates'),
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
                            child: const DuplicateFilesList(),
                          ),
                        )
              ]),
            ),
          ),
        ])),
        // Overlay full-screen scanning indicator when a full scan is active
        if (isScanning && clutterState.isFullScan)
          FullScreenScanningIndicator(currentAction: currentAction),
      ],
    );
  }
}