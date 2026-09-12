import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../common/logger.dart';

/// Utility class for image operations
class ImageUtils {
  /// ラベルスキャン用に、認識精度を保ちながら送信サイズを抑えたJPEGを生成します。
  ///
  /// 呼び出し側は、送信完了後に返却された一時ファイルを削除してください。
  static Future<File> compressForSakeScan(
    File file, {
    int longEdge = 1920,
    int quality = 88,
  }) async {
    if (!await file.exists()) {
      throw const FileSystemException('スキャン画像が見つかりません');
    }

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();
    codec.dispose();

    final scale = max(width, height) > longEdge
        ? longEdge / max(width, height)
        : 1.0;
    final targetWidth = max(1, (width * scale).round());
    final targetHeight = max(1, (height * scale).round());
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/sake_scan_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      minWidth: targetWidth,
      minHeight: targetHeight,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (compressed == null) {
      throw StateError('スキャン画像の圧縮に失敗しました');
    }
    return File(compressed.path);
  }

  /// 保存酒用に、表示品質を保ちつつストレージ負荷を抑えたWebPを生成します。
  ///
  /// 呼び出し側は、永続保存後に返却された一時ファイルを削除してください。
  static Future<File> compressForSakeStorage(
    File file, {
    int longEdge = 1600,
    int quality = 72,
  }) async {
    if (!await file.exists()) {
      throw const FileSystemException('保存する画像が見つかりません');
    }

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();
    codec.dispose();

    final scale = max(width, height) > longEdge
        ? longEdge / max(width, height)
        : 1.0;
    final targetWidth = max(1, (width * scale).round());
    final targetHeight = max(1, (height * scale).round());
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/sake_storage_${DateTime.now().microsecondsSinceEpoch}.webp';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      minWidth: targetWidth,
      minHeight: targetHeight,
      quality: quality,
      format: CompressFormat.webp,
      keepExif: false,
    );
    if (compressed == null) {
      throw StateError('保存用画像の圧縮に失敗しました');
    }
    return File(compressed.path);
  }

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
      }

      // 一時ファイルのパスを生成（ランダム要素を含めて一意にする）
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$rand$ext';

      logger.info('圧縮ファイルパス: $targetPath');

      // Compress the image
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        format: format,
      );

      if (compressedXFile == null) {
        // If compression fails, fall back to the original file
        logger.shout('画像圧縮に失敗しました。元の画像を使用します。');
        return base64Encode(originalBytes);
      }

      // Read the compressed file and encode to base64
      final compressedBytes = await compressedXFile.readAsBytes();
      final compressedSize = compressedBytes.length;

      // 圧縮後のサイズをログ出力
      logger.info('圧縮後の画像サイズ: ${_formatFileSize(compressedSize)}');
      logger.info(
        '圧縮率: ${(compressedSize / originalSize * 100).toStringAsFixed(2)}%',
      );

      // Delete the temporary compressed file
      final compressedPath = compressedXFile.path;
      if (compressedPath.isNotEmpty) {
        try {
          await File(compressedPath).delete();
        } catch (error) {
          logger.info('一時ファイル削除に失敗: $error');
        }
      }

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
