import '../../infrastructure/api_client/sake_menu_recognition_api_client.dart';
import '../constants/sake_community.dart';
import 'sake_scan_repository.dart';

abstract class SakeCommunityRepository {
  Future<bool> hasAcceptedLabelConsent();
  Future<void> acceptLabelConsent();
  Future<void> saveReview({
    required int sakeId,
    required int overallRating,
    required Map<String, int> tasteRatings,
    String? comment,
    String? savedId,
  });
  Future<void> deleteReview(int sakeId);
  Future<void> reportImage(int imageId, {String? reason});
  Future<void> deleteImage(int imageId);
  Future<void> reportReview(int reviewId, {String? reason});
}

class SakeCommunityApiRepository implements SakeCommunityRepository {
  SakeCommunityApiRepository(
    this._apiClient, {
    this.requestTimeout = const Duration(seconds: 30),
  });

  final SakeMenuRecognitionApiClient _apiClient;
  final Duration requestTimeout;

  @override
  Future<bool> hasAcceptedLabelConsent() async {
    final response = await _apiClient.fetchSakeLabelConsent().timeout(
      requestTimeout,
    );
    return _requireBody(response)['agreed'] == true;
  }

  @override
  Future<void> acceptLabelConsent() async {
    final response = await _apiClient
        .acceptSakeLabelConsent(<String, dynamic>{
          'consentVersion': sakeLabelConsentVersion,
          'agreed': true,
        })
        .timeout(requestTimeout);
    _requireBody(response);
  }

  @override
  Future<void> saveReview({
    required int sakeId,
    required int overallRating,
    required Map<String, int> tasteRatings,
    String? comment,
    String? savedId,
  }) async {
    final response = await _apiClient
        .saveSakeReview(sakeId, <String, dynamic>{
          'overallRating': overallRating,
          'tasteRatings': tasteRatings,
          if (comment?.trim().isNotEmpty == true) 'comment': comment!.trim(),
          if (savedId?.trim().isNotEmpty == true) 'savedId': savedId!.trim(),
        })
        .timeout(requestTimeout);
    _requireBody(response);
  }

  @override
  Future<void> deleteReview(int sakeId) =>
      _expectSuccess(_apiClient.deleteSakeReview(sakeId));

  @override
  Future<void> reportImage(int imageId, {String? reason}) => _expectSuccess(
    _apiClient.reportSakeCommunityImage(imageId, <String, dynamic>{
      if (reason != null) 'reason': reason,
    }),
  );

  @override
  Future<void> deleteImage(int imageId) =>
      _expectSuccess(_apiClient.deleteSakeCommunityImage(imageId));

  @override
  Future<void> reportReview(int reviewId, {String? reason}) => _expectSuccess(
    _apiClient.reportSakeCommunityReview(reviewId, <String, dynamic>{
      if (reason != null) 'reason': reason,
    }),
  );

  Map<String, dynamic> _requireBody(dynamic response) {
    if (response.isSuccessful && response.body is Map<String, dynamic>) {
      return response.body as Map<String, dynamic>;
    }
    throw SakeScanException(
      kind: SakeScanErrorKind.unknown,
      statusCode: response.statusCode as int?,
      message: response.error?.toString() ?? 'コミュニティ機能の通信に失敗しました',
    );
  }

  Future<void> _expectSuccess(Future<dynamic> request) async {
    final response = await request.timeout(requestTimeout);
    if (response.isSuccessful) return;
    _requireBody(response);
  }
}
