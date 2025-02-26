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
  
  /// メニュー画像から日本酒名と種類のみを抽出する
  Future<Map<String, dynamic>?> extractSakeInfo(File file) async {
    final baseFile = base64Encode(Io.File(file.path).readAsBytesSync());
    final response = await _apiClient.extractSakeInfo(baseFile);
    if (response.isSuccessful) {
      logger.shout(response.body);
      return response.body as Map<String, dynamic>;
    } else {
      logger.shout(response.error);
      return null;
    }
  }
  
  /// 日本酒名と種類のリストから詳細情報を取得する
  Future<SakeMenuRecognitionResponse?> getSakeInfoBatch(List<Map<String, dynamic>> sakes) async {
    // 新しいAPIクライアントを作成する必要があるが、一時的にここで実装
    final url = '/api/perplexity/sake-info-batch';
    final body = {'sakes': sakes};
    
    final request = Request(
      'POST',
      Uri.parse(url),
      body,
    );
    
    final response = await _apiClient.client.send(request);
    
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
