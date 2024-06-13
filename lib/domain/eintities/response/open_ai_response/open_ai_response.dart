import 'package:freezed_annotation/freezed_annotation.dart';

part 'open_ai_response.freezed.dart';
part 'open_ai_response.g.dart';

@freezed
abstract class OpenAIResponse with _$OpenAIResponse {
  factory OpenAIResponse({
    String? title,
    Map<String, String>? description,
    String? etc,
    // @JsonKey(name: 'avatar_url') String avatarUrl,
  }) = _OpenAIResponse;

  OpenAIResponse._();

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIResponseFromJson(json);
}
