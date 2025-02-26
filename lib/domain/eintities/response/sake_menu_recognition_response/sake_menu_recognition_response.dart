import 'package:freezed_annotation/freezed_annotation.dart';

part 'sake_menu_recognition_response.freezed.dart';
part 'sake_menu_recognition_response.g.dart';

@freezed
class SakeMenuRecognitionResponse with _$SakeMenuRecognitionResponse {
  const factory SakeMenuRecognitionResponse({
    required List<Sake> sakes,
  }) = _SakeMenuRecognitionResponse;

  factory SakeMenuRecognitionResponse.fromJson(Map<String, dynamic> json) =>
      _$SakeMenuRecognitionResponseFromJson(json);
}

@freezed
class Sake with _$Sake {
  const factory Sake({
    required String name,
    required String type,
    required String brewery,
    required List<String> types,
    required String taste,
    required int sakeMeterValue,
  }) = _Sake;

  factory Sake.fromJson(Map<String, dynamic> json) => _$SakeFromJson(json);
}
