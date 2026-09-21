import 'dart:io';

import '../../common/logger.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../common/utils/image_utils.dart';
import '../eintities/response/sake_bottle_recognition_response/sake_bottle_comprehensive_response.dart';
import '../eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../eintities/sake_label_scan.dart';
import '../notifier/saved_sake/saved_sake_notifier.dart';
import '../repository/sake_menu_recognition_repository.dart';

abstract class SakeScanAnalysisService {
  Future<List<Sake>> identifyCandidates(
    File image, {
    File? secondaryImage,
    String? scanSessionId,
  });

  Future<Sake> analyze(
    File image, {
    int? sakeId,
    String? scanSessionId,
    Sake? confirmedSake,
  });
}

class DefaultSakeScanAnalysisService implements SakeScanAnalysisService {
  DefaultSakeScanAnalysisService(
    this._repository, {
    required this.preferencesProvider,
  });

  final SakeMenuRecognitionRepository _repository;
  final String? Function() preferencesProvider;

  @override
  Future<List<Sake>> identifyCandidates(
    File image, {
    File? secondaryImage,
    String? scanSessionId,
  }) async {
    final candidates = await _repository.recognizeSakeBottleCandidates(
      image,
      secondaryFile: secondaryImage,
      scanSessionId: scanSessionId,
    );
    if (candidates.isEmpty) {
      throw SakeBottleRecognitionException(
        statusCode: 404,
        message: '日本酒の候補を特定できませんでした',
      );
    }
    return candidates;
  }

  @override
  Future<Sake> analyze(
    File image, {
    int? sakeId,
    String? scanSessionId,
    Sake? confirmedSake,
  }) async {
    final preferences = preferencesProvider()?.trim();
    final SakeBottleComprehensiveResponse? response = await _repository
        .comprehensiveSakeBottleAnalysis(
          image,
          preferences: preferences == null || preferences.isEmpty
              ? null
              : preferences,
          sakeId: sakeId,
          scanSessionId: scanSessionId,
          confirmedName: _confirmedSakeName(confirmedSake),
          confirmedType: confirmedSake?.type,
          confirmedBrewery: confirmedSake?.brewery,
        );
    if (response?.sakeInfo == null ||
        !isPlausibleRecognizedSakeName(response!.sakeInfo!.name)) {
      throw SakeBottleRecognitionException(
        statusCode: 500,
        message: '日本酒のAI解析結果を取得できませんでした',
      );
    }
    return response.sakeInfo!.copyWith(
      sakeId: response.sakeId ?? sakeId ?? response.sakeInfo!.sakeId,
    );
  }

  String? _confirmedSakeName(Sake? sake) {
    final name = sake?.name?.trim();
    return isPlausibleRecognizedSakeName(name) ? name : null;
  }
}

abstract class SakeScanPersistenceService {
  Future<Sake> saveInitial(
    Sake sake,
    File primaryImage, {
    File? secondaryImage,
    required bool isPublic,
  });

  Future<Sake> saveCompleted(
    Sake initial,
    Sake completed,
    File image, {
    required bool isPublic,
  });
}

class DefaultSakeScanPersistenceService implements SakeScanPersistenceService {
  DefaultSakeScanPersistenceService({
    required SavedSakeNotifier savedSakeNotifier,
  }) : _savedSakeNotifier = savedSakeNotifier;

  final SavedSakeNotifier _savedSakeNotifier;

  @override
  Future<Sake> saveInitial(
    Sake sake,
    File primaryImage, {
    File? secondaryImage,
    required bool isPublic,
  }) async {
    final savedPath = await _saveCompressedImagePermanently(
      primaryImage,
      'saved_sake',
    );
    if (savedPath == null) {
      throw StateError('撮影画像を保存できませんでした');
    }
    final savedPaths = <String>[savedPath];
    if (secondaryImage != null && secondaryImage.path != primaryImage.path) {
      final secondaryPath = await _saveCompressedImagePermanently(
        secondaryImage,
        'saved_sake',
      );
      if (secondaryPath == null) {
        throw StateError('裏ラベル画像を保存できませんでした');
      }
      savedPaths.add(secondaryPath);
    }
    final draft = sake.copyWith(
      imagePaths: savedPaths,
      isPublic: false,
      syncStatus: SavedSakeSyncStatus.localOnly,
    );
    final savedId = await _savedSakeNotifier.addSavedSake(draft);
    final saved = draft.copyWith(savedId: savedId);
    await _savedSakeNotifier.syncSavedSakeToServer(
      savedId,
      startOnly: true,
      publicLabelContribution: true,
    );
    return saved;
  }

  @override
  Future<Sake> saveCompleted(
    Sake initial,
    Sake completed,
    File image, {
    required bool isPublic,
  }) async {
    final savedId = initial.savedId;
    if (savedId == null || savedId.isEmpty) {
      throw StateError('保存酒IDがありません');
    }
    final latest = _savedSakeNotifier.savedSakes.firstWhere(
      (item) => item.savedId == savedId,
      orElse: () => initial,
    );
    final normalized = completed.copyWith(
      savedId: savedId,
      sakeId: completed.sakeId ?? initial.sakeId,
      imagePaths: latest.imagePaths ?? initial.imagePaths,
      impression: latest.impression,
      place: latest.place,
      drinkingPlace: latest.drinkingPlace,
      userTags: latest.userTags,
      personalTasteRatings: latest.personalTasteRatings,
      isPublic: latest.isPublic,
    );
    await _savedSakeNotifier.updateSavedSakeWithInfo(savedId, normalized);
    final stored = _savedSakeNotifier.savedSakes.firstWhere(
      (item) => item.savedId == savedId,
      orElse: () => normalized,
    );
    final synced = await _savedSakeNotifier.syncSavedSakeToServer(
      savedId,
      force: true,
    );
    return synced ?? stored;
  }

  Future<String?> _saveCompressedImagePermanently(
    File image,
    String prefix,
  ) async {
    final compressed = await ImageUtils.compressForSakeStorage(image);
    try {
      return await ImageCropperService.saveImagePermanently(compressed, prefix);
    } finally {
      try {
        if (await compressed.exists()) await compressed.delete();
      } catch (error) {
        logger.info('保存用一時画像を削除できませんでした: $error');
      }
    }
  }
}
