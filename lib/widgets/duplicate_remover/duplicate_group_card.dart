import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:clutter_cut/widgets/duplicate_remover/duplicate_file_item.dart';

class DuplicateGroupCard extends StatelessWidget {
  final int index;
  final List<File> files;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;
  final dynamic duplicateRemover;

  const DuplicateGroupCard({
    super.key,
    required this.index,
    required this.files,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.duplicateRemover,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurface;
    final totalSize = files.isNotEmpty 
        ? '${(files.first.lengthSync() / 1024).toStringAsFixed(2)} KB'
        : 'Unknown';

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: iconColor,
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
        title: Text('Duplicate Group ${index + 1}'),
        subtitle: Text('${files.length} identical files • Size: $totalSize'),
        leading: isExpanded 
          ? SvgPicture.asset('assets/svgs/folder-open.svg', color: iconColor)
          : SvgPicture.asset('assets/svgs/dir.svg', color: iconColor),
        onExpansionChanged: onExpansionChanged,
        children: files.map((file) {
          return DuplicateFileItem(
            file: file,
            isOriginal: files.indexOf(file) == 0,
            duplicateRemover: duplicateRemover,
          );
        }).toList(),
      ),
    );
  }
}