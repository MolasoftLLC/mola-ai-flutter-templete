import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';

import 'package:path_provider/path_provider.dart';

import '../../common/logger.dart';
import '../../common/utils/image_utils.dart';
import '../eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../infrastructure/api_client/api_client.dart';

bool _isRemotePath(String path) =>
    path.startsWith('http://') || path.startsWith('https://');

enum SavedSakeSyncStage { analysisStart, analysisComplete }

extension SavedSakeSyncStageValue on SavedSakeSyncStage {
  String get apiValue {
    switch (this) {
      case SavedSakeSyncStage.analysisStart:
        return 'analysis_start';
      case SavedSakeSyncStage.analysisComplete:
        return 'analysis_complete';
    }
  }
}

class SavedSakeSyncRepository {
  SavedSakeSyncRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> syncSavedSake({
    required SavedSakeSyncStage stage,
    required String userId,
    required Sake sake,
    File? imageFile,
  }) async {
    if (sake.savedId == null || sake.savedId!.isEmpty) {
      logger.warning('サーバー同期をスキップしました: savedIdが未設定です');
      return;
    }

    try {
      final payload = await _buildPayload(
        stage: stage,
        userId: userId,
        sake: sake,
        imageFile: imageFile,
      );

      Response<dynamic> response;
      if (stage == SavedSakeSyncStage.analysisStart) {
        response = await _apiClient.uploadSavedSakeAnalysisStart(payload);
      } else {
        response = await _apiClient.uploadSavedSakeAnalysisComplete(payload);
      }

      if (!response.isSuccessful) {
        logger.warning(
          '保存酒の同期に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
      } else {
        logger.info('保存酒を同期しました: stage=${stage.apiValue}, id=${sake.savedId}');
      }
    } catch (error, stackTrace) {
      logger.warning('保存酒の同期処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
    }
  }

  Future<List<Sake>> fetchSavedSakes(String userId) async {
    try {
      final response = await _apiClient.fetchSavedSakes(userId);
      if (!response.isSuccessful || response.body == null) {
        logger.warning(
          '保存酒の取得に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return const <Sake>[];
      }

      final rawBody = response.body;
      logger.info('[SavedSakeSyncRepository.fetchSavedSakes] レスポンス: $rawBody');
      final List<dynamic> rawList;
      if (rawBody is List) {
        rawList = rawBody;
      } else if (rawBody is Map<String, dynamic> && rawBody['sakes'] is List) {
        rawList = rawBody['sakes'] as List<dynamic>;
      } else {
        logger.warning('保存酒の取得に失敗しました: 想定外のレスポンス形式');
        return const <Sake>[];
      }

      final result = <Sake>[];
      for (final item in rawList) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        logger.info('[SavedSakeSyncRepository.fetchSavedSakes] レコード生データ: $item');
        final sakeJson = Map<String, dynamic>.from(item);

        Map<String, dynamic>? embeddedDetail;
        final dynamic embedded = sakeJson.remove('sake');
        if (embedded is Map<String, dynamic>) {
          embeddedDetail = Map<String, dynamic>.from(embedded);
        } else if (embedded is Map) {
          embeddedDetail = <String, dynamic>{};
          embedded.forEach((key, value) {
            if (key == null) {
              return;
            }
            embeddedDetail![key.toString()] = value;
          });
        }

        final dynamic base64Field = sakeJson.remove('imageBase64');
        final dynamic base64ListField = sakeJson.remove('imageBase64List');
        final dynamic imageUrlField = sakeJson.remove('imageUrl');
        final dynamic imageUrlListField = sakeJson.remove('imageUrls');

        final savedId = sakeJson['savedId'] as String?;

        final imagePaths = <String>[];
        if (base64Field is String && base64Field.isNotEmpty) {
          final path = await _writeImage(base64Field, savedId);
          if (path != null) {
            imagePaths.add(path);
          }
        }

        if (base64ListField is List) {
          for (final element in base64ListField) {
            if (element is String && element.isNotEmpty) {
              final path = await _writeImage(element, savedId);
              if (path != null) {
                imagePaths.add(path);
              }
            }
          }
        }

        if (imageUrlField is String && imageUrlField.isNotEmpty) {
          imagePaths.add(imageUrlField);
        }

        if (imageUrlListField is List) {
          for (final element in imageUrlListField) {
            if (element is String && element.isNotEmpty) {
              imagePaths.add(element);
            }
          }
        }

        if (embeddedDetail != null && embeddedDetail.isNotEmpty) {
          embeddedDetail.forEach((key, value) {
            if (value == null) {
              return;
            }
            if (!sakeJson.containsKey(key) || sakeJson[key] == null) {
              sakeJson[key] = value;
            }
          });
        }

        try {
          final sake = Sake.fromJson(sakeJson);
          logger.info('[SavedSakeSyncRepository.fetchSavedSakes] パース後: $sakeJson');

          final combined = <String>[];
          if (sake.imagePaths != null) {
            combined.addAll(sake.imagePaths!);
          }
          combined.addAll(imagePaths);

          final remoteSet = <String>{};
          final localSet = <String>{};
          for (final path in combined) {
            if (path.isEmpty) {
              continue;
            }
            if (_isRemotePath(path)) {
              remoteSet.add(path);
            } else {
              localSet.add(path);
            }
          }

          final normalizedPaths = <String>[];
          if (remoteSet.isNotEmpty) {
            normalizedPaths.addAll(remoteSet);
          } else if (localSet.isNotEmpty) {
            normalizedPaths.addAll(localSet);
          }

          if (normalizedPaths.isNotEmpty) {
            result.add(sake.copyWith(imagePaths: normalizedPaths));
          } else {
            result.add(sake);
          }
        } catch (error) {
          logger.warning('保存酒レスポンスのパースに失敗しました: $error');
        }
      }

      return result;
    } catch (error, stackTrace) {
      logger.warning('保存酒の取得処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return const <Sake>[];
    }
  }

  Future<Map<String, dynamic>> _buildPayload({
    required SavedSakeSyncStage stage,
    required String userId,
    required Sake sake,
    File? imageFile,
  }) async {
    final Map<String, dynamic> sakeJson =
        Map<String, dynamic>.from(sake.toJson());
    sakeJson.remove('imagePaths');
    _removeNullAndEmptyValues(sakeJson);

    final payload = <String, dynamic>{
      'userId': userId,
      'savedId': sake.savedId,
      'stage': stage.apiValue,
      'timestamp': DateTime.now().toIso8601String(),
      'sake': sakeJson,
    };

    if (stage == SavedSakeSyncStage.analysisStart) {
      final File? effectiveImage = imageFile ?? _resolveImageFile(sake);
      final imageBase64 = await _encodeImage(effectiveImage);
      if (imageBase64 != null) {
        payload['imageBase64'] = imageBase64;
      }
    }

    return payload;
  }

  Future<String?> _writeImage(String base64Data, String? savedId) async {
    try {
      final bytes = base64Decode(base64Data);
      final directory = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${directory.path}/saved_sake_images');
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      final fileName =
          '${savedId ?? DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}.webp';
      final file = File('${savedDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (error) {
      logger.warning('画像ファイルの書き込みに失敗しました: $error');
      return null;
    }
  }

  Future<String?> uploadSavedSakeImage({
    required String userId,
    required String savedId,
    required File imageFile,
  }) async {
    try {
      final base64 = await ImageUtils.compressAndEncodeImage(imageFile);
      final payload = <String, dynamic>{
        'userId': userId,
        'imageBase64': base64,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.uploadSavedSakeImage(savedId, payload);
      if (!response.isSuccessful) {
        logger.warning(
          '保存酒画像のアップロードに失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return null;
      }

      final body = response.body;
      if (body is Map<String, dynamic>) {
        final imageUrl = body['imageUrl'];
        if (imageUrl is String && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }

      logger.warning('保存酒画像のレスポンスに imageUrl が含まれていません');
      return null;
    } catch (error, stackTrace) {
      logger.warning('保存酒画像のアップロード処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return null;
    }
  }

  Future<bool> deleteSavedSakeImage({
    required String userId,
    required String savedId,
    required String imageUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'userId': userId,
        'imageUrl': imageUrl,
      };

      final response = await _apiClient.deleteSavedSakeImage(savedId, payload);
      if (!response.isSuccessful) {
        logger.warning(
          '保存酒画像の削除に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return false;
      }

      return true;
    } catch (error, stackTrace) {
      logger.warning('保存酒画像の削除処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }

  Future<bool> deleteSavedSakeRecord({
    required String userId,
    required String savedId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.removeSavedSake(savedId, payload);
      if (!response.isSuccessful) {
        logger.warning(
          '保存酒削除に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return false;
      }

      logger.info('保存酒をサーバーから削除しました: id=$savedId');
      return true;
    } catch (error, stackTrace) {
      logger.warning('保存酒削除処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }

  File? _resolveImageFile(Sake sake) {
    final paths = sake.imagePaths;
    if (paths == null || paths.isEmpty) {
      return null;
    }
    final firstPath = paths.first;
    if (firstPath.isEmpty) {
      return null;
    }
    final file = File(firstPath);
    return file.existsSync() ? file : null;
  }

  Future<String?> _encodeImage(File? file) async {
    if (file == null) {
      return null;
    }

    try {
      if (!file.existsSync()) {
        logger.warning('同期用画像ファイルが存在しません: ${file.path}');
        return null;
      }
      return await ImageUtils.compressAndEncodeImage(file);
    } catch (error) {
      logger.warning('画像のエンコードに失敗しました: $error');
      return null;
    }
  }

  void _removeNullAndEmptyValues(Map<String, dynamic> json) {
    final keysToRemove = <String>[];
    json.forEach((key, value) {
      if (value == null) {
        keysToRemove.add(key);
      } else if (value is String && value.isEmpty) {
        keysToRemove.add(key);
      } else if (value is Iterable) {
        final cleaned = value
            .where(
                (element) => element != null && element.toString().isNotEmpty)
            .toList();
        if (cleaned.isEmpty) {
          keysToRemove.add(key);
        } else {
          json[key] = cleaned;
        }
      } else if (value is Map<String, dynamic>) {
        _removeNullAndEmptyValues(value);
        if (value.isEmpty) {
          keysToRemove.add(key);
        }
      }
    });

    for (final key in keysToRemove) {
      json.remove(key);
    }
  }
}
