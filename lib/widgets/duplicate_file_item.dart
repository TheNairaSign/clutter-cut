import 'dart:io';
import 'package:clutter_cut/providers/duplicate_remover_provider.dart';
import 'package:flutter/material.dart';
import 'package:clutter_cut/utils/confirm_dialog.dart';
import 'package:clutter_cut/utils/get_file_extension.dart';
import 'package:clutter_cut/pages/file_preview_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuplicateFileItem extends ConsumerWidget {
  final File file;
  final File originalFile;
  final bool isOriginal;

  const DuplicateFileItem({
    super.key,
    required this.file,
    required this.originalFile,
    required this.isOriginal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryColor = colorScheme.secondary;
    final errorColor = colorScheme.error;

    final duplicateRemover = ref.watch(duplicateRemoverNotifierProvider.notifier);

    return ListTile(
      onTap: () {
        final extension = file.path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FilePreviewPage(
                originalFile: originalFile,
                duplicateFile: file,
              ),
            ),
          );
        }
      },
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
              backgroundColor: WidgetStatePropertyAll(secondaryColor.withValues(alpha: .1)),
            ),
              onPressed: null,
              child: const Text('Original'),
            ),
        )
        : SizedBox(
          height: 33,
          child: TextButton(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(errorColor),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              backgroundColor: WidgetStatePropertyAll(errorColor.withValues(alpha: .1)),
            ),
              child: const Text('Delete'),
              onPressed: () async {
                final confirm = await confirmRemoval(context, file.path);
                if (confirm) {
                  // Use the proper method to move to recycle bin
                  await duplicateRemover.confirmRemoveFile(file);
                }
              },
            ),
        ),
    );
  }
}