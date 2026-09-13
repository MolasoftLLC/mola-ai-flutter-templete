import 'dart:io';

import '../../common/localization/app_locale_resolver.dart';
import '../../common/logger.dart';
import '../../common/utils/image_utils.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../infrastructure/api_client/sake_menu_recognition_api_client.dart';
import '../eintities/response/sake_bottle_recognition_response/sake_bottle_recognition_response.dart';
import '../eintities/response/sake_bottle_recognition_response/sake_bottle_comprehensive_response.dart';
import '../eintities/sake_label_scan.dart';
import '../notifier/favorite/favorite_notifier.dart';

class SakeMenuRecognitionRepository {
  SakeMenuRecognitionRepository(this._apiClient);

  final SakeMenuRecognitionApiClient _apiClient;

  Future<SakeMenuRecognitionResponse?> recognizeMenu(File file) async {
    final baseFile = await ImageUtils.compressAndEncodeImage(file);
    logger.shout(baseFile);
    final response = await _apiClient.recognizeMenu(baseFile);
    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as Map<String, dynamic>;
      return SakeMenuRecognitionResponse.fromJson(responseBodyJson);
    } else {
      logger.shout(response.error);
      return null;
    }
  }

  /// メニュー画像から日本酒名と種類のみを抽出する
  Future<List<Sake>?> extractSakeInfo(File file) async {
    // リトライ回数
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final baseFile = await ImageUtils.compressAndEncodeImage(file);
        final response = await _apiClient.extractSakeInfo(baseFile);

        if (response.isSuccessful) {
          logger.shout(response.body);
          final responseBodyJson = response.body as Map<String, dynamic>;

          // 'sakes'キーから日本酒リストを取得
          final sakesList =
              (responseBodyJson['sakes'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          // 各日本酒情報をSakeオブジェクトに変換
          return sakesList.map((sakeMap) => Sake.fromJson(sakeMap)).toList();
        } else {
          logger.shout('API呼び出しエラー: ${response.error}');
          retryCount++;
          // 少し待機してからリトライ
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      } catch (e) {
        logger.shout('例外発生: $e');
        retryCount++;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    logger.shout('最大リトライ回数に達しました');
    return null;
  }

  /// 日本酒名と種類のリストから詳細情報を取得する
  Future<SakeMenuRecognitionResponse?> getSakeInfoBatch(
    List<Map<String, dynamic>> sakes,
  ) async {
    final body = {
      'sakes': sakes,
      'locale': await resolveAppLocaleLanguageCode(),
    };

    final response = await _apiClient.getSakeInfoBatch(body);

    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as Map<String, dynamic>;
      return SakeMenuRecognitionResponse.fromJson(responseBodyJson);
    } else {
      logger.shout(response.error);
      return null;
    }
  }

  /// 日本酒名から詳細情報を取得する
  Future<Sake?> getSakeInfo(
    String sakeName, {
    String? type,
    String? preferences,
  }) async {
    final sakeJson = await _getSakeInfoJson(
      sakeName,
      type: type,
      preferences: preferences,
    );
    if (sakeJson == null) return null;
    return Sake.fromJson(sakeJson);
  }

  /// AI検索候補を開いた詳細画面で、名前から表示用の詳細一式を取得する。
  Future<SakeOverview?> getSakeOverviewByName(
    String sakeName, {
    String? type,
    String? preferences,
  }) async {
    final sakeJson = await _getSakeInfoJson(
      sakeName,
      type: type,
      preferences: preferences,
    );
    if (sakeJson == null ||
        !isPlausibleRecognizedSakeName(sakeJson['name']?.toString())) {
      return null;
    }
    return SakeOverview.fromJson(<String, dynamic>{
      'sake': sakeJson,
      'analysis': <String, dynamic>{'sakeInfo': sakeJson},
      'brewery': <String, dynamic>{'name': sakeJson['brewery']},
    });
  }

  Future<Map<String, dynamic>?> _getSakeInfoJson(
    String sakeName, {
    String? type,
    String? preferences,
  }) async {
    if (!isPlausibleRecognizedSakeName(sakeName)) return null;

    final Map<String, dynamic> body = {
      'sakeName': sakeName,
      'locale': await resolveAppLocaleLanguageCode(),
    };

    // 種類（タイプ）が指定されている場合は追加
    if (type != null && type.isNotEmpty) {
      body['type'] = type;
    }

    // 好みが指定されている場合は追加
    if (preferences != null && preferences.isNotEmpty) {
      body['preferences'] = preferences;
    }

    final response = await _apiClient.getSakeInfo(body);

    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as Map<String, dynamic>;

      // エラーメッセージがある場合はnullを返す
      if (responseBodyJson.containsKey('error')) {
        logger.info('日本酒情報の取得に失敗: ${responseBodyJson['error']}');
        return null;
      }

      // APIレスポンスの構造に応じて適切に変換
      Map<String, dynamic> sakeJson;
      if (responseBodyJson.containsKey('sake')) {
        sakeJson = Map<String, dynamic>.from(responseBodyJson['sake'] as Map);
      } else {
        sakeJson = Map<String, dynamic>.from(responseBodyJson);
      }

      // sakeMeterValueが文字列の場合は数値に変換
      if (sakeJson.containsKey('sakeMeterValue') &&
          sakeJson['sakeMeterValue'] is String) {
        try {
          final valueStr = sakeJson['sakeMeterValue'] as String;
          // +4のような形式の場合は+を除去
          final cleanValue = valueStr.replaceAll('+', '');
          sakeJson['sakeMeterValue'] = int.tryParse(cleanValue);
        } catch (e) {
          // 変換できない場合はnullに
          sakeJson['sakeMeterValue'] = null;
        }
      }

      return sakeJson;
    } else {
      logger.shout(response.error);
      return null;
    }
  }

  // 酒瓶画像を認識する
  Future<SakeBottleRecognitionResponse?> recognizeSakeBottle(
    File file, {
    File? secondaryFile,
  }) async {
    try {
      // トリミング処理はmain_search_page_notifierで行うため、ここでは行わない
      final baseFile = await ImageUtils.compressAndEncodeImage(file);
      final secondaryBaseFile = secondaryFile == null
          ? null
          : await ImageUtils.compressAndEncodeImage(secondaryFile);
      logger.shout(baseFile.length);
      final response = await _apiClient.recognizeSakeBottle(
        baseFile,
        secondaryBaseFile,
      );

      if (response.isSuccessful) {
        final body = response.body;
        if (body == null) {
          logger.shout('酒瓶認識API: レスポンスボディがnullです');
          return null;
        }

        logger.info('酒瓶認識API成功: ${body.toString()}');

        return SakeBottleRecognitionResponse(
          sakeName: body['sakeName'] as String?,
          type: body['type'] as String?,
        );
      } else {
        final statusCode = response.statusCode;
        final errorPayload = response.error;
        final message = _extractBottleErrorMessage(errorPayload);
        logger.shout(
          '酒瓶認識API失敗: ステータスコード=$statusCode, メッセージ=$message, エラー=${response.error}',
        );
        throw SakeBottleRecognitionException(
          statusCode: statusCode,
          message: message,
        );
      }
    } on SakeBottleRecognitionException catch (e) {
      logger.shout('酒瓶認識API例外: $e');
      rethrow;
    } catch (e, stackTrace) {
      // 例外の詳細をログに出力
      logger.shout('酒瓶認識API例外: $e');
      logger.shout('スタックトレース: $stackTrace');
      return null;
    }
  }

  Future<List<Sake>> recognizeSakeBottleCandidates(
    File file, {
    File? secondaryFile,
  }) async {
    final baseFile = await ImageUtils.compressAndEncodeImage(file);
    final secondaryBaseFile = secondaryFile == null
        ? null
        : await ImageUtils.compressAndEncodeImage(secondaryFile);
    final response = await _apiClient.recognizeSakeBottleCandidates(
      baseFile,
      secondaryBaseFile,
    );
    if (!response.isSuccessful || response.body == null) {
      throw SakeBottleRecognitionException(
        statusCode: response.statusCode,
        message: _extractBottleErrorMessage(response.error),
      );
    }
    final rawCandidates = response.body!['candidates'];
    if (rawCandidates is! List) return const <Sake>[];
    return rawCandidates
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(
          (item) => Sake(
            name: item['sakeName']?.toString().trim() ?? '',
            type: item['type']?.toString().trim(),
            brewery: item['brewery']?.toString().trim(),
          ),
        )
        .where((item) => isPlausibleRecognizedSakeName(item.name))
        .take(7)
        .toList(growable: false);
  }

  Future<SakeBottleComprehensiveResponse?> comprehensiveSakeBottleAnalysis(
    File file, {
    String? preferences,
    int? sakeId,
    String? scanSessionId,
  }) async {
    try {
      final baseFile = await ImageUtils.compressAndEncodeImage(file);
      final payload = <String, dynamic>{
        'file': baseFile,
        'locale': await resolveAppLocaleLanguageCode(),
      };
      if (preferences != null && preferences.isNotEmpty) {
        payload['preferences'] = preferences;
      }
      if (sakeId != null) {
        payload['sakeId'] = sakeId;
      }
      if (scanSessionId != null && scanSessionId.isNotEmpty) {
        payload['scanSessionId'] = scanSessionId;
      }
      final response = await _apiClient.comprehensiveSakeBottleAnalysis(
        payload,
      );

      if (response.isSuccessful) {
        final body = response.body;
        if (body is! Map<String, dynamic>) {
          logger.shout('酒瓶包括解析API: レスポンスボディが不正です');
          return null;
        }

        final infoJson = body['sakeInfo'] as Map<String, dynamic>?;
        Sake? sakeInfo;
        if (infoJson != null) {
          sakeInfo = Sake.fromJson(infoJson);
        }

        final recognizedName = body['sakeName']?.toString().trim();
        if (sakeInfo != null && !isPlausibleRecognizedSakeName(sakeInfo.name)) {
          sakeInfo = isPlausibleRecognizedSakeName(recognizedName)
              ? sakeInfo.copyWith(name: recognizedName)
              : null;
        }

        final responseSakeId = _parseOptionalInt(body['sakeId']) ?? sakeId;
        if (sakeInfo != null && responseSakeId != null) {
          sakeInfo = sakeInfo.copyWith(sakeId: responseSakeId);
        }
        final manualSearchQuery = (body['manualSearchQuery'] as String?)
            ?.trim();
        final manualSearchSuggested =
            body['manualSearchSuggested'] == true &&
            isPlausibleRecognizedSakeName(manualSearchQuery);

        return SakeBottleComprehensiveResponse(
          sakeId: responseSakeId,
          sakeName: isPlausibleRecognizedSakeName(recognizedName)
              ? recognizedName
              : null,
          type: body['type'] as String?,
          sakeInfo: sakeInfo,
          manualSearchSuggested: manualSearchSuggested,
          manualSearchQuery: manualSearchQuery,
        );
      } else {
        final statusCode = response.statusCode;
        final errorPayload = response.error;
        final message = _extractBottleErrorMessage(errorPayload);
        logger.shout(
          '酒瓶包括解析API失敗: ステータスコード=$statusCode, メッセージ=$message, エラー=${response.error}',
        );
        throw SakeBottleRecognitionException(
          statusCode: statusCode,
          message: message,
        );
      }
    } on SakeBottleRecognitionException {
      rethrow;
    } catch (e, stackTrace) {
      logger.shout('酒瓶包括解析API例外: $e');
      logger.shout('スタックトレース: $stackTrace');
      return null;
    }
  }

  Future<String?> analyzeSakePreference(List<FavoriteSake> sakes) async {
    if (sakes.isEmpty) {
      return null;
    }

    final List<Map<String, dynamic>> sakesData = sakes
        .map((sake) => {'sakeName': sake.name, 'type': sake.type ?? ''})
        .toList();

    final body = {'sakes': sakesData};

    final response = await _apiClient.analyzeSakePreference(body);
    if (response.isSuccessful) {
      final responseBodyJson = response.body as Map<String, dynamic>;
      return responseBodyJson['preference'] as String?;
    } else {
      logger.shout(response.error);
      return null;
    }
  }

  String _extractBottleErrorMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final error = payload['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } else if (payload is String && payload.isNotEmpty) {
      return payload;
    }
    return '酒瓶の認識に失敗しました';
  }

  int? _parseOptionalInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class SakeBottleRecognitionException implements Exception {
  SakeBottleRecognitionException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() =>
      'SakeBottleRecognitionException(statusCode: $statusCode, message: $message)';
}
