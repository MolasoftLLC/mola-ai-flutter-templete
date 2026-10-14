import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/analytics/app_analytics.dart' show analyticsId;
import '../../infrastructure/api_client/api_client.dart';
import 'auth_repository.dart';

class AppFeedbackIdentity {
  const AppFeedbackIdentity({required this.userId, this.guestId});
  final String userId;
  final String? guestId;

  static Future<AppFeedbackIdentity> load(AuthRepository auth) async {
    final uid = auth.currentUser?.uid;
    if (uid != null) return AppFeedbackIdentity(userId: uid);
    final prefs = await SharedPreferences.getInstance();
    var guestId = prefs.getString('app_feedback_guest_id_v1');
    if (guestId == null ||
        !RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(guestId)) {
      guestId = analyticsId();
      await prefs.setString('app_feedback_guest_id_v1', guestId);
    }
    return AppFeedbackIdentity(userId: 'guest_$guestId', guestId: guestId);
  }
}

class AppFeedbackException implements Exception {
  const AppFeedbackException(this.message);
  final String message;
}

class AppFeedbackRepository {
  AppFeedbackRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<void> submit({
    required AppFeedbackIdentity identity,
    required String requestId,
    required String content,
  }) async {
    final info = await PackageInfo.fromPlatform();
    final response = await _apiClient
        .sendAppFeedback({
          'requestId': requestId,
          'userId': identity.userId,
          if (identity.guestId != null) 'guestId': identity.guestId,
          'content': content.trim(),
          'version': '${info.version}+${info.buildNumber}',
          'platform': Platform.isIOS
              ? 'ios'
              : Platform.isAndroid
              ? 'android'
              : 'other',
        })
        .timeout(const Duration(seconds: 25));
    if (response.isSuccessful &&
        response.body is Map &&
        response.body['accepted'] == true) {
      return;
    }
    final error = response.error;
    throw AppFeedbackException(
      error is Map && error['error'] is String
          ? error['error'] as String
          : '送信できませんでした。入力内容はそのままで、もう一度お試しください。',
    );
  }
}
