// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FavoriteState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<String> get myFavoriteList => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FavoriteStateCopyWith<FavoriteState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FavoriteStateCopyWith<$Res> {
  factory $FavoriteStateCopyWith(
          FavoriteState value, $Res Function(FavoriteState) then) =
      _$FavoriteStateCopyWithImpl<$Res, FavoriteState>;
  @useResult
  $Res call({bool isLoading, List<String> myFavoriteList});
}

/// @nodoc
class _$FavoriteStateCopyWithImpl<$Res, $Val extends FavoriteState>
    implements $FavoriteStateCopyWith<$Res> {
  _$FavoriteStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? myFavoriteList = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      myFavoriteList: null == myFavoriteList
          ? _value.myFavoriteList
          : myFavoriteList // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FavoriteStateImplCopyWith<$Res>
    implements $FavoriteStateCopyWith<$Res> {
  factory _$$FavoriteStateImplCopyWith(
          _$FavoriteStateImpl value, $Res Function(_$FavoriteStateImpl) then) =
      __$$FavoriteStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, List<String> myFavoriteList});
}

/// @nodoc
class __$$FavoriteStateImplCopyWithImpl<$Res>
    extends _$FavoriteStateCopyWithImpl<$Res, _$FavoriteStateImpl>
    implements _$$FavoriteStateImplCopyWith<$Res> {
  __$$FavoriteStateImplCopyWithImpl(
      _$FavoriteStateImpl _value, $Res Function(_$FavoriteStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? myFavoriteList = null,
  }) {
    return _then(_$FavoriteStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      myFavoriteList: null == myFavoriteList
          ? _value._myFavoriteList
          : myFavoriteList // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$FavoriteStateImpl implements _FavoriteState {
  const _$FavoriteStateImpl(
      {this.isLoading = false, final List<String> myFavoriteList = const []})
      : _myFavoriteList = myFavoriteList;

  @override
  @JsonKey()
  final bool isLoading;
  final List<String> _myFavoriteList;
  @override
  @JsonKey()
  List<String> get myFavoriteList {
    if (_myFavoriteList is EqualUnmodifiableListView) return _myFavoriteList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_myFavoriteList);
  }

  @override
  String toString() {
    return 'FavoriteState(isLoading: $isLoading, myFavoriteList: $myFavoriteList)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FavoriteStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality()
                .equals(other._myFavoriteList, _myFavoriteList));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading,
      const DeepCollectionEquality().hash(_myFavoriteList));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FavoriteStateImplCopyWith<_$FavoriteStateImpl> get copyWith =>
      __$$FavoriteStateImplCopyWithImpl<_$FavoriteStateImpl>(this, _$identity);
}

abstract class _FavoriteState implements FavoriteState {
  const factory _FavoriteState(
      {final bool isLoading,
      final List<String> myFavoriteList}) = _$FavoriteStateImpl;

  @override
  bool get isLoading;
  @override
  List<String> get myFavoriteList;
  @override
  @JsonKey(ignore: true)
  _$$FavoriteStateImplCopyWith<_$FavoriteStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
