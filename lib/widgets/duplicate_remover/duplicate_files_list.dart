import 'package:flutter/material.dart';
import 'package:clutter_cut/widgets/duplicate_remover/duplicate_group_card.dart';

class DuplicateFilesList extends StatelessWidget {
  final dynamic duplicateState;
  final dynamic duplicateRemover;
  final Map<int, bool> expandedStates;
  final Function(int, bool) onExpansionChanged;

  const DuplicateFilesList({
    super.key,
    required this.duplicateState,
    required this.duplicateRemover,
    required this.expandedStates,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: duplicateState.duplicateFiles.length,
      itemBuilder: (context, index) {
        final hash = duplicateState.duplicateFiles.keys.elementAt(index);
        final files = duplicateState.duplicateFiles[hash]!;
        
        return DuplicateGroupCard(
          index: index,
          files: files,
          isExpanded: expandedStates[index] == true,
          onExpansionChanged: (value) => onExpansionChanged(index, value),
          duplicateRemover: duplicateRemover,
        );
      },
    );
  }
}