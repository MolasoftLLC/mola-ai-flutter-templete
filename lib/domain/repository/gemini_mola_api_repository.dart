import 'dart:convert';
import 'dart:io' as Io;
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:rxdart/rxdart.dart';

import '../../common/exception/exception.dart';
import '../../common/logger.dart';
import '../../infrastructure/api_client/api_client.dart';
import '../eintities/request/favorite_body.dart';

class GeminiMolaApiRepository {
  GeminiMolaApiRepository(this._apiClient);

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

  Future<String> promptWithText(String text) async {
    final response = await _apiClient.promptWithText({'text': text});
    if (response.isSuccessful) {
      final responseBodyJson = response.body as String;
      return responseBodyJson;
    } else {
      logger.shout(response.error);
      return '';
    }
  }

  Future<String> promptWithImage(File file, String? hint) async {
    final baseFile = base64Encode(Io.File(file.path).readAsBytesSync());
    logger.shout(baseFile);
    final response = await _apiClient.promptWithImage(baseFile, hint ?? '');
    if (response.isSuccessful) {
      final responseBodyJson = response.body as String;
      logger.shout(responseBodyJson);
      return responseBodyJson;
    } else {
      logger.shout(response.error);
      return '';
    }
  }

  Future<String> promptWithFavorite(
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
}
