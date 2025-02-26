import 'dart:convert';
import 'dart:io' as Io;
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:rxdart/rxdart.dart';

import '../../common/exception/exception.dart';
import '../../common/logger.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../infrastructure/api_client/sake_menu_recognition_api_client.dart';

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
    final baseFile = base64Encode(Io.File(file.path).readAsBytesSync());
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
}
