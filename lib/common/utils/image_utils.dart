import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../common/logger.dart';

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
    int quality = 55,
    CompressFormat format = CompressFormat.webp,
  }) async {
    try {
      // 元の画像サイズを取得してログ出力
      final originalBytes = file.readAsBytesSync();
      final originalSize = originalBytes.length;
      logger.info('元の画像サイズ: ${_formatFileSize(originalSize)}');

      // 一時ディレクトリを取得
      final tempDir = await getTemporaryDirectory();
      final rand = Random().nextInt(10000);

      // 拡張子を決定
      String ext;
      switch (format) {
        case CompressFormat.jpeg:
          ext = '.jpg';
          break;
        case CompressFormat.png:
          ext = '.png';
          break;
        case CompressFormat.heic:
          ext = '.heic';
          break;
        case CompressFormat.webp:
          ext = '.webp';
          break;
        default:
          ext = '.jpg';
      }

      // 一時ファイルのパスを生成（ランダム要素を含めて一意にする）
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$rand$ext';

      logger.info('圧縮ファイルパス: $targetPath');

      // Compress the image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        format: format,
      );

      if (compressedFile == null) {
        // If compression fails, fall back to the original file
        logger.shout('画像圧縮に失敗しました。元の画像を使用します。');
        return base64Encode(originalBytes);
      }

      // Read the compressed file and encode to base64
      final compressedBytes = compressedFile.readAsBytesSync();
      final compressedSize = compressedBytes.length;

      // 圧縮後のサイズをログ出力
      logger.info('圧縮後の画像サイズ: ${_formatFileSize(compressedSize)}');
      logger.info(
          '圧縮率: ${(compressedSize / originalSize * 100).toStringAsFixed(2)}%');

      // Delete the temporary compressed file
      await compressedFile.delete().catchError((e) {
        logger.info('一時ファイル削除に失敗: $e');
      });

      // Return the base64 encoded string
      return base64Encode(compressedBytes);
    } catch (e, stackTrace) {
      // エラー情報も詳細にログ出力
      logger.shout('画像圧縮中にエラーが発生しました: $e');
      logger.shout('スタックトレース: $stackTrace');

      // If any error occurs, fall back to the original file
      return base64Encode(file.readAsBytesSync());
    }
  }

  /// ファイルサイズを読みやすい形式に変換
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
