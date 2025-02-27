import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Utility class for image operations
class ImageUtils {
  /// Compresses an image file and converts it to base64 string
  ///
  /// [file] The image file to compress and encode
  /// [quality] The quality of compression (0-100), default is 80
  /// [format] The format to compress to, default is jpeg
  /// 
  /// Returns a base64 encoded string of the compressed image
  static Future<String> compressAndEncodeImage(
    File file, {
    int quality = 80,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      // Get file extension
      final path = file.path;
      final lastIndex = path.lastIndexOf('.');
      final ext = lastIndex != -1 ? path.substring(lastIndex) : '.jpg';
      
      // Create a temporary file for the compressed image
      final targetPath = '${path}_compressed$ext';
      
      // Compress the image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        format: format,
      );
      
      if (compressedFile == null) {
        // If compression fails, fall back to the original file
        return base64Encode(file.readAsBytesSync());
      }
      
      // Read the compressed file and encode to base64
      final compressedBytes = compressedFile.readAsBytesSync();
      
      // Delete the temporary compressed file
      await compressedFile.delete();
      
      // Return the base64 encoded string
      return base64Encode(compressedBytes);
    } catch (e) {
      // If any error occurs, fall back to the original file
      return base64Encode(file.readAsBytesSync());
    }
  }
}
