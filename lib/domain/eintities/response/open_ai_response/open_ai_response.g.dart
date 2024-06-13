// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_ai_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OpenAIResponseImpl _$$OpenAIResponseImplFromJson(Map<String, dynamic> json) =>
    _$OpenAIResponseImpl(
      title: json['title'] as String?,
      description: (json['description'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      etc: json['etc'] as String?,
    );

Map<String, dynamic> _$$OpenAIResponseImplToJson(
        _$OpenAIResponseImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'etc': instance.etc,
    };
