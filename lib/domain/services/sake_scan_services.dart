import 'dart:async';
import 'dart:io';

import '../../common/utils/image_cropper_service.dart';
import '../eintities/response/sake_bottle_recognition_response/sake_bottle_comprehensive_response.dart';
import '../eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../notifier/saved_sake/saved_sake_notifier.dart';
import '../repository/auth_repository.dart';
import '../repository/sake_menu_recognition_repository.dart';
import '../repository/saved_sake_sync_repository.dart';

abstract class SakeScanAnalysisService {
  Future<List<Sake>> identifyCandidates(File image, {File? secondaryImage});

  Future<Sake> analyze(File image, {int? sakeId, String? scanSessionId});
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
  }) async {
    final candidates = await _repository.recognizeSakeBottleCandidates(
      image,
      secondaryFile: secondaryImage,
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
  Future<Sake> analyze(File image, {int? sakeId, String? scanSessionId}) async {
    final preferences = preferencesProvider()?.trim();
    final SakeBottleComprehensiveResponse? response = await _repository
        .comprehensiveSakeBottleAnalysis(
          image,
          preferences: preferences == null || preferences.isEmpty
              ? null
              : preferences,
          sakeId: sakeId,
          scanSessionId: scanSessionId,
        );
    if (response?.sakeInfo == null) {
      throw SakeBottleRecognitionException(
        statusCode: 500,
        message: '日本酒のAI解析結果を取得できませんでした',
      );
    }
    return response!.sakeInfo!.copyWith(
      sakeId: response.sakeId ?? sakeId ?? response.sakeInfo!.sakeId,
    );
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
    required SavedSakeSyncRepository syncRepository,
    required AuthRepository authRepository,
  }) : _savedSakeNotifier = savedSakeNotifier,
       _syncRepository = syncRepository,
       _authRepository = authRepository;

  final SavedSakeNotifier _savedSakeNotifier;
  final SavedSakeSyncRepository _syncRepository;
  final AuthRepository _authRepository;

  @override
  Future<Sake> saveInitial(
    Sake sake,
    File primaryImage, {
    File? secondaryImage,
    required bool isPublic,
  }) async {
    final savedPath = await ImageCropperService.saveImagePermanently(
      primaryImage,
      'saved_sake',
    );
    if (savedPath == null) {
      throw StateError('撮影画像を保存できませんでした');
    }
    final savedPaths = <String>[savedPath];
    if (secondaryImage != null && secondaryImage.path != primaryImage.path) {
      final secondaryPath = await ImageCropperService.saveImagePermanently(
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
      isPublic: isPublic,
      syncStatus: SavedSakeSyncStatus.localOnly,
    );
    final savedId = await _savedSakeNotifier.addSavedSake(draft);
    final saved = draft.copyWith(savedId: savedId);
    _sync(
      stage: SavedSakeSyncStage.analysisStart,
      sake: saved,
      image: File(savedPath),
      additionalImages: savedPaths
          .skip(1)
          .map(File.new)
          .toList(growable: false),
      isPublic: isPublic,
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
    final normalized = completed.copyWith(
      savedId: savedId,
      sakeId: completed.sakeId ?? initial.sakeId,
      imagePaths: initial.imagePaths,
      isPublic: isPublic,
    );
    await _savedSakeNotifier.updateSavedSakeWithInfo(savedId, normalized);
    final stored = _savedSakeNotifier.savedSakes.firstWhere(
      (item) => item.savedId == savedId,
      orElse: () => normalized,
    );
    _sync(
      stage: SavedSakeSyncStage.analysisComplete,
      sake: stored,
      image: image,
      isPublic: isPublic,
    );
    return stored;
  }

  void _sync({
    required SavedSakeSyncStage stage,
    required Sake sake,
    required File image,
    List<File> additionalImages = const <File>[],
    required bool isPublic,
  }) {
    final user = _authRepository.currentUser;
    if (user == null) return;
    unawaited(
      _syncWithImages(
        stage: stage,
        userId: user.uid,
        sake: sake,
        image: image,
        additionalImages: additionalImages,
        isPublic: isPublic,
      ),
    );
  }

  Future<void> _syncWithImages({
    required SavedSakeSyncStage stage,
    required String userId,
    required Sake sake,
    required File image,
    required List<File> additionalImages,
    required bool isPublic,
  }) async {
    final synced = await _syncRepository.syncSavedSake(
      stage: stage,
      userId: userId,
      sake: sake,
      imageFile: image,
      isPublic: isPublic,
    );
    if (!synced) return;

    if (stage != SavedSakeSyncStage.analysisStart) {
      final savedId = sake.savedId;
      if (savedId != null && savedId.isNotEmpty) {
        await _savedSakeNotifier.markSavedSakeServerSynced(savedId);
      }
      return;
    }

    for (final additionalImage in additionalImages) {
      await _syncRepository.uploadSavedSakeImage(
        userId: userId,
        savedId: sake.savedId!,
        imageFile: additionalImage,
      );
    }
  }
}
