// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:clutter_cut/widgets/duplicate_file_item.dart';

class DuplicateGroupCard extends StatelessWidget {
  final int index;
  final List<File> files;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;

  const DuplicateGroupCard({
    super.key,
    required this.index,
    required this.files,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurface;
    final totalSizeFuture = files.isNotEmpty ? files.first.length() : Future.value(0);

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: iconColor,
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
        title: Text('Duplicate Group ${index + 1}'),
        subtitle: FutureBuilder<int>(
          future: totalSizeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return Text('${files.length} identical files • Size: ${(snapshot.data! / 1024).toStringAsFixed(2)} KB');
            } else {
              return Text('${files.length} identical files • Size: ...');
            }
          },
        ),
        leading: isExpanded 
          ? SvgPicture.asset('assets/svgs/folder-open.svg', colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn))
          : SvgPicture.asset('assets/svgs/dir.svg', colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
        onExpansionChanged: onExpansionChanged,
        children: files.map((file) {
          return DuplicateFileItem(
            file: file,
            originalFile: files.first,
            isOriginal: files.indexOf(file) == 0,
          );
        }).toList(),
      ),
    );
  }
}