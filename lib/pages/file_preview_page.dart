
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FilePreviewPage extends StatelessWidget {
  final File originalFile;
  final File duplicateFile;

  const FilePreviewPage({
    super.key,
    required this.originalFile,
    required this.duplicateFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Preview'),
      ),
      body: Column(
        children: [
          // Original File Preview
          Expanded(
            child: Column(
              children: [
                const Chip(label: Text('Original')),
                Expanded(
                  child: _buildFilePreview(originalFile),
                ),
              ],
            ),
          ),
          const Divider(),
          // Duplicate File Preview
          Expanded(
            child: Column(
              children: [
                const Chip(label: Text('Duplicate')),
                Expanded(
                  child: _buildFilePreview(duplicateFile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
      return Image.file(file);
    } else if (['mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
      return VideoPlayerWidget(file: file);
    } else {
      return const Center(
        child: Text('File preview not available for this file type.'),
      );
    }
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final File file;

  const VideoPlayerWidget({super.key, required this.file});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(widget.file);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Chewie(controller: _chewieController);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }
}
