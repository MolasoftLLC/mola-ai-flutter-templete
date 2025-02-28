import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:rxdart/rxdart.dart';

import '../../common/exception/exception.dart';
import '../../common/logger.dart';
import '../../common/utils/image_utils.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../infrastructure/api_client/sake_menu_recognition_api_client.dart';
import '../eintities/response/sake_bottle_recognition_response/sake_bottle_recognition_response.dart';

class SakeMenuRecognitionRepository {
  SakeMenuRecognitionRepository(this._apiClient);

  final SakeMenuRecognitionApiClient _apiClient;

  final _errorAuth = PublishSubject<MolaApiException>();

  Stream<MolaApiException> get errorAuth => _errorAuth;

  void _handleError({
    required Response response,
    bool throwsAnyError = false,
  }) {
    final apiException = MolaApiException.fromObject(response.error!);
    if (response.statusCode != 403 && response.statusCode != 400) {
      throw throwsAnyError ? MolaApiException.anyError() : apiException;
    }
    _errorAuth.add(apiException);
    logger.info(response.error);
  }

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
    final baseFile = await ImageUtils.compressAndEncodeImage(file);
    final response = await _apiClient.extractSakeInfo(baseFile);
    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as Map<String, dynamic>;

      // 'sakes'キーから日本酒リストを取得
      final sakesList = (responseBodyJson['sakes'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // 各日本酒情報をSakeオブジェクトに変換
      return sakesList.map((sakeMap) => Sake.fromJson(sakeMap)).toList();
    } else {
      logger.shout(response.error);
      return null;
    }
  }

  /// 日本酒名と種類のリストから詳細情報を取得する
  Future<SakeMenuRecognitionResponse?> getSakeInfoBatch(
      List<Map<String, dynamic>> sakes) async {
    final body = {'sakes': sakes};

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
  Future<Sake?> getSakeInfo(String sakeName,
      {String? type, String? preferences}) async {
    if (sakeName.isEmpty) {
      return null;
    }

    final Map<String, dynamic> body = {'sakeName': sakeName};

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
        sakeJson = responseBodyJson['sake'] as Map<String, dynamic>;
      } else {
        sakeJson = responseBodyJson;
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

      return Sake.fromJson(sakeJson);
    } else {
      logger.shout(response.error);
      return null;
    }
  }

  // 酒瓶画像を認識する
  Future<SakeBottleRecognitionResponse?> recognizeSakeBottle(File file) async {
    try {
      final baseFile = await ImageUtils.compressAndEncodeImage(file);
      logger.shout(baseFile.length);
      final response = await _apiClient.recognizeSakeBottle(
        baseFile,
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
        // エラーレスポンスの詳細をログに出力
        logger.shout(
            '酒瓶認識API失敗: ステータスコード=${response.statusCode}, エラー=${response.error}');
        return null;
      }
    } catch (e, stackTrace) {
      // 例外の詳細をログに出力
      logger.shout('酒瓶認識API例外: $e');
      logger.shout('スタックトレース: $stackTrace');
      return null;
    }
  }
}
