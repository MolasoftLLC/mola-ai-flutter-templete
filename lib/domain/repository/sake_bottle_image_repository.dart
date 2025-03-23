import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../common/logger.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../infrastructure/local_database/shared_key.dart';
import '../../infrastructure/local_database/shared_preference.dart';
import '../eintities/sake_bottle_image.dart';

class SakeBottleImageRepository {
  // Save a sake bottle image
  Future<SakeBottleImage?> saveSakeBottleImage(File imageFile, {String? sakeName, String? type}) async {
    try {
      // Save to gallery
      final galleryPath = await ImageCropperService.saveImageToGallery(imageFile);
      if (galleryPath == null) {
        logger.shout('ギャラリーへの保存に失敗しました');
        return null;
      }
      
      // Copy to app directory
      final savedImage = await ImageCropperService.copyImageToAppDirectory(
        imageFile,
        'sake_bottle',
      );
      
      if (savedImage == null) {
        logger.shout('アプリディレクトリへのコピーに失敗しました');
        return null;
      }
      
      // Create sake bottle image object
      final sakeBottleImage = SakeBottleImage(
        id: 'sake_bottle_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        path: savedImage.path,
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
}
