import 'package:firebase_auth/firebase_auth.dart';

import '../../common/logger.dart';
import '../../infrastructure/api_client/api_client.dart';

class SakeUserRepository {
  SakeUserRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> registerUser(User user) async {
    try {
      final existing = await fetchUser(user.uid);
      if (existing != null) {
        logger.info('既に登録済みのため register をスキップします: ${user.uid}');
        return;
      }
    } catch (error, stackTrace) {
      logger.info('既存ユーザー確認に失敗しましたが登録を継続します: $error');
      logger.info(stackTrace.toString());
    }

    try {
      final resolvedDisplayName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : null;
      final emailLocalPart = () {
        final email = user.email;
        if (email == null) {
          return null;
        }
        final local = email.split('@').first.trim();
        if (local.isEmpty) {
          return null;
        }
        return local;
      }();
      final resolvedUsername = resolvedDisplayName ??
          emailLocalPart ??
          'sake_user_${user.uid.substring(0, 6)}';

      final payload = <String, dynamic>{
        'userId': user.uid,
        'displayName': resolvedDisplayName ?? resolvedUsername,
        'photoUrl': user.photoURL,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.registerSakeUser(payload);
      if (!response.isSuccessful) {
        logger.warning(
          'ユーザー登録に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
      } else {
        logger.info('ユーザー登録に成功しました: ${user.uid}');
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
        if (response.statusCode == 404) {
          logger.info('ユーザー情報が見つかりませんでした (未登録かもしれません): $userId');
        } else {
          logger.warning(
            'ユーザー情報の取得に失敗しました: status=${response.statusCode}, error=${response.error}',
          );
        }
        return null;
      }

      final body = response.body;
      if (body is! Map) {
        logger.warning('ユーザー情報のレスポンス形式が想定外です: ${response.body}');
        return null;
      }

      Map<String, dynamic>? userMap;
      if (body['user'] is Map) {
        userMap = Map<String, dynamic>.from(body['user'] as Map);
      } else if (body is Map<String, dynamic>) {
        userMap = Map<String, dynamic>.from(body);
      }

      if (userMap == null) {
        logger.warning('ユーザー情報のレスポンスから user データを取得できませんでした: ${response.body}');
        return null;
      }

      logger.info('[SakeUserRepository.fetchUser] レスポンス: $userMap');

      return userMap;
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

      logger
          .info('[SakeUserRepository.updateUsername] レスポンス: ${response.body}');
      return true;
    } catch (error, stackTrace) {
      logger.warning('ユーザー名更新処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }

  Future<bool> deleteAccount(String userId) async {
    try {
      final payload = <String, dynamic>{'userId': userId};
      final response = await _apiClient.deleteSakeUser(payload);
      if (!response.isSuccessful) {
        logger.warning(
          'アカウント削除リクエストに失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return false;
      }
      logger.info('アカウント削除リクエストを送信しました: $userId');
      return true;
    } catch (error, stackTrace) {
      logger.warning('アカウント削除処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }
}
