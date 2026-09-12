// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_page_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MyPageState {
  bool get isLoading => throw _privateConstructorUsedError;
  String? get sakeName => throw _privateConstructorUsedError;
  String? get hint => throw _privateConstructorUsedError;
  File? get sakeImage => throw _privateConstructorUsedError;
  String? get geminiResponse => throw _privateConstructorUsedError;
  String? get preferences => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MyPageStateCopyWith<MyPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyPageStateCopyWith<$Res> {
  factory $MyPageStateCopyWith(
          MyPageState value, $Res Function(MyPageState) then) =
      _$MyPageStateCopyWithImpl<$Res, MyPageState>;
  @useResult
  $Res call(
      {bool isLoading,
      String? sakeName,
      String? hint,
      File? sakeImage,
      String? geminiResponse,
      String? preferences});
}

/// @nodoc
class _$MyPageStateCopyWithImpl<$Res, $Val extends MyPageState>
    implements $MyPageStateCopyWith<$Res> {
  _$MyPageStateCopyWithImpl(this._value, this._then);

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
    Object? preferences = freezed,
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
      preferences: freezed == preferences
          ? _value.preferences
          : preferences // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MyPageStateImplCopyWith<$Res>
    implements $MyPageStateCopyWith<$Res> {
  factory _$$MyPageStateImplCopyWith(
          _$MyPageStateImpl value, $Res Function(_$MyPageStateImpl) then) =
      __$$MyPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      String? sakeName,
      String? hint,
      File? sakeImage,
      String? geminiResponse,
      String? preferences});
}

/// @nodoc
class __$$MyPageStateImplCopyWithImpl<$Res>
    extends _$MyPageStateCopyWithImpl<$Res, _$MyPageStateImpl>
    implements _$$MyPageStateImplCopyWith<$Res> {
  __$$MyPageStateImplCopyWithImpl(
      _$MyPageStateImpl _value, $Res Function(_$MyPageStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? sakeName = freezed,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? geminiResponse = freezed,
    Object? preferences = freezed,
  }) {
    return _then(_$MyPageStateImpl(
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
      preferences: freezed == preferences
          ? _value.preferences
          : preferences // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MyPageStateImpl implements _MyPageState {
  const _$MyPageStateImpl(
      {this.isLoading = false,
      this.sakeName,
      this.hint,
      this.sakeImage,
      this.geminiResponse,
      this.preferences});

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
  final String? preferences;

  @override
  String toString() {
    return 'MyPageState(isLoading: $isLoading, sakeName: $sakeName, hint: $hint, sakeImage: $sakeImage, geminiResponse: $geminiResponse, preferences: $preferences)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyPageStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.sakeName, sakeName) ||
                other.sakeName == sakeName) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.sakeImage, sakeImage) ||
                other.sakeImage == sakeImage) &&
            (identical(other.geminiResponse, geminiResponse) ||
                other.geminiResponse == geminiResponse) &&
            (identical(other.preferences, preferences) ||
                other.preferences == preferences));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading, sakeName, hint,
      sakeImage, geminiResponse, preferences);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MyPageStateImplCopyWith<_$MyPageStateImpl> get copyWith =>
      __$$MyPageStateImplCopyWithImpl<_$MyPageStateImpl>(this, _$identity);
}

abstract class _MyPageState implements MyPageState {
  const factory _MyPageState(
      {final bool isLoading,
      final String? sakeName,
      final String? hint,
      final File? sakeImage,
      final String? geminiResponse,
      final String? preferences}) = _$MyPageStateImpl;

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
  String? get preferences;
  @override
  @JsonKey(ignore: true)
  _$$MyPageStateImplCopyWith<_$MyPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
