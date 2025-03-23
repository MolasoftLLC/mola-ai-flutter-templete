import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../common/logger.dart';

class ImageCropperService {
  /// Crop and rotate an image
  static Future<File?> cropAndRotateImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '画像を編集',
            toolbarColor: const Color(0xFF1D3567),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: '画像を編集',
            doneButtonTitle: '完了',
            cancelButtonTitle: 'キャンセル',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      logger.shout('画像のクロップに失敗しました: $e');
      return null;
    }
  }

  /// Save image to gallery and return the saved path
  static Future<String?> saveImageToGallery(File imageFile) async {
    try {
      final result = await ImageGallerySaver.saveFile(imageFile.path);
      logger.info('画像をギャラリーに保存しました: $result');

      if (result is Map && result['isSuccess'] == true) {
        return result['filePath'] ?? imageFile.path;
      } else if (result is String) {
        return result;
      }

      return imageFile.path;
    } catch (e) {
      logger.shout('ギャラリーへの画像保存に失敗しました: $e');
      return null;
    }
  }

  /// Create a copy of the image in the app's documents directory
  static Future<File?> copyImageToAppDirectory(
      File imageFile, String prefix) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath =
          path.join(appDir.path, '${prefix}_${timestamp}_$fileName');

      final newFile = await imageFile.copy(newPath);
      logger.info('画像をアプリディレクトリにコピーしました: ${newFile.path}');

      return newFile;
    } catch (e) {
      logger.shout('画像のコピーに失敗しました: $e');
      return null;
    }
  }

  /// Save an image permanently to the app's documents directory
  static Future<String?> saveImagePermanently(File imageFile, [String? customPrefix]) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final prefix = customPrefix != null ? '${customPrefix}_' : '';
      final newPath = path.join(appDir.path, '${prefix}${timestamp}_$fileName');

      final savedImage = await imageFile.copy(newPath);
      logger.info('画像を永続的に保存しました: ${savedImage.path}');

      return savedImage.path;
    } catch (e) {
      logger.shout('永続的な画像の保存に失敗しました: $e');
      return null;
    }
  }
}
