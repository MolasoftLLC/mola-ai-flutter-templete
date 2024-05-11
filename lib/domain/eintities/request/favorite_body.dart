import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_body.freezed.dart';
part 'favorite_body.g.dart';

@freezed
abstract class FavoriteBody with _$FavoriteBody {
  factory FavoriteBody({
    List<String>? flavors,
    List<String>? designs,
    List<String>? tastes,
    String? prefecture,
  }) = _FavoriteBody;

  FavoriteBody._();

  factory FavoriteBody.fromJson(Map<String, dynamic> json) =>
      _$FavoriteBodyFromJson(json);
}
