import 'dart:convert';
import 'dart:io' as Io;
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:rxdart/rxdart.dart';

import '../../common/exception/exception.dart';
import '../../common/logger.dart';
import '../../infrastructure/api_client/api_client.dart';

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
      logger.shout(responseBodyJson);
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
}
