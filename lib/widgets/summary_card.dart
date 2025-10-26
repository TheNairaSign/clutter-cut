import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:clutter_cut/providers/clutter_provider.dart';

class SummaryCard extends ConsumerWidget {

  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark? Colors.white : Colors.black;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final errorColor = colorScheme.error;

    final duplicateState = ref.watch(duplicateRemoverNotifierProvider);

    final clutterState = ref.watch(clutterNotifierProvider);
    final duplicateCount = duplicateState.duplicateFiles.keys.length;

    final duplicateRemover = ref.watch(duplicateRemoverNotifierProvider.notifier);

    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Files: ${clutterState.selectedFiles.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Duplicates Found: $duplicateCount'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Theme.of(context).scaffoldBackgroundColor),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                    ),
                    onPressed: () {
                      // Trigger full device scan
                      ref.read(clutterNotifierProvider.notifier).scanEntireDevice();
                    },
                    icon: Icon(Icons.sync, color: textColor),
                    label: Text("Scan Device", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Theme.of(context).scaffoldBackgroundColor),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                    ),
                    onPressed: () {
                      // Trigger directory picker for targeted scan
                      ref.read(clutterNotifierProvider.notifier).selectDirectory();
                    },
                    icon: Icon(Icons.folder_open, color: textColor),
                    label: Text("Scan Folder", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),),
                  ),
                ),
              ],
            ),
            // Row(
            //   children: [
            //     ElevatedButton.icon(
            //       style: ButtonStyle(
            //         backgroundColor: WidgetStatePropertyAll(primaryColor),
            //         foregroundColor: WidgetStatePropertyAll(Colors.white),
            //         shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
            //       ),
            //       onPressed: duplicateState.isScanning
            //           ? null 
            //           : () async {
            //             ref.read(clutterNotifierProvider.notifier).selectDirectory();
            //           },
            //       icon: SvgPicture.asset('assets/svgs/dir.svg', color: Colors.white),
            //       label: const Text('Select Folder'),
            //     ),
            //     const SizedBox(width: 8),
            //     if (duplicateCount > 0)
            //       Expanded(
            //         child: ElevatedButton.icon(
            //           iconAlignment: IconAlignment.end,
            //           onPressed: duplicateState.isScanning
            //               ? null 
            //               : () async {
            //                 duplicateRemover.requestBulkDelete();
            //               },
            //           icon: const Icon(Icons.cleaning_services),
            //           label: const Text('Remove All'),
            //           style: ElevatedButton.styleFrom(
            //             backgroundColor: errorColor,
            //             foregroundColor: Colors.white,
            //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            //           ),
            //         ),
            //       ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}