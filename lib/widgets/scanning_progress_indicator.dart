import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScanningProgressIndicator extends ConsumerWidget {

  const ScanningProgressIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    final duplicateState = ref.watch(duplicateRemoverNotifierProvider);
    
    return Padding(
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
    );
  }
}