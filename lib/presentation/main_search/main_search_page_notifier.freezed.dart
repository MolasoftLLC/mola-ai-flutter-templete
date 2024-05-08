// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'main_search_page_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MainSearchPageState {
  bool get isLoading => throw _privateConstructorUsedError;
  String? get sakeName => throw _privateConstructorUsedError;
  String? get hint => throw _privateConstructorUsedError;
  File? get sakeImage => throw _privateConstructorUsedError;
  String? get geminiResponse => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MainSearchPageStateCopyWith<MainSearchPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MainSearchPageStateCopyWith<$Res> {
  factory $MainSearchPageStateCopyWith(
          MainSearchPageState value, $Res Function(MainSearchPageState) then) =
      _$MainSearchPageStateCopyWithImpl<$Res, MainSearchPageState>;
  @useResult
  $Res call(
      {bool isLoading,
      String? sakeName,
      String? hint,
      File? sakeImage,
      String? geminiResponse});
}

/// @nodoc
class _$MainSearchPageStateCopyWithImpl<$Res, $Val extends MainSearchPageState>
    implements $MainSearchPageStateCopyWith<$Res> {
  _$MainSearchPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? sakeName = freezed,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? geminiResponse = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      sakeName: freezed == sakeName
          ? _value.sakeName
          : sakeName // ignore: cast_nullable_to_non_nullable
              as String?,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeImage: freezed == sakeImage
          ? _value.sakeImage
          : sakeImage // ignore: cast_nullable_to_non_nullable
              as File?,
      geminiResponse: freezed == geminiResponse
          ? _value.geminiResponse
          : geminiResponse // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MainSearchPageStateImplCopyWith<$Res>
    implements $MainSearchPageStateCopyWith<$Res> {
  factory _$$MainSearchPageStateImplCopyWith(_$MainSearchPageStateImpl value,
          $Res Function(_$MainSearchPageStateImpl) then) =
      __$$MainSearchPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      String? sakeName,
      String? hint,
      File? sakeImage,
      String? geminiResponse});
}

/// @nodoc
class __$$MainSearchPageStateImplCopyWithImpl<$Res>
    extends _$MainSearchPageStateCopyWithImpl<$Res, _$MainSearchPageStateImpl>
    implements _$$MainSearchPageStateImplCopyWith<$Res> {
  __$$MainSearchPageStateImplCopyWithImpl(_$MainSearchPageStateImpl _value,
      $Res Function(_$MainSearchPageStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? sakeName = freezed,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? geminiResponse = freezed,
  }) {
    return _then(_$MainSearchPageStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      sakeName: freezed == sakeName
          ? _value.sakeName
          : sakeName // ignore: cast_nullable_to_non_nullable
              as String?,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeImage: freezed == sakeImage
          ? _value.sakeImage
          : sakeImage // ignore: cast_nullable_to_non_nullable
              as File?,
      geminiResponse: freezed == geminiResponse
          ? _value.geminiResponse
          : geminiResponse // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MainSearchPageStateImpl implements _MainSearchPageState {
  const _$MainSearchPageStateImpl(
      {this.isLoading = false,
      this.sakeName,
      this.hint,
      this.sakeImage,
      this.geminiResponse});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? sakeName;
  @override
  final String? hint;
  @override
  final File? sakeImage;
  @override
  final String? geminiResponse;

  @override
  String toString() {
    return 'MainSearchPageState(isLoading: $isLoading, sakeName: $sakeName, hint: $hint, sakeImage: $sakeImage, geminiResponse: $geminiResponse)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MainSearchPageStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.sakeName, sakeName) ||
                other.sakeName == sakeName) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.sakeImage, sakeImage) ||
                other.sakeImage == sakeImage) &&
            (identical(other.geminiResponse, geminiResponse) ||
                other.geminiResponse == geminiResponse));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isLoading, sakeName, hint, sakeImage, geminiResponse);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MainSearchPageStateImplCopyWith<_$MainSearchPageStateImpl> get copyWith =>
      __$$MainSearchPageStateImplCopyWithImpl<_$MainSearchPageStateImpl>(
          this, _$identity);
}

abstract class _MainSearchPageState implements MainSearchPageState {
  const factory _MainSearchPageState(
      {final bool isLoading,
      final String? sakeName,
      final String? hint,
      final File? sakeImage,
      final String? geminiResponse}) = _$MainSearchPageStateImpl;

  @override
  bool get isLoading;
  @override
  String? get sakeName;
  @override
  String? get hint;
  @override
  File? get sakeImage;
  @override
  String? get geminiResponse;
  @override
  @JsonKey(ignore: true)
  _$$MainSearchPageStateImplCopyWith<_$MainSearchPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
