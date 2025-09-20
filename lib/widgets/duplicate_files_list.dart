import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:flutter/material.dart';
import 'package:clutter_cut/widgets/duplicate_group_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuplicateFilesList extends ConsumerStatefulWidget {

  const DuplicateFilesList({super.key});

  @override
  ConsumerState<DuplicateFilesList> createState() => _DuplicateFilesListState();
}

class _DuplicateFilesListState extends ConsumerState<DuplicateFilesList> {

  final Map<int, bool> _expandedStates = {};


  @override
  Widget build(BuildContext context) {
    final duplicateState = ref.watch(duplicateRemoverNotifierProvider);

    return SizedBox(
      width: double.infinity,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemCount: duplicateState.duplicateFiles.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final hash = duplicateState.duplicateFiles.keys.elementAt(index);
          final files = duplicateState.duplicateFiles[hash]!;
      
          return DuplicateGroupCard(
            index: index,
            files: files,
            isExpanded: _expandedStates[index] == true,
            onExpansionChanged: (value) {
              setState(() {
                _expandedStates[index] = value;
              });
            },
          );
        },
      ),
    );
  }
}