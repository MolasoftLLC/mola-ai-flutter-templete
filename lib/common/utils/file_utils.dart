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
      logger.info('画像の読み込み: ファイルパスもbase64もnullのためプレースホルダーを使用');
      return Assets.sakePlaceholder;
    }
    
    // Try base64 image first if available
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        logger.info('base64データから画像を読み込みます (${base64Image.length} バイト)');
        final imageBytes = base64Decode(base64Image);
        logger.info('base64データのデコードに成功しました: ${imageBytes.length} バイト');
        return MemoryImage(Uint8List.fromList(imageBytes));
      } catch (e) {
        logger.warning('base64画像のデコードに失敗しました: $e');
        // Continue to file-based loading if available
      }
    } else if (base64Image != null) {
      logger.warning('base64データは存在しますが、空です');
    }
    
    // If no file path or base64 decode failed, return placeholder
    if (filePath == null) {
      logger.info('ファイルパスがnullのためプレースホルダーを使用');
      return Assets.sakePlaceholder;
    }
    
    // Check if file exists
    final file = File(filePath);
    if (!file.existsSync()) {
      logger.warning('ファイルが見つかりません: $filePath');
      return Assets.sakePlaceholder;
    }
    
    // File exists, return FileImage
    logger.info('ファイルから画像を読み込みます: $filePath');
    return FileImage(file);
  }
}
