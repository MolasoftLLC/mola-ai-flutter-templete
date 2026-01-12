// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations, unnecessary_brace_in_string_interps
class _$ApiClient extends ApiClient {
  _$ApiClient([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = ApiClient;

  @override
  Future<Response<dynamic>> checkApiUseCount() {
    final Uri $url = Uri.parse('/check_api_use_count');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> promptWithText(Map<String, String> text) {
    final Uri $url = Uri.parse('/prompt_with_text');
    final $body = text;
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> promptWithTextByOpenAI(Map<String, String> text) {
    final Uri $url = Uri.parse('/open_ai/prompt_with_text');
    final $body = text;
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> promptWithImage(
    String image,
    String hint,
  ) {
    final Uri $url = Uri.parse('/prompt_with_image');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'image',
        image,
      ),
      PartValue<String>(
        'hint',
        hint,
      ),
    ];
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
  Future<Response<dynamic>> promptWithImageByOpenAI(
    String image,
    String hint,
  ) {
    final Uri $url = Uri.parse('/open_ai/prompt_with_image');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'image',
        image,
      ),
      PartValue<String>(
        'hint',
        hint,
      ),
    ];
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
  Future<Response<dynamic>> promptWithMenuByOpenAI(
    String image,
    List<String> favorites,
  ) {
    final Uri $url = Uri.parse('/open_ai/prompt_with_menu');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'image',
        image,
      ),
      PartValue<List<String>>(
        'favorites',
        favorites,
      ),
    ];
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
  Future<Response<dynamic>> promptWithFavorite(FavoriteBody body) {
    final Uri $url = Uri.parse('/prompt_with_favorite');
    final $body = body;
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getLatestVersion() {
    final Uri $url = Uri.parse('/get_latest_version');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> uploadSavedSakeAnalysisStart(
      Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/saved-sakes/analysis-start');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> uploadSavedSakeAnalysisComplete(
      Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/saved-sakes/analysis-complete');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> markSavedSakeAnalysisFailed(
    String savedId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/saved-sakes/${savedId}/analysis-failed');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> fetchSavedSakes(String userId) {
    final Uri $url = Uri.parse('/saved-sakes');
    final Map<String, dynamic> $params = <String, dynamic>{'userId': userId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> fetchSavedSakeTimeline({
    String? userId,
    String? cursor,
    int? limit,
  }) {
    final Uri $url = Uri.parse('/saved-sakes/timeline');
    final Map<String, dynamic> $params = <String, dynamic>{
      'userId': userId,
      'cursor': cursor,
      'limit': limit,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> fetchTimelineEnvyRanking({int? limit}) {
    final Uri $url = Uri.parse('/saved-sakes/timeline/envy-ranking');
    final Map<String, dynamic> $params = <String, dynamic>{'limit': limit};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> incrementSavedSakeEnvy(
    String savedId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/saved-sakes/${savedId}/envy');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> reportSavedSake(
    String savedId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/saved-sakes/${savedId}/report');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateSavedSakeVisibility(
    String savedId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/saved-sakes/${savedId}/visibility');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> removeSavedSake(
    String savedId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/saved-sakes/${savedId}/remove');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> uploadSavedSakeImage(
    String savedId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/saved-sakes/${savedId}/images');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> deleteSavedSakeImage(
    String savedId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/saved-sakes/${savedId}/images/delete');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> comprehensiveSakeBottleAnalysis(
      Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/sake-bottle/comprehensive-analysis');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> fetchFavorites(String userId) {
    final Uri $url = Uri.parse('/favorites');
    final Map<String, dynamic> $params = <String, dynamic>{'userId': userId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> addFavorite(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/favorites');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> removeFavorite(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/favorites/delete');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> fetchPreferences(String userId) {
    final Uri $url = Uri.parse('/preferences');
    final Map<String, dynamic> $params = <String, dynamic>{'userId': userId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updatePreferences(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/preferences');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> fetchTasteProfile(String userId) {
    final Uri $url = Uri.parse('/preferences/taste-profile');
    final Map<String, dynamic> $params = <String, dynamic>{'userId': userId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> analyzeTasteProfile(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/preferences/taste-profile/analyze');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> registerSakeUser(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/sake-users/register');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> fetchSakeUser(String userId) {
    final Uri $url = Uri.parse('/sake-users/me');
    final Map<String, dynamic> $params = <String, dynamic>{'userId': userId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateUsername(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/sake-users/username');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> uploadUserPhoto(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/sake-users/icon');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> deleteSakeUser(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/sake-users/delete');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> fetchAchievementStats(String userId) {
    final Uri $url = Uri.parse('/users/${userId}/achievement-stats');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
