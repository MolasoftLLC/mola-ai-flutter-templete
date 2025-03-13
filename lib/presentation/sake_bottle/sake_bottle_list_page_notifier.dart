import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../domain/eintities/sake_bottle_image.dart';
import '../../domain/repository/sake_bottle_image_repository.dart';

part 'sake_bottle_list_page_notifier.freezed.dart';

@freezed
class SakeBottleListPageState with _$SakeBottleListPageState {
  const factory SakeBottleListPageState({
    @Default([]) List<SakeBottleImage> sakeBottleImages,
    @Default(true) bool isLoading,
    String? errorMessage,
  }) = _SakeBottleListPageState;
}

class SakeBottleListPageNotifier extends StateNotifier<SakeBottleListPageState> {
  final BuildContext context;
  late final SakeBottleImageRepository _sakeBottleImageRepository;

  SakeBottleListPageNotifier({
    required this.context,
  }) : super(const SakeBottleListPageState()) {
    _sakeBottleImageRepository = context.read<SakeBottleImageRepository>();
    _loadSakeBottleImages();
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
      final success = await _sakeBottleImageRepository.deleteSakeBottleImage(id);
      
      if (success) {
        final updatedImages = state.sakeBottleImages.where((img) => img.id != id).toList();
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
