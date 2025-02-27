// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sake_menu_recognition_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SakeMenuRecognitionResponseImpl _$$SakeMenuRecognitionResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$SakeMenuRecognitionResponseImpl(
      sakes: (json['sakes'] as List<dynamic>?)
          ?.map((e) => Sake.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$SakeMenuRecognitionResponseImplToJson(
        _$SakeMenuRecognitionResponseImpl instance) =>
    <String, dynamic>{
      'sakes': instance.sakes,
    };

_$SakeImpl _$$SakeImplFromJson(Map<String, dynamic> json) => _$SakeImpl(
      name: json['name'] as String?,
      brewery: json['brewery'] as String?,
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
      taste: json['taste'] as String?,
      sakeMeterValue: (json['sakeMeterValue'] as num?)?.toInt(),
      type: json['type'] as String?,
      price: json['price'] as String?,
      description: json['description'] as String?,
      recommendationScore: (json['recommendationScore'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SakeImplToJson(_$SakeImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'brewery': instance.brewery,
      'types': instance.types,
      'taste': instance.taste,
      'sakeMeterValue': instance.sakeMeterValue,
      'type': instance.type,
      'price': instance.price,
      'description': instance.description,
      'recommendationScore': instance.recommendationScore,
    };
