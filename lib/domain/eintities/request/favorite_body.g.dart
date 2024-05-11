// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FavoriteBodyImpl _$$FavoriteBodyImplFromJson(Map<String, dynamic> json) =>
    _$FavoriteBodyImpl(
      flavors:
          (json['flavors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      designs:
          (json['designs'] as List<dynamic>?)?.map((e) => e as String).toList(),
      tastes:
          (json['tastes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      prefecture: json['prefecture'] as String?,
    );

Map<String, dynamic> _$$FavoriteBodyImplToJson(_$FavoriteBodyImpl instance) =>
    <String, dynamic>{
      'flavors': instance.flavors,
      'designs': instance.designs,
      'tastes': instance.tastes,
      'prefecture': instance.prefecture,
    };
