import 'package:flutter/material.dart';

class ScanningProgressIndicator extends StatelessWidget {
  final dynamic duplicateState;

  const ScanningProgressIndicator({
    super.key,
    required this.duplicateState,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(duplicateState.currentAction ?? 'Scanning...'),
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