import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart' as http;

import 'package:http/http.dart' show MultipartFile;
import 'package:http_parser/http_parser.dart';

import '../../common/localization/app_locale_resolver.dart';
import '../../common/logger.dart';
import '../../common/utils/image_utils.dart';
import '../../infrastructure/api_client/sake_menu_recognition_api_client.dart';
import '../eintities/sake_label_scan.dart';

abstract class SakeScanRepository {
  Future<SakeScanResult> scanFront(
    File image, {
    SakeFrontScanMethod method = SakeFrontScanMethod.googleLens,
  });

  Future<SakeScanResult> scanBack(String scanSessionId, File image);

  Future<SakeScanResult> startBackLabelFallback();

  Future<SakeScanConfirmation> confirm(String scanSessionId, int sakeId);

  Future<void> rejectCandidates(String scanSessionId, List<int> sakeIds);

  Future<SakeOverview> fetchOverview(int sakeId, {bool trackView = false});
  Future<Map<int, SakeTasteProfileDetails>> fetchTasteProfiles(
    List<int> sakeIds,
  );
}

abstract interface class LensDetailAnalysisRepository {
  Future<String> startLensDetailAnalysis(int sakeId, {bool retry = false});
  Future<String> fetchLensDetailAnalysisStatus(int sakeId);
}

abstract interface class LensDiscoveryRepository {
  Future<SakeScanConfirmation> confirmDiscovery(
    String scanSessionId,
    String candidateKey,
  );
}

abstract interface class ProgressiveSakeScanRepository {
  Future<SakeScanResult> scanFrontProgressively(
    File image, {
    required void Function(List<String>) onLensResults,
  });
}

enum SakeFrontScanMethod { googleLens, chatGpt, progressiveLens }

class SakeDetailViewMemory {
  final Set<int> _viewedSakeIds = <int>{};

  bool markViewed(int sakeId) => _viewedSakeIds.add(sakeId);

  void forget(int sakeId) => _viewedSakeIds.remove(sakeId);
}

