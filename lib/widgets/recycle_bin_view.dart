import 'package:clutter_cut/models/recycled_file.dart';
import 'package:clutter_cut/providers/recycle_bin_provider.dart';
import 'package:clutter_cut/utils/get_file_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

class RecycleBinView extends ConsumerWidget {
  const RecycleBinView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recycleBinState = ref.watch(recycleBinProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recycle Bin (${recycleBinState.recycledFiles.length} items)',
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red,),
            tooltip: 'Empty Bin',
            onPressed: recycleBinState.recycledFiles.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Empty Recycle Bin'),
                        content: const Text(
                          'Are you sure you want to permanently delete all items in the recycle bin?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(recycleBinProvider.notifier).emptyRecycleBin();
                              Navigator.pop(context);
                            },
                            child: const Text('Empty'),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Builder(
          builder: (context) {
            if (recycleBinState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (recycleBinState.recycledFiles.isEmpty) {
              return const Center(child: Text('Recycle bin is empty'));
            }
            return Column(
              children: [
                Card(
                  color: Colors.yellow[100],
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.swipe, color: Colors.black,),
                    title: const Text('Tip: Swipe right to delete, left to restore', style: TextStyle(color: Colors.black),),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: recycleBinState.recycledFiles.length,
                    itemBuilder: (context, index) {
                      final file = recycleBinState.recycledFiles[index];
                      return Dismissible(
                        key: ValueKey(file.originalPath + file.deletedAt.toIso8601String()),
                        background: Container(
                          color: Theme.of(context).colorScheme.error,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Row(
                            children: [
                              Icon(Icons.delete_forever, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          color: Colors.green,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.restore, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Restore', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Swipe right to delete
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Permanently'),
                                content: Text(
                                  'Are you sure you want to permanently delete ${path.basename(file.originalPath)}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Swipe left to restore
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Restore File'),
                                content: Text(
                                  'Do you want to restore ${path.basename(file.originalPath)}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Restore'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            ref.read(recycleBinProvider.notifier).permanentlyDeleteFile(file);
                          } else {
                            ref.read(recycleBinProvider.notifier).restoreFile(file);
                          }
                        },
                        child: RecycledFileListItem(file: file),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RecycledFileListItem extends ConsumerWidget {
  final RecycledFile file;

  const RecycledFileListItem({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = 30 - DateTime.now().difference(file.deletedAt).inDays;

    return Card(
      child: Column(
        children: [
          // Row(
          //   children: [
          //     TextButton.icon(
          //       icon: const Icon(Icons.restore),
          //       label: const Text('Restore'),
          //       onPressed: () {
          //         ref.read(recycleBinProvider.notifier).restoreFile(file);
          //       },
          //     ),
          //     const Spacer(),
          //     TextButton.icon(
          //       style: TextButton.styleFrom(
          //         // backgroundColor: Colors.grey[200],
          //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          //         foregroundColor: Theme.of(context).colorScheme.error,
          //       ),
          //       icon: const Icon(Icons.delete_forever),
          //       label: const Text('Delete'),
          //       onPressed: () {
          //         showDialog(
          //           context: context,
          //           builder: (context) => AlertDialog(
          //             title: const Text('Delete Permanently'),
          //             content: Text(
          //               'Are you sure you want to permanently delete ${path.basename(file.originalPath)}?',
          //             ),
          //             actions: [
          //               TextButton(
          //                 onPressed: () => Navigator.pop(context),
          //                 child: const Text('Cancel'),
          //               ),
          //               TextButton(
          //                 onPressed: () {
          //                   ref.read(recycleBinProvider.notifier).permanentlyDeleteFile(file);
          //                   Navigator.pop(context);
          //                 },
          //                 child: const Text('Delete'),
          //               ),
          //             ],
          //           ),
          //         );
          //       },
          //     ),
          //   ],
          // ),
          ListTile(
            leading: getFileIcon(context, getFileExtension(file.originalPath)),
            title: Text(path.basename(file.originalPath)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(
                    text: 'Original location: ',
                    style: TextStyle(fontSize: 12),
                    ),
                    TextSpan(
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      text: path.dirname(file.originalPath),
                    ),
                  ],
                  ),
                ),
                Text('Expires in $daysLeft days', style: TextStyle(color: Colors.red),),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
