import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:flutter/material.dart';
import 'package:clutter_cut/widgets/duplicate_group_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final expandedStatesProvider = StateProvider<Map<int, bool>>((ref) => {});

class DuplicateFilesList extends ConsumerWidget {
  const DuplicateFilesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duplicateState = ref.watch(duplicateRemoverNotifierProvider);
    final expandedStates = ref.watch(expandedStatesProvider);

    // When the duplicate files change, reset the expanded states
    ref.listen(duplicateRemoverNotifierProvider.select((state) => state.duplicateFiles), (previous, next) {
      if (previous != next) {
        ref.read(expandedStatesProvider.notifier).state = {};
      }
    });

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
            isExpanded: expandedStates[index] == true,
            onExpansionChanged: (value) {
              final newExpandedStates = Map<int, bool>.from(expandedStates);
              newExpandedStates[index] = value;
              ref.read(expandedStatesProvider.notifier).state = newExpandedStates;
            },
          );
        },
      ),
    );
  }
}