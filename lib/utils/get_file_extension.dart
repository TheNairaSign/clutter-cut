import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;

String getFileExtension(String filePath) {
    // Get the file name from the path and convert to lowercase
    final fileName = filePath.split(Platform.pathSeparator).last.toLowerCase();
    // Split by dot and get the last part (extension)
    final parts = fileName.split('.');
    // Return the extension or empty string if no extension found
    return parts.length > 1 ? parts.last : '';
  }

Widget getFileIcon(BuildContext context, String filePath) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;
  final colorScheme = theme.colorScheme;
  final extension = filePath.split('.').last.toLowerCase();
  
  // Define colors from our color scheme
  final defaultIconColor = Colors.black; // Subtle gray for defaults
  final pdfColor = colorScheme.error; // Red for PDFs
  final imageColor = colorScheme.secondary; // Green for images
  // final videoColor = colorScheme.primary; // Blue for videos
  
  switch (extension) {
    case 'pdf':
      return SvgPicture.asset(
        'assets/svgs/pdf-file-red.svg', // Use same SVG but with dynamic color
        color: pdfColor,
      );
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
      return SvgPicture.asset(
        'assets/svgs/photo.svg',
        color: imageColor,
      );
    case 'mp4':
    case 'avi':
    case 'mov':
    case 'wmv':
      return SvgPicture.asset(
        'assets/svgs/video-library.svg',
        color: pdfColor,
      );
    case 'mp3':
    case 'wav':
    case 'ogg':
    case 'm4a':
      return SvgPicture.asset(
        'assets/svgs/music-folder.svg',
        color: imageColor, // Using green for audio too
      );
    case 'doc':
    case 'docx':
    case 'txt':
    case 'rtf':
      return SvgPicture.asset(
        isDarkMode ? 'assets/svgs/document.svg' : 'assets/svgs/document-filled.svg',
        color: colorScheme.primary, // Blue for documents
      );
    case 'zip':
    case 'rar':
    case '7z':
      return SvgPicture.asset(
        'assets/svgs/zip-file.svg',
        color: defaultIconColor, // Subtle gray for archives
      );
    default:
      return SvgPicture.asset(
        'assets/svgs/document.svg',
        color: defaultIconColor,
      );
  }
}