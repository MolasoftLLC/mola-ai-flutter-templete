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
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'file',
        file,
      )
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
}
