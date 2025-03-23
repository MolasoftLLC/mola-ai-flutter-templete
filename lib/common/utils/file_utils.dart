import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../common/logger.dart';
import '../assets.dart';

class FileUtils {
  /// Safely loads an image from a file path or base64 string, providing a fallback if unavailable
  static ImageProvider safeLoadImage(String? filePath, {String? base64Image}) {
    // If both paths are null, return placeholder
    if (filePath == null && base64Image == null) {
      return Assets.sakePlaceholder;
    }
    
    // Try base64 image first if available
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        final imageBytes = base64Decode(base64Image);
        return MemoryImage(Uint8List.fromList(imageBytes));
      } catch (e) {
        logger.warning('base64画像のデコードに失敗しました: $e');
        // Continue to file-based loading if available
      }
    }
    
    // If no file path or base64 decode failed, return placeholder
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
