import 'package:mola_gemini_flutter_template/common/logger.dart';
import '../../infrastructure/api_client/api_client.dart';

class UserPreferenceRepository {
  UserPreferenceRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<String?> fetchPreferences(String userId) async {
    try {
      final response = await _apiClient.fetchPreferences(userId);
      if (!response.isSuccessful) {
        logger.warning(
          '好み設定の取得に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return null;
      }

      final body = response.body;
      if (body is Map<String, dynamic>) {
        final preferences = body['preferences'];
        if (preferences is String) {
          return preferences;
        }
      } else if (body is String && body.isNotEmpty) {
        return body;
      }

      logger.info('好み設定のレスポンスが空でした');
      return null;
    } catch (error, stackTrace) {
      logger.warning('好み設定の取得処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return null;
    }
  }

  Future<bool> updatePreferences({
    required String userId,
    required String preferences,
  }) async {
    try {
      final payload = <String, dynamic>{
        'userId': userId,
        'preferences': preferences,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.updatePreferences(payload);
      if (!response.isSuccessful) {
        logger.warning(
          '好み設定の更新に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return false;
      }
      return true;
    } catch (error, stackTrace) {
      logger.warning('好み設定の更新処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }
}
