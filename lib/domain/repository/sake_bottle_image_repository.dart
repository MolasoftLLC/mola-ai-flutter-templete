import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../common/logger.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../common/utils/image_utils.dart';
import '../../infrastructure/local_database/shared_key.dart';
import '../../infrastructure/local_database/shared_preference.dart';
import '../eintities/sake_bottle_image.dart';

class SakeBottleImageRepository {
  // Save a sake bottle image
  Future<SakeBottleImage?> saveSakeBottleImage(File imageFile, {String? sakeName, String? type}) async {
    try {
      // Save to gallery if not from gallery already
      String? galleryPath;
      if (!imageFile.path.contains('DCIM')) {
        galleryPath = await ImageCropperService.saveImageToGallery(imageFile);
      }
      
      // Save to permanent storage
      final permanentPath = await ImageCropperService.saveImagePermanently(imageFile, 'sake_bottle');
      
      if (permanentPath == null) {
        logger.shout('永続的な画像の保存に失敗しました');
        return null;
      }
      
      // Compress and encode to base64
      final base64Image = await ImageUtils.compressAndEncodeImage(
        imageFile,
        quality: 55,
        format: CompressFormat.webp,
      );
      
      // Create sake bottle image object
      final sakeBottleImage = SakeBottleImage(
        id: 'sake_bottle_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        path: permanentPath,
        base64Image: base64Image,
        capturedAt: DateTime.now(),
        sakeName: sakeName,
        type: type,
      );
      
      // Save to shared preferences
      await _saveSakeBottleImageToPrefs(sakeBottleImage);
      
      return sakeBottleImage;
    } catch (e) {
      logger.shout('酒瓶画像の保存に失敗しました: $e');
      return null;
    }
  }
  
  // Get all sake bottle images
  Future<List<SakeBottleImage>> getAllSakeBottleImages() async {
    try {
      final jsonString = await SharedPreference.staticGetString(
        key: SAKE_BOTTLE_IMAGES,
        defaultValue: '[]',
      );
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<SakeBottleImage> images = jsonList
          .map((json) => SakeBottleImage.fromJson(json))
          .toList();
      
      // Filter out images with non-existent files
      final List<SakeBottleImage> validImages = [];
      for (final image in images) {
        if (File(image.path).existsSync()) {
          validImages.add(image);
        } else {
          logger.warning('酒瓶画像ファイルが見つかりません: ${image.path}');
        }
      }
      
      // Sort by date (newest first)
      validImages.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      
      return validImages;
    } catch (e) {
      logger.shout('酒瓶画像の取得に失敗しました: $e');
      return [];
    }
  }
  
  // Delete a sake bottle image
  Future<bool> deleteSakeBottleImage(String id) async {
    try {
      final images = await getAllSakeBottleImages();
      final imageToDelete = images.firstWhere((img) => img.id == id);
      
      // Delete file
      final file = File(imageToDelete.path);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from list
      final updatedImages = images.where((img) => img.id != id).toList();
      
      // Save updated list
      await _saveSakeBottleImagesList(updatedImages);
      
      return true;
    } catch (e) {
      logger.shout('酒瓶画像の削除に失敗しました: $e');
      return false;
    }
  }
  
  // Update a sake bottle image
  Future<bool> updateSakeBottleImage(SakeBottleImage image) async {
    try {
      final images = await getAllSakeBottleImages();
      final index = images.indexWhere((img) => img.id == image.id);
      
      if (index >= 0) {
        images[index] = image;
        await _saveSakeBottleImagesList(images);
        return true;
      }
      
      return false;
    } catch (e) {
      logger.shout('酒瓶画像の更新に失敗しました: $e');
      return false;
    }
  }
  
  // Private method to save a sake bottle image to shared preferences
  Future<void> _saveSakeBottleImageToPrefs(SakeBottleImage image) async {
    final images = await getAllSakeBottleImages();
    images.add(image);
    await _saveSakeBottleImagesList(images);
  }
  
  // Private method to save the list of sake bottle images
  Future<void> _saveSakeBottleImagesList(List<SakeBottleImage> images) async {
    final jsonList = images.map((img) => img.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    
    await SharedPreference.staticSetString(
      key: SAKE_BOTTLE_IMAGES,
      value: jsonString,
    );
  }

  /// Migrate existing images to permanent storage
  Future<void> migrateExistingImages() async {
    try {
      final jsonString = await SharedPreference.staticGetString(
        key: SAKE_BOTTLE_IMAGES,
        defaultValue: '[]',
      );
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<SakeBottleImage> images = jsonList
          .map((json) => SakeBottleImage.fromJson(json))
          .toList();
      
      bool hasChanges = false;
      final updatedImages = <SakeBottleImage>[];
      
      for (final image in images) {
        // Skip if image already has base64 data
        if (image.base64Image != null && image.base64Image!.isNotEmpty) {
          updatedImages.add(image);
          continue;
        }
        
        final file = File(image.path);
        if (file.existsSync()) {
          // Check if the image is already in the documents directory
          final appDir = await getApplicationDocumentsDirectory();
          if (!image.path.startsWith(appDir.path)) {
            // Need to migrate this image
            final permanentPath = await ImageCropperService.saveImagePermanently(
              file,
              'sake_bottle'
            );
            
            if (permanentPath != null) {
              try {
                // Compress and encode to base64
                final base64Image = await ImageUtils.compressAndEncodeImage(
                  file,
                  quality: 55,
                  format: CompressFormat.webp,
                );
                
                // Create updated image with new path and base64 data
                final updatedImage = image.copyWith(
                  path: permanentPath,
                  base64Image: base64Image,
                );
                updatedImages.add(updatedImage);
                hasChanges = true;
                logger.info('酒瓶画像を永続的なストレージに移行しました: ${image.id}');
              } catch (e) {
                // If encoding fails, keep original with new path
                final updatedImage = image.copyWith(path: permanentPath);
                updatedImages.add(updatedImage);
                hasChanges = true;
                logger.warning('酒瓶画像のbase64エンコードに失敗しました: ${image.id} - $e');
              }
            } else {
              // Couldn't migrate, but file exists, so keep original
              updatedImages.add(image);
            }
          } else {
            // Already in permanent storage, but need to add base64
            try {
              // Compress and encode to base64
              final base64Image = await ImageUtils.compressAndEncodeImage(
                file,
                quality: 55,
                format: CompressFormat.webp,
              );
              
              // Create updated image with base64 data
              final updatedImage = image.copyWith(base64Image: base64Image);
              updatedImages.add(updatedImage);
              hasChanges = true;
              logger.info('酒瓶画像をbase64エンコードしました: ${image.id}');
            } catch (e) {
              // If encoding fails, keep original
              logger.warning('酒瓶画像のbase64エンコードに失敗しました: ${image.id} - $e');
              updatedImages.add(image);
            }
          }
        } else {
          // File doesn't exist, image will be filtered out
          logger.warning('存在しない酒瓶画像をスキップしました: ${image.id} at ${image.path}');
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        await _saveSakeBottleImagesList(updatedImages);
        logger.info('酒瓶画像の移行が完了しました。${images.length - updatedImages.length} 個の無効な画像が削除されました。');
      }
    } catch (e) {
      logger.shout('既存の酒瓶画像の移行に失敗しました: $e');
    }
  }
}
