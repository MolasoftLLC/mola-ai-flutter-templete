import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/logger.dart';
import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../domain/eintities/sake_bottle_image.dart';
import '../../domain/repository/sake_bottle_image_repository.dart';

part 'sake_bottle_list_page_notifier.freezed.dart';

@freezed
class SakeBottleListPageState with _$SakeBottleListPageState {
  const factory SakeBottleListPageState({
    @Default([]) List<SakeBottleImage> sakeBottleImages,
    @Default(true) bool isLoading,
    String? errorMessage,
    File? selectedImage,
  }) = _SakeBottleListPageState;
}

class SakeBottleListPageNotifier extends StateNotifier<SakeBottleListPageState>
    with LocatorMixin {
  final BuildContext context;
  late final SakeBottleImageRepository _sakeBottleImageRepository;

  SakeBottleListPageNotifier({
    required this.context,
  }) : super(const SakeBottleListPageState()) {
    _sakeBottleImageRepository = context.read<SakeBottleImageRepository>();
    _initializeWithMigration();
  }

  Future<void> _initializeWithMigration() async {
    // Migrate existing images first
    await _sakeBottleImageRepository.migrateExistingImages();
    // Then load the images
    await _loadSakeBottleImages();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final imageFile = await CustomImagePicker.pickImage(source: source);

      if (imageFile != null) {
        final croppedFile =
            await ImageCropperService.cropAndRotateImage(imageFile.path);

        if (croppedFile != null) {
          final galleryPath =
              await ImageCropperService.saveImageToGallery(croppedFile);
          if (galleryPath != null) {
            logger.info('クロップした画像をギャラリーに保存しました: $galleryPath');
          }

          state = state.copyWith(selectedImage: croppedFile);

          await _saveSakeBottleImage(croppedFile);
        }
      }
    } catch (e) {
      logger.shout('画像選択中にエラーが発生しました: $e');
      state = state.copyWith(
        errorMessage: '画像の選択に失敗しました: $e',
      );
    }
  }

  void clearSelectedImage() {
    state = state.copyWith(selectedImage: null);
  }

  Future<void> _saveSakeBottleImage(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true);

      final sakeBottleImage =
          await _sakeBottleImageRepository.saveSakeBottleImage(
        imageFile,
        sakeName: '未分析の酒瓶',
      );

      if (sakeBottleImage != null) {
        await _loadSakeBottleImages();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '酒瓶画像の保存に失敗しました',
        );
      }
    } catch (e) {
      logger.shout('酒瓶画像の保存中にエラーが発生しました: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '酒瓶画像の保存に失敗しました: $e',
      );
    }
  }

  Future<void> _loadSakeBottleImages() async {
    try {
      state = state.copyWith(isLoading: true);
      final images = await _sakeBottleImageRepository.getAllSakeBottleImages();
      state = state.copyWith(
        sakeBottleImages: images,
        isLoading: false,
      );
    } catch (e) {
      logger.shout('酒瓶画像の読み込みに失敗しました: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '酒瓶画像の読み込みに失敗しました',
      );
    }
  }

  Future<void> deleteSakeBottleImage(String id) async {
    try {
      state = state.copyWith(isLoading: true);
      final success =
          await _sakeBottleImageRepository.deleteSakeBottleImage(id);

      if (success) {
        final updatedImages =
            state.sakeBottleImages.where((img) => img.id != id).toList();
        state = state.copyWith(
          sakeBottleImages: updatedImages,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '酒瓶画像の削除に失敗しました',
        );
      }
    } catch (e) {
      logger.shout('酒瓶画像の削除中にエラーが発生しました: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '酒瓶画像の削除に失敗しました: $e',
      );
    }
  }

  Future<void> refreshSakeBottleImages() async {
    await _loadSakeBottleImages();
  }
}
