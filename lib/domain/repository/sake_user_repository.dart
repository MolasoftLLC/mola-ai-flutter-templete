import 'package:firebase_auth/firebase_auth.dart';

import '../../common/logger.dart';
import '../../infrastructure/api_client/api_client.dart';

class SakeUserRepository {
  SakeUserRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> registerUser(User user) async {
    try {
      final payload = <String, dynamic>{
        'userId': user.uid,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.registerSakeUser(payload);
      if (!response.isSuccessful) {
        logger.warning(
          'ユーザー登録に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
      }
    } catch (error, stackTrace) {
      logger.warning('ユーザー登録処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
    }
  }

  Future<Map<String, dynamic>?> fetchUser(String userId) async {
    try {
      final response = await _apiClient.fetchSakeUser(userId);
      if (!response.isSuccessful || response.body == null) {
        logger.warning(
          'ユーザー情報の取得に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return null;
      }

      final body = response.body;
      if (body is Map<String, dynamic>) {
        return body;
      }

      logger.warning('ユーザー情報のレスポンス形式が想定外です');
      return null;
    } catch (error, stackTrace) {
      logger.warning('ユーザー情報取得で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return null;
    }
  }

  Future<bool> updateUsername(String username) async {
    try {
      final payload = <String, dynamic>{'username': username};
      final response = await _apiClient.updateUsername(payload);
      if (!response.isSuccessful) {
        logger.warning(
          'ユーザー名更新に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return false;
      }
      return true;
    } catch (error, stackTrace) {
      logger.warning('ユーザー名更新処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }
}
