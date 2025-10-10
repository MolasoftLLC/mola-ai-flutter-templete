import 'package:mola_gemini_flutter_template/common/logger.dart';
import '../../infrastructure/api_client/api_client.dart';
import '../notifier/favorite/favorite_notifier.dart';

class FavoriteSyncRepository {
  FavoriteSyncRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<FavoriteSake>> fetchFavorites(String userId) async {
    try {
      final response = await _apiClient.fetchFavorites(userId);
      if (!response.isSuccessful || response.body == null) {
        logger.warning(
          'お気に入りの取得に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return const <FavoriteSake>[];
      }

      final rawBody = response.body;
      final List<dynamic> rawList;
      if (rawBody is List) {
        rawList = rawBody;
      } else if (rawBody is Map<String, dynamic> &&
          rawBody['favorites'] is List) {
        rawList = rawBody['favorites'] as List<dynamic>;
      } else {
        logger.warning('お気に入りの取得に失敗しました: 想定外のレスポンス形式');
        return const <FavoriteSake>[];
      }

      final result = <FavoriteSake>[];
      for (final item in rawList) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final name = item['name'];
        if (name is! String || name.isEmpty) {
          continue;
        }
        final type = item['type'];
        result.add(
          FavoriteSake(
            name: name,
            type: type is String && type.isNotEmpty ? type : null,
          ),
        );
      }

      return result;
    } catch (error, stackTrace) {
      logger.warning('お気に入り取得処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return const <FavoriteSake>[];
    }
  }

  Future<bool> addFavorite({
    required String userId,
    required FavoriteSake sake,
  }) async {
    try {
      final payload = <String, dynamic>{
        'userId': userId,
        'name': sake.name,
        'type': sake.type,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.addFavorite(payload);
      if (!response.isSuccessful) {
        logger.warning(
          'お気に入りの追加に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return false;
      }
      return true;
    } catch (error, stackTrace) {
      logger.warning('お気に入り追加処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }

  Future<bool> removeFavorite({
    required String userId,
    required FavoriteSake sake,
  }) async {
    try {
      final payload = <String, dynamic>{
        'userId': userId,
        'name': sake.name,
        'type': sake.type,
      };

      final response = await _apiClient.removeFavorite(payload);
      if (!response.isSuccessful) {
        logger.warning(
          'お気に入りの削除に失敗しました: status=${response.statusCode}, error=${response.error}',
        );
        return false;
      }
      return true;
    } catch (error, stackTrace) {
      logger.warning('お気に入り削除処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }
}
