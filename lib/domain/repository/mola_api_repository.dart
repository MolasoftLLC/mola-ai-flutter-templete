import 'dart:convert';
import 'dart:io' as Io;
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/open_ai_response/open_ai_response.dart';
import 'package:rxdart/rxdart.dart';

import '../../common/exception/exception.dart';
import '../../common/logger.dart';
import '../../common/utils/image_utils.dart';
import '../../infrastructure/api_client/api_client.dart';
import '../eintities/request/favorite_body.dart';
import '../notifier/favorite/favorite_notifier.dart';

class MolaApiRepository {
  MolaApiRepository(this._apiClient);

  final ApiClient _apiClient;

  final _errorAuth = PublishSubject<MolaApiException>();

  @override
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
              (dynamic e) => OpenAIResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      logger.shout(response.error);
      return [];
    }
  }

  Future<List<OpenAIResponse>> promptWithImageByOpenAI(
      File file, String? hint) async {
    final baseFile = await ImageUtils.compressAndEncodeImage(file);
    final response =
        await _apiClient.promptWithImageByOpenAI(baseFile, hint ?? '');
    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as List<dynamic>;
      return responseBodyJson
          .map(
              (dynamic e) => OpenAIResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      logger.shout(response.error);
      return [];
    }
  }

  Future<String> promptWithFavoriteByOpenAI(
      {List<String>? flavors,
      List<String>? designs,
      List<String>? tastes,
      String? prefecture}) async {
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
    final response =
        await _apiClient.promptWithMenuByOpenAI(baseFile, favorite ?? []);
    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as List<dynamic>;
      return responseBodyJson
          .map(
              (dynamic e) => OpenAIResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      logger.shout(response.error);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestVersion() async {
    final response = await _apiClient.getLatestVersion();
    if (response.isSuccessful) {
      logger.shout(response.body);
      final responseBodyJson = response.body as Map<String, dynamic>;
      return responseBodyJson;
    } else {
      logger.shout(response.error);
    }
    return null;
  }

  Future<String?> analyzeSakePreference(List<FavoriteSake> sakes) async {
    if (sakes.isEmpty) {
      return null;
    }
    
    final List<Map<String, dynamic>> sakesData = sakes.map((sake) => {
      'sakeName': sake.name,
      'type': sake.type ?? '',
    }).toList();
    
    final body = {
      'sakes': sakesData,
    };
    
    final response = await _apiClient.analyzeSakePreference(body);
    if (response.isSuccessful) {
      final responseBodyJson = response.body as Map<String, dynamic>;
      return responseBodyJson['preference'] as String?;
    } else {
      logger.shout(response.error);
      return null;
    }
  }
}
