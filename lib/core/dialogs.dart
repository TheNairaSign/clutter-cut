import 'dart:math';

import 'package:clutter_cut/providers/state/clutter_state.dart';
import 'package:flutter/material.dart';

class Dialogs {
  static void showMessage(String message) {
    print(message);
  }

  static showProgressDialog(BuildContext context, ClutterState state, {required int totalDuplicates}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Removing Duplicates'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sliding animation for duplicates
                  SizedBox(
                    height: 150,
                    width: 250,
                    child: Stack(
                      children: [
                        // Static icon at the top
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                            size: 48,
                          ),
                        ),
                        
                        // Animated sliding items
                        AnimatedBuilder(
                          animation: ValueNotifier<int>(state.scannedFiles),
                          builder: (context, child) {
                            return Stack(
                              children: List.generate(
                                min(5, totalDuplicates - state.scannedFiles + 5),
                                (index) => TweenAnimationBuilder(
                                  tween: Tween<Offset>(
                                    begin: Offset(0, 0),
                                    end: index == 0 ? Offset(1.5, 0) : Offset(0, 0),
                                  ),
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeOutQuad,
                                  onEnd: () {
                                    if (index == 0) {
                                      setDialogState(() {});
                                    }
                                  },
                                  builder: (context, Offset offset, child) {
                                    return Positioned(
                                      left: 20 + (offset.dx * 200),
                                      bottom: 20 + (index * 20),
                                      child: Transform.translate(
                                        offset: offset,
                                        child: Container(
                                          width: 180,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator
                  LinearProgressIndicator(
                    value: state.scannedFiles / max(totalDuplicates, 1),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${state.scannedFiles} / $totalDuplicates files deleted',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}