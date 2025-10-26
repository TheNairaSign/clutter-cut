import 'package:flutter/material.dart';

class ScanningProgressIndicator extends StatelessWidget {
  final String currentAction;
  final int scannedFiles;
  final int totalFiles;

  const ScanningProgressIndicator({
    super.key,
    required this.currentAction,
    required this.scannedFiles,
    required this.totalFiles,
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
          Text(currentAction),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            borderRadius: BorderRadius.circular(5),
            backgroundColor: primaryColor.withOpacity(0.1),
            color: primaryColor,
            value: totalFiles > 0 ? scannedFiles / totalFiles : 0,
          ),
          const SizedBox(height: 4),
          Text('$scannedFiles / $totalFiles'),
        ],
      ),
    );
  }
}