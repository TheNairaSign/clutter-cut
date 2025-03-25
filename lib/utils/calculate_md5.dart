import 'dart:io';

import 'package:crypto/crypto.dart';

Future<String> calculateMD5(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      // Return a unique string to prevent falsely identifying as duplicate
      return "error_${DateTime.now().millisecondsSinceEpoch}_${file.path}";
    }
  }