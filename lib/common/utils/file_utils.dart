import 'dart:io';
import 'package:flutter/material.dart';
import '../../common/logger.dart';
import '../assets.dart';

class FileUtils {
  /// Safely loads an image from a file path, providing a fallback if the file doesn't exist
  static ImageProvider safeLoadImage(String? filePath) {
    // If path is null, return placeholder
    if (filePath == null) {
      return Assets.sakePlaceholder;
    }

    // Check if file exists
    final file = File(filePath);
    if (!file.existsSync()) {
      logger.warning('ファイルが見つかりません: $filePath');
      return Assets.sakePlaceholder;
    }

    // File exists, return FileImage
    return FileImage(file);
  }
}
