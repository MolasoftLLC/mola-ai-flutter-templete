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
}
