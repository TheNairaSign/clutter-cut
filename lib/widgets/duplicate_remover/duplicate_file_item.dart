import 'dart:io';
import 'package:flutter/material.dart';
import 'package:clutter_cut/utils/confirm_dialog.dart';
import 'package:clutter_cut/utils/get_file_extension.dart';

class DuplicateFileItem extends StatelessWidget {
  final File file;
  final bool isOriginal;
  final dynamic duplicateRemover;

  const DuplicateFileItem({
    super.key,
    required this.file,
    required this.isOriginal,
    required this.duplicateRemover,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryColor = colorScheme.secondary;
    final errorColor = colorScheme.error;

    return ListTile(
      title: Text(
        file.path.split(Platform.pathSeparator).last, 
        style: TextStyle(fontWeight: isOriginal ? FontWeight.bold : FontWeight.normal)
      ),
      subtitle: Text(
        file.path, 
        style: const TextStyle(fontSize: 12)
      ),
      leading: Container(
        padding: const EdgeInsets.all(5),
        width: 33,
        height: 33,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOriginal? Colors.grey.shade100 : Colors.grey.shade200,
        ),
        child: getFileIcon(context, getFileExtension(file.path))),
      trailing: isOriginal
        ? SizedBox(
          height: 33,
          child: TextButton(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(secondaryColor),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              backgroundColor: WidgetStatePropertyAll(secondaryColor.withOpacity(0.1)),
            ),
              child: const Text('Original'),
              onPressed: null,
            ),
        )
        : SizedBox(
          height: 33,
          child: TextButton(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(errorColor),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              backgroundColor: WidgetStatePropertyAll(errorColor.withOpacity(0.1)),
            ),
              child: const Text('Delete'),
              onPressed: () async {
                final confirm = await confirmRemoval(context, file.path);
                if (confirm) {
                  await file.delete();
                  await duplicateRemover.findDuplicates();
                }
              },
            ),
        ),
    );
  }
}