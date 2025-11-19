import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// A custom image picker that uses MediaStore.ACTION_PICK_IMAGES on Android
/// to avoid requiring READ_MEDIA_IMAGES permission.
class CustomImagePicker {
  static const MethodChannel _channel = MethodChannel('custom_image_picker');
  static final ImagePicker _defaultPicker = ImagePicker();

  /// Picks an image from the gallery using MediaStore.ACTION_PICK_IMAGES on Android
  /// or the default image_picker implementation on other platforms.
  static Future<File?> pickImage({required ImageSource source}) async {
    // Only use custom implementation for gallery on Android
    if (Platform.isAndroid && source == ImageSource.gallery) {
      try {
        final String? path = await _channel.invokeMethod<String>('pickImage');
        if (path != null) {
          return File(path);
        }
      } on PlatformException catch (e) {
        print('Failed to pick image: ${e.message}');
        // Fall back to default implementation if custom one fails
      }
    }

    // Use default implementation for camera or non-Android platforms
    final pickedFile = await _defaultPicker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }

    return null;
  }
}
