import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:clutter_cut/providers/clutter_provider.dart';

class SummaryCard extends ConsumerWidget {
  final dynamic duplicateState;
  final int duplicateCount;
  final dynamic duplicateRemover;

  const SummaryCard({
    super.key,
    required this.duplicateState,
    required this.duplicateCount,
    required this.duplicateRemover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final errorColor = colorScheme.error;

    return Card(
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
                    backgroundColor: WidgetStatePropertyAll(primaryColor.withOpacity(0.1)),
                    foregroundColor: WidgetStatePropertyAll(primaryColor),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                  ),
                  onPressed: duplicateState.isScanning
                      ? null 
                      : () async {
                        ref.read(clutterNotifierProvider(context).notifier).selectDirectory();
                      },
                  icon: SvgPicture.asset('assets/svgs/dir.svg', color: primaryColor),
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
                          await duplicateRemover.findDuplicates();
                        },
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Remove All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor.withOpacity(0.1),
                      foregroundColor: errorColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}