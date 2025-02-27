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
  String? get sakeType => throw _privateConstructorUsedError;
  Sake? get sakeInfo => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

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
      String? sakeType,
      Sake? sakeInfo,
      String? errorMessage});

  $SakeCopyWith<$Res>? get sakeInfo;
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
    Object? sakeType = freezed,
    Object? sakeInfo = freezed,
    Object? errorMessage = freezed,
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
      sakeType: freezed == sakeType
          ? _value.sakeType
          : sakeType // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeInfo: freezed == sakeInfo
          ? _value.sakeInfo
          : sakeInfo // ignore: cast_nullable_to_non_nullable
              as Sake?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SakeCopyWith<$Res>? get sakeInfo {
    if (_value.sakeInfo == null) {
      return null;
    }

    return $SakeCopyWith<$Res>(_value.sakeInfo!, (value) {
      return _then(_value.copyWith(sakeInfo: value) as $Val);
    });
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
      String? sakeType,
      Sake? sakeInfo,
      String? errorMessage});

  @override
  $SakeCopyWith<$Res>? get sakeInfo;
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
    Object? sakeType = freezed,
    Object? sakeInfo = freezed,
    Object? errorMessage = freezed,
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
      sakeType: freezed == sakeType
          ? _value.sakeType
          : sakeType // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeInfo: freezed == sakeInfo
          ? _value.sakeInfo
          : sakeInfo // ignore: cast_nullable_to_non_nullable
              as Sake?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MainSearchPageStateImpl implements _MainSearchPageState {
  const _$MainSearchPageStateImpl(
      {this.isLoading = false,
      this.sakeName,
      this.sakeType,
      this.sakeInfo,
      this.errorMessage});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? sakeName;
  @override
  final String? sakeType;
  @override
  final Sake? sakeInfo;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'MainSearchPageState(isLoading: $isLoading, sakeName: $sakeName, sakeType: $sakeType, sakeInfo: $sakeInfo, errorMessage: $errorMessage)';
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
            (identical(other.sakeType, sakeType) ||
                other.sakeType == sakeType) &&
            (identical(other.sakeInfo, sakeInfo) ||
                other.sakeInfo == sakeInfo) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isLoading, sakeName, sakeType, sakeInfo, errorMessage);

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
      final String? sakeType,
      final Sake? sakeInfo,
      final String? errorMessage}) = _$MainSearchPageStateImpl;

  @override
  bool get isLoading;
  @override
  String? get sakeName;
  @override
  String? get sakeType;
  @override
  Sake? get sakeInfo;
  @override
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$MainSearchPageStateImplCopyWith<_$MainSearchPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