class SakeScanApiRepository
    implements
        SakeScanRepository,
        ProgressiveSakeScanRepository,
        LensDiscoveryRepository,
        LensDetailAnalysisRepository {
  SakeScanApiRepository(
    this._apiClient, {
    this.requestTimeout = const Duration(seconds: 30),
    this.frontCandidateTimeout = const Duration(seconds: 90),
    SakeDetailViewMemory? detailViewMemory,
  }) : _detailViewMemory = detailViewMemory ?? _appDetailViewMemory;

  static final SakeDetailViewMemory _appDetailViewMemory =
      SakeDetailViewMemory();

  final SakeMenuRecognitionApiClient _apiClient;
  final Duration requestTimeout;
  final Duration frontCandidateTimeout;
  final SakeDetailViewMemory _detailViewMemory;

  @override
  Future<SakeScanResult> scanFront(
    File image, {
    SakeFrontScanMethod method = SakeFrontScanMethod.googleLens,
  }) async {
    final compressed = await _prepareImage(image);
    try {
      final locale = await resolveAppLocaleLanguageCode();
      final imagePart = await _jpegPart(compressed);
      final response = switch (method) {
        SakeFrontScanMethod.progressiveLens => throw StateError(
          'Use scanFrontProgressively for streaming scans',
        ),
        SakeFrontScanMethod.googleLens =>
          _apiClient.scanSakeFrontLabelWithLensCandidates(imagePart, locale),
        SakeFrontScanMethod.chatGpt =>
          _apiClient.scanSakeFrontLabelWithChatGptCandidates(imagePart, locale),
      };
      final completedResponse = await response.timeout(frontCandidateTimeout);
      return SakeScanResult.fromJson(_requireBody(completedResponse));
    } finally {
      await _deleteTemporaryFile(compressed);
    }
  }

  @override
  Future<SakeScanResult> scanFrontProgressively(
    File image, {
    required void Function(List<String>) onLensResults,
  }) async {
    final compressed = await _prepareImage(image);
    final client = http.Client();
    try {
      return await (() async {
        final request = http.MultipartRequest(
          'POST',
          _apiClient.client.baseUrl.resolve(
            '/api/sake-bottle/scan/front/lens-progressive',
          ),
        );
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/x-ndjson';
        request.fields['locale'] = await resolveAppLocaleLanguageCode();
        request.files.add(await _jpegPart(compressed));
        final response = await client.send(request);
        if (response.statusCode != 200) {
          throw SakeScanException(
            kind: _errorKindForStatus(response.statusCode),
            statusCode: response.statusCode,
            message: await response.stream.bytesToString(),
          );
        }
        await for (final line
            in response.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          if (line.trim().isEmpty) continue;
          final event = jsonDecode(line) as Map<String, dynamic>;
          if (event['event'] == 'lens_results') {
            final results = (event['results'] as List)
                .cast<Map<String, dynamic>>();
            onLensResults(
              results.map((item) => item['name'] as String).toList(),
            );
          } else if (event['event'] == 'complete') {
            return SakeScanResult.fromJson(
              event['result'] as Map<String, dynamic>,
            );
          } else if (event['event'] == 'error') {
            throw SakeScanException(
              kind: SakeScanErrorKind.server,
              message: event['error'].toString(),
            );
          } else if (event['status'] != null) {
            // A pre-stream failure may return the regular back-label fallback.
            return SakeScanResult.fromJson(event);
          }
        }
        throw const SakeScanException(
          kind: SakeScanErrorKind.server,
          message: '検索の接続が切れました',
        );
      })().timeout(frontCandidateTimeout);
    } finally {
      client.close();
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
  Future<SakeScanResult> startBackLabelFallback() async {
    final response = await _apiClient.startSakeBackLabelFallback().timeout(
      requestTimeout,
    );
    return SakeScanResult.fromJson(_requireBody(response));
  }

  @override
  Future<SakeScanConfirmation> confirmDiscovery(
    String scanSessionId,
    String candidateKey,
  ) async {
    final response = await _apiClient
        .confirmScannedSake(scanSessionId, <String, dynamic>{
          'candidateKey': candidateKey,
        })
        .timeout(requestTimeout);
    return SakeScanConfirmation.fromJson(_requireBody(response));
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
  Future<Map<int, SakeTasteProfileDetails>> fetchTasteProfiles(
    List<int> sakeIds,
  ) async {
    final ids = sakeIds.where((id) => id > 0).toSet().toList(growable: false);
    if (ids.isEmpty) return <int, SakeTasteProfileDetails>{};

    final response = await _apiClient
        .fetchSakeTasteProfiles(<String, dynamic>{'sakeIds': ids})
        .timeout(requestTimeout);
    final body = _requireBody(response);
    final rawProfiles = body['profiles'];
    if (rawProfiles is! List) return <int, SakeTasteProfileDetails>{};

    final result = <int, SakeTasteProfileDetails>{};
    for (final item in rawProfiles.whereType<Map>()) {
      final json = Map<String, dynamic>.from(item);
      final sakeId = json['sakeId'];
      final profile = json['tasteProfile'];
      if (sakeId is num && profile is Map) {
        result[sakeId.toInt()] = SakeTasteProfileDetails.fromJson(
          Map<String, dynamic>.from(profile),
        );
      }
    }
    return result;
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

  @override
  Future<String> startLensDetailAnalysis(
    int sakeId, {
    bool retry = false,
  }) async {
    return _lensDetailRequest(
      sakeId,
      'POST',
      body: {'locale': await resolveAppLocaleLanguageCode(), 'retry': retry},
    );
  }

  @override
  Future<String> fetchLensDetailAnalysisStatus(int sakeId) =>
      _lensDetailRequest(sakeId, 'GET');

  Future<String> _lensDetailRequest(
    int sakeId,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _apiClient.client
        .send<Map<String, dynamic>, Map<String, dynamic>>(
          chopper.Request(
            method,
            Uri.parse('/api/sakes/$sakeId/lens-detail-analysis'),
            _apiClient.client.baseUrl,
            body: body,
          ),
        )
        .timeout(requestTimeout);
    return _requireBody(response)['status'] as String;
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
  if (statusCode != null && statusCode >= 500 && statusCode <= 599) {
    return SakeScanErrorKind.server;
  }
  return switch (statusCode) {
    400 || 422 => SakeScanErrorKind.invalidRequest,
    404 => SakeScanErrorKind.sessionExpired,
    429 => SakeScanErrorKind.rateLimited,
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
