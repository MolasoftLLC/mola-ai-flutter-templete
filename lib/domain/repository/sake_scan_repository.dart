import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show MultipartFile;
import 'package:http_parser/http_parser.dart';

import '../../common/localization/app_locale_resolver.dart';
import '../../common/logger.dart';
import '../../common/utils/image_utils.dart';
import '../../infrastructure/api_client/sake_menu_recognition_api_client.dart';
import '../eintities/sake_label_scan.dart';

abstract class SakeScanRepository {
  Future<SakeScanResult> scanFront(File image);

  Future<SakeScanResult> scanBack(String scanSessionId, File image);

  Future<SakeScanConfirmation> confirm(String scanSessionId, int sakeId);

  Future<void> rejectCandidates(String scanSessionId, List<int> sakeIds);

  Future<SakeOverview> fetchOverview(int sakeId, {bool trackView = false});
}

class SakeDetailViewMemory {
  final Set<int> _viewedSakeIds = <int>{};

  bool markViewed(int sakeId) => _viewedSakeIds.add(sakeId);

  void forget(int sakeId) => _viewedSakeIds.remove(sakeId);
}

class SakeScanApiRepository implements SakeScanRepository {
  SakeScanApiRepository(
    this._apiClient, {
    this.requestTimeout = const Duration(seconds: 30),
    SakeDetailViewMemory? detailViewMemory,
  }) : _detailViewMemory = detailViewMemory ?? _appDetailViewMemory;

  static final SakeDetailViewMemory _appDetailViewMemory =
      SakeDetailViewMemory();

  final SakeMenuRecognitionApiClient _apiClient;
  final Duration requestTimeout;
  final SakeDetailViewMemory _detailViewMemory;

  @override
  Future<SakeScanResult> scanFront(File image) async {
    final compressed = await _prepareImage(image);
    try {
      final locale = await resolveAppLocaleLanguageCode();
      final imagePart = await _jpegPart(compressed);
      final response = await _apiClient
          .scanSakeFrontLabel(imagePart, locale)
          .timeout(requestTimeout);
      return SakeScanResult.fromJson(_requireBody(response));
    } finally {
      await _deleteTemporaryFile(compressed);
    }
  }

  @override
  Future<SakeScanResult> scanBack(String scanSessionId, File image) async {
    if (scanSessionId.isEmpty) {
      throw const SakeScanException(
        kind: SakeScanErrorKind.sessionExpired,
        message: 'スキャンセッションがありません',
      );
    }
    final compressed = await _prepareImage(image);
    try {
      final locale = await resolveAppLocaleLanguageCode();
      final imagePart = await _jpegPart(compressed);
      final response = await _apiClient
          .scanSakeBackLabel(scanSessionId, imagePart, locale)
          .timeout(requestTimeout);
      return SakeScanResult.fromJson(_requireBody(response));
    } finally {
      await _deleteTemporaryFile(compressed);
    }
  }

  @override
  Future<SakeScanConfirmation> confirm(String scanSessionId, int sakeId) async {
    final locale = await resolveAppLocaleLanguageCode();
    final response = await _apiClient
        .confirmScannedSake(scanSessionId, <String, dynamic>{
          'sakeId': sakeId,
          'locale': locale,
        })
        .timeout(requestTimeout);
    return SakeScanConfirmation.fromJson(_requireBody(response));
  }

  @override
  Future<void> rejectCandidates(String scanSessionId, List<int> sakeIds) async {
    final response = await _apiClient
        .rejectScannedSakeCandidates(scanSessionId, <String, dynamic>{
          'sakeIds': sakeIds,
        })
        .timeout(requestTimeout);
    if (response.isSuccessful) return;
    _requireBody(response);
  }

  @override
  Future<SakeOverview> fetchOverview(
    int sakeId, {
    bool trackView = false,
  }) async {
    final shouldTrackView = trackView && _detailViewMemory.markViewed(sakeId);
    try {
      final locale = await resolveAppLocaleLanguageCode();
      final response = await _apiClient
          .fetchSakeOverview(sakeId, locale, shouldTrackView)
          .timeout(requestTimeout);
      return SakeOverview.fromJson(_requireBody(response));
    } catch (_) {
      if (shouldTrackView) _detailViewMemory.forget(sakeId);
      rethrow;
    }
  }

  Future<File> _prepareImage(File image) async {
    try {
      return await ImageUtils.compressForSakeScan(image);
    } catch (error, stackTrace) {
      logger.warning('ラベルスキャン画像の圧縮に失敗しました: $error');
      logger.info(stackTrace.toString());
      throw SakeScanException(
        kind: SakeScanErrorKind.compression,
        message: error.toString(),
      );
    }
  }

  Future<MultipartFile> _jpegPart(File file) {
    return MultipartFile.fromPath(
      'image',
      file.path,
      filename: 'sake_label.jpg',
      contentType: MediaType('image', 'jpeg'),
    );
  }

  Map<String, dynamic> _requireBody(dynamic response) {
    if (response.isSuccessful && response.body is Map<String, dynamic>) {
      return response.body as Map<String, dynamic>;
    }
    final statusCode = response.statusCode as int?;
    final body = response.error ?? response.body;
    throw SakeScanException(
      kind: _errorKindForStatus(statusCode),
      statusCode: statusCode,
      message: _extractMessage(body),
    );
  }

  Future<void> _deleteTemporaryFile(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (error) {
      logger.info('スキャン一時画像を削除できませんでした: $error');
    }
  }
}

enum SakeScanErrorKind {
  cameraPermission,
  compression,
  timeout,
  noCandidates,
  sessionExpired,
  invalidRequest,
  rateLimited,
  server,
  aiAnalysis,
  unknown,
}

class SakeScanException implements Exception {
  const SakeScanException({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  factory SakeScanException.fromError(Object error) {
    if (error is SakeScanException) return error;
    if (error is TimeoutException) {
      return SakeScanException(
        kind: SakeScanErrorKind.timeout,
        message: error.toString(),
      );
    }
    return SakeScanException(
      kind: SakeScanErrorKind.unknown,
      message: error.toString(),
    );
  }

  final SakeScanErrorKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'SakeScanException(kind: $kind, statusCode: $statusCode, message: $message)';
}

SakeScanErrorKind _errorKindForStatus(int? statusCode) {
  return switch (statusCode) {
    400 || 422 => SakeScanErrorKind.invalidRequest,
    404 => SakeScanErrorKind.sessionExpired,
    429 => SakeScanErrorKind.rateLimited,
    500 => SakeScanErrorKind.server,
    _ => SakeScanErrorKind.unknown,
  };
}

String _extractMessage(dynamic body) {
  if (body is Map) {
    return body['message']?.toString() ??
        body['error']?.toString() ??
        'ラベルスキャンに失敗しました';
  }
  return body?.toString() ?? 'ラベルスキャンに失敗しました';
}
