// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sake_menu_recognition_api_client.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations, unnecessary_brace_in_string_interps
class _$SakeMenuRecognitionApiClient extends SakeMenuRecognitionApiClient {
  _$SakeMenuRecognitionApiClient([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = SakeMenuRecognitionApiClient;

  @override
  Future<Response<dynamic>> recognizeMenu(String file) {
    final Uri $url = Uri.parse('/api/menu-recognition/recognize');
    final List<PartValue> $parts = <PartValue>[PartValue<String>('file', file)];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> extractSakeInfo(String file) {
    final Uri $url = Uri.parse('/api/menu-recognition/extract');
    final List<PartValue> $parts = <PartValue>[PartValue<String>('file', file)];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> extractSakeInfoJson(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/menu-recognition/extract');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getSakeInfoBatch(Map<String, dynamic> body) {
    final Uri $url = Uri.parse(
      '/api/menu-recognition/perplexity/sake-info-batch',
    );
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getSakeInfo(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/menu-recognition/perplexity/sake-info');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> resolveSakeCandidate(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/sakes/resolve-candidate');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> recognizeSakeBottle(
    String file,
    String? secondaryFile,
  ) {
    final Uri $url = Uri.parse('/api/sake-bottle/recognize');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>('file', file),
      PartValue<String?>('secondaryFile', secondaryFile),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> recognizeSakeBottleCandidates(
    String file,
    String? secondaryFile,
    String? scanSessionId,
  ) {
    final Uri $url = Uri.parse('/api/sake-bottle/scan/ai-candidates');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>('file', file),
      PartValue<String?>('secondaryFile', secondaryFile),
      PartValue<String?>('scanSessionId', scanSessionId),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> comprehensiveSakeBottleAnalysis(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/sake-bottle/comprehensive-analysis');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> scanSakeFrontLabel(
    MultipartFile image,
    String locale,
  ) {
    final Uri $url = Uri.parse('/api/sake-bottle/scan/front');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>('locale', locale),
      PartValueFile<MultipartFile>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> scanSakeBackLabel(
    String scanSessionId,
    MultipartFile image,
    String locale,
  ) {
    final Uri $url = Uri.parse('/api/sake-bottle/scan/${scanSessionId}/back');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>('locale', locale),
      PartValueFile<MultipartFile>('image', image),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> confirmScannedSake(
    String scanSessionId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse(
      '/api/sake-bottle/scan/${scanSessionId}/confirm',
    );
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<dynamic>> rejectScannedSakeCandidates(
    String scanSessionId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/sake-bottle/scan/${scanSessionId}/reject');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> fetchSakeOverview(
    int sakeId,
    String locale,
    bool trackView,
  ) {
    final Uri $url = Uri.parse('/api/sakes/${sakeId}/overview');
    final Map<String, dynamic> $params = <String, dynamic>{
      'locale': locale,
      'trackView': trackView,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> fetchSakeTasteProfiles(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/sakes/taste-profiles');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> fetchSakeLabelConsent() {
    final Uri $url = Uri.parse('/api/sakes/label-consent');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> acceptSakeLabelConsent(
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/sakes/label-consent');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> saveSakeReview(
    int sakeId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/sakes/${sakeId}/review');
    final $body = body;
    final Request $request = Request('PUT', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<dynamic>> deleteSakeReview(int sakeId) {
    final Uri $url = Uri.parse('/api/sakes/${sakeId}/review');
    final Request $request = Request('DELETE', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> reportSakeCommunityImage(
    int imageId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/sakes/community/images/${imageId}/report');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<dynamic>> deleteSakeCommunityImage(int imageId) {
    final Uri $url = Uri.parse('/api/sakes/community/images/${imageId}');
    final Request $request = Request('DELETE', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> reportSakeCommunityReview(
    int reviewId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse(
      '/api/sakes/community/reviews/${reviewId}/report',
    );
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<dynamic>> analyzeSakePreference(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/sake-preference/analyze');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }
}
