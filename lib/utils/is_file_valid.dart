import 'dart:io';

Future<bool> isFileValid(File file) async {
    try {
      // Check if file exists and is readable
      final exists = await file.exists();
      if (!exists) return false;
      
      // Try to read a small portion of the file to see if it's accessible
      await file.openRead(0, 1).first;
      return true;
    } catch (e) {
      return false;
    }
  }