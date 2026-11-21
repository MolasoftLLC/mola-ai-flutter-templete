import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/open_ai_response/open_ai_response.dart';
import 'package:rxdart/rxdart.dart';

import '../../common/exception/exception.dart';
import '../../common/logger.dart';
import '../../common/utils/image_utils.dart';
import '../../infrastructure/api_client/api_client.dart';
import '../eintities/request/favorite_body.dart';
import '../eintities/app_content.dart';

class MonthlyRecommendationLimitException implements Exception {
  const MonthlyRecommendationLimitException();
}

class MolaApiRepository {
  MolaApiRepository(this._apiClient);

  final ApiClient _apiClient;

  final _errorAuth = PublishSubject<MolaApiException>();

  @override
  Stream<MolaApiException> get errorAuth => _errorAuth;

  void _handleError({required Response response, bool throwsAnyError = false}) {
    final apiException = MolaApiException.fromObject(response.error!);
    if (response.statusCode != 403 && response.statusCode != 400) {
      throw throwsAnyError ? MolaApiException.anyError() : apiException;
    }
    _errorAuth.add(apiException);
    logger.info(response.error);
  }

  Future<int> checkApiUseCount() async {
    final response = await _apiClient.checkApiUseCount();
    if (response.isSuccessful) {
      final responseBodyJson = response.body as int;
      return responseBodyJson;
    } else {
      logger.shout(response.error);
      return 0;
    }
  }

  Future<List<OpenAIResponse>> promptWithTextByOpenAI(String text) async {
    final response = await _apiClient.promptWithTextByOpenAI({'text': text});
    if (response.isSuccessful) {
      final responseBodyJson = response.body as List<dynamic>;
      return responseBodyJson
          .map(
            (dynamic e) => OpenAIResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } else {
      logger.shout(response.error);
      return [];
    }
  }

  Future<List<OpenAIResponse>> promptWithImageByOpenAI(
    File file,
    String? hint,
  ) async {
    final baseFile = await ImageUtils.compressAndEncodeImage(file);
    final response = await _apiClient.promptWithImageByOpenAI(
      baseFile,
      hint ?? '',
    );
    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as List<dynamic>;
      return responseBodyJson
          .map(
            (dynamic e) => OpenAIResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } else {
      logger.shout(response.error);
      return [];
    }
  }

  Future<String> promptWithFavoriteByOpenAI({
    List<String>? flavors,
    List<String>? designs,
    List<String>? tastes,
    String? prefecture,
  }) async {
    if (prefecture == '指定なし') {
      prefecture = null;
    }
    if (designs != null) {
      if (designs.isEmpty) {
        designs = null;
      }
    }
    if (flavors != null) {
      if (flavors.isEmpty) {
        flavors = null;
      }
    }
    if (tastes != null) {
      if (tastes.isEmpty) {
        tastes = null;
      }
    }
    if (prefecture == '指定なし') {
      prefecture = null;
    }
    final body = FavoriteBody(
      flavors: flavors,
      designs: designs,
      tastes: tastes,
      prefecture: prefecture,
    );
    final response = await _apiClient.promptWithFavorite(body);
    if (response.isSuccessful) {
      final responseBodyJson = response.body as String;
      return responseBodyJson;
    } else {
      logger.shout(response.error);
      return '';
    }
  }

  Future<List<OpenAIResponse>> promptWithMenuByOpenAI(
    File file,
    List<String> favorite,
  ) async {
    final baseFile = await ImageUtils.compressAndEncodeImage(file);
    final response = await _apiClient.promptWithMenuByOpenAI(
      baseFile,
      favorite ?? [],
    );
    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as List<dynamic>;
      return responseBodyJson
          .map(
            (dynamic e) => OpenAIResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } else {
      logger.shout(response.error);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestVersion({
    required String platform,
  }) async {
    final response = await _apiClient.getLatestVersion(platform);
    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as Map<String, dynamic>;
      return responseBodyJson;
    } else {
      logger.shout(response.error);
    }
    return null;
  }

  Future<AppContent?> fetchAppContent({required String platform}) async {
    final response = await _apiClient.fetchAppContent(platform);
    if (!response.isSuccessful || response.body is! Map) {
      logger.warning('アプリコンテンツを取得できませんでした: ${response.error}');
      return null;
    }
    return AppContent.fromJson(Map<String, dynamic>.from(response.body as Map));
  }

  Future<List<HomeSakeRecommendation>> fetchHomeSakeRecommendations({
    int limit = 7,
  }) async {
    final response = await _apiClient.fetchHomeSakeRecommendations(limit);
    return _parseHomeRecommendations(response);
  }

  Future<List<HomeSakeRecommendation>> refreshHomeSakeRecommendations() async {
    final response = await _apiClient.refreshHomeSakeRecommendations();
    if (response.statusCode == 429) {
      throw const MonthlyRecommendationLimitException();
    }
    if (response.statusCode == 409) {
      throw const MissingTasteProfileException();
    }
    if (!response.isSuccessful) {
      throw StateError('おすすめの再選定に失敗しました。');
    }
    return _parseHomeRecommendations(response);
  }

  List<HomeSakeRecommendation> _parseHomeRecommendations(Response response) {
    if (!response.isSuccessful || response.body is! Map) return const [];
    final body = Map<String, dynamic>.from(response.body as Map);
    final items = body['recommendations'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) =>
              HomeSakeRecommendation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }
}

class MissingTasteProfileException implements Exception {
  const MissingTasteProfileException();
}
