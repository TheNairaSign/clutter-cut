import 'dart:io';

class RecycledFile {
  final String originalPath;
  final String recyclePath;
  final DateTime deletedAt;
  final int fileSize;

  const RecycledFile({
    required this.originalPath,
    required this.recyclePath,
    required this.deletedAt,
    required this.fileSize,
  });

  bool get isExpired => DateTime.now().difference(deletedAt).inDays > 30;

  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'recyclePath': recyclePath,
      'deletedAt': deletedAt.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  factory RecycledFile.fromJson(Map<String, dynamic> json) {
    return RecycledFile(
      originalPath: json['originalPath'] as String,
      recyclePath: json['recyclePath'] as String,
      deletedAt: DateTime.parse(json['deletedAt'] as String),
      fileSize: json['fileSize'] as int,
    );
  }
}