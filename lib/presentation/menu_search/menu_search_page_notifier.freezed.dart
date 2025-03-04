// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_search_page_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MenuSearchPageState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isExtractingInfo => throw _privateConstructorUsedError;
  bool get isGettingDetails => throw _privateConstructorUsedError;
  bool get isAdLoading => throw _privateConstructorUsedError;
  bool get isAnalyzingInBackground => throw _privateConstructorUsedError;
  String? get sakeName => throw _privateConstructorUsedError;
  String? get hint => throw _privateConstructorUsedError;
  File? get sakeImage => throw _privateConstructorUsedError;
  String? get geminiResponse => throw _privateConstructorUsedError;
  List<Sake> get extractedSakes => throw _privateConstructorUsedError;
  SakeMenuRecognitionResponse? get sakeMenuRecognitionResponse =>
      throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  List<Sake>? get sakes => throw _privateConstructorUsedError;
  Map<String, bool> get sakeLoadingStatus =>
      throw _privateConstructorUsedError; // 元の名前と取得した詳細情報の名前のマッピング
  Map<String, String> get nameMapping =>
      throw _privateConstructorUsedError; // ユーザーの好み
  String? get preferences =>
      throw _privateConstructorUsedError; // 日本酒リストが表示された後にスクロールしたかどうか
  bool get hasScrolledToResults =>
      throw _privateConstructorUsedError; // メニュー解析履歴
  List<MenuAnalysisHistoryItem> get menuAnalysisHistory =>
      throw _privateConstructorUsedError; // 現在選択されている履歴項目のID
  String? get selectedHistoryItemId =>
      throw _privateConstructorUsedError; // 店舗名の編集中かどうか
  bool get isEditingStoreName => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MenuSearchPageStateCopyWith<MenuSearchPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuSearchPageStateCopyWith<$Res> {
  factory $MenuSearchPageStateCopyWith(
          MenuSearchPageState value, $Res Function(MenuSearchPageState) then) =
      _$MenuSearchPageStateCopyWithImpl<$Res, MenuSearchPageState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isExtractingInfo,
      bool isGettingDetails,
      bool isAdLoading,
      bool isAnalyzingInBackground,
      String? sakeName,
      String? hint,
      File? sakeImage,
      String? geminiResponse,
      List<Sake> extractedSakes,
      SakeMenuRecognitionResponse? sakeMenuRecognitionResponse,
      String? errorMessage,
      List<Sake>? sakes,
      Map<String, bool> sakeLoadingStatus,
      Map<String, String> nameMapping,
      String? preferences,
      bool hasScrolledToResults,
      List<MenuAnalysisHistoryItem> menuAnalysisHistory,
      String? selectedHistoryItemId,
      bool isEditingStoreName});

  $SakeMenuRecognitionResponseCopyWith<$Res>? get sakeMenuRecognitionResponse;
}

/// @nodoc
class _$MenuSearchPageStateCopyWithImpl<$Res, $Val extends MenuSearchPageState>
    implements $MenuSearchPageStateCopyWith<$Res> {
  _$MenuSearchPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isExtractingInfo = null,
    Object? isGettingDetails = null,
    Object? isAdLoading = null,
    Object? isAnalyzingInBackground = null,
    Object? sakeName = freezed,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? geminiResponse = freezed,
    Object? extractedSakes = null,
    Object? sakeMenuRecognitionResponse = freezed,
    Object? errorMessage = freezed,
    Object? sakes = freezed,
    Object? sakeLoadingStatus = null,
    Object? nameMapping = null,
    Object? preferences = freezed,
    Object? hasScrolledToResults = null,
    Object? menuAnalysisHistory = null,
    Object? selectedHistoryItemId = freezed,
    Object? isEditingStoreName = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isExtractingInfo: null == isExtractingInfo
          ? _value.isExtractingInfo
          : isExtractingInfo // ignore: cast_nullable_to_non_nullable
              as bool,
      isGettingDetails: null == isGettingDetails
          ? _value.isGettingDetails
          : isGettingDetails // ignore: cast_nullable_to_non_nullable
              as bool,
      isAdLoading: null == isAdLoading
          ? _value.isAdLoading
          : isAdLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnalyzingInBackground: null == isAnalyzingInBackground
          ? _value.isAnalyzingInBackground
          : isAnalyzingInBackground // ignore: cast_nullable_to_non_nullable
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
      extractedSakes: null == extractedSakes
          ? _value.extractedSakes
          : extractedSakes // ignore: cast_nullable_to_non_nullable
              as List<Sake>,
      sakeMenuRecognitionResponse: freezed == sakeMenuRecognitionResponse
          ? _value.sakeMenuRecognitionResponse
          : sakeMenuRecognitionResponse // ignore: cast_nullable_to_non_nullable
              as SakeMenuRecognitionResponse?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      sakes: freezed == sakes
          ? _value.sakes
          : sakes // ignore: cast_nullable_to_non_nullable
              as List<Sake>?,
      sakeLoadingStatus: null == sakeLoadingStatus
          ? _value.sakeLoadingStatus
          : sakeLoadingStatus // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      nameMapping: null == nameMapping
          ? _value.nameMapping
          : nameMapping // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      preferences: freezed == preferences
          ? _value.preferences
          : preferences // ignore: cast_nullable_to_non_nullable
              as String?,
      hasScrolledToResults: null == hasScrolledToResults
          ? _value.hasScrolledToResults
          : hasScrolledToResults // ignore: cast_nullable_to_non_nullable
              as bool,
      menuAnalysisHistory: null == menuAnalysisHistory
          ? _value.menuAnalysisHistory
          : menuAnalysisHistory // ignore: cast_nullable_to_non_nullable
              as List<MenuAnalysisHistoryItem>,
      selectedHistoryItemId: freezed == selectedHistoryItemId
          ? _value.selectedHistoryItemId
          : selectedHistoryItemId // ignore: cast_nullable_to_non_nullable
              as String?,
      isEditingStoreName: null == isEditingStoreName
          ? _value.isEditingStoreName
          : isEditingStoreName // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SakeMenuRecognitionResponseCopyWith<$Res>? get sakeMenuRecognitionResponse {
    if (_value.sakeMenuRecognitionResponse == null) {
      return null;
    }

    return $SakeMenuRecognitionResponseCopyWith<$Res>(
        _value.sakeMenuRecognitionResponse!, (value) {
      return _then(_value.copyWith(sakeMenuRecognitionResponse: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MenuSearchPageStateImplCopyWith<$Res>
    implements $MenuSearchPageStateCopyWith<$Res> {
  factory _$$MenuSearchPageStateImplCopyWith(_$MenuSearchPageStateImpl value,
          $Res Function(_$MenuSearchPageStateImpl) then) =
      __$$MenuSearchPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isExtractingInfo,
      bool isGettingDetails,
      bool isAdLoading,
      bool isAnalyzingInBackground,
      String? sakeName,
      String? hint,
      File? sakeImage,
      String? geminiResponse,
      List<Sake> extractedSakes,
      SakeMenuRecognitionResponse? sakeMenuRecognitionResponse,
      String? errorMessage,
      List<Sake>? sakes,
      Map<String, bool> sakeLoadingStatus,
      Map<String, String> nameMapping,
      String? preferences,
      bool hasScrolledToResults,
      List<MenuAnalysisHistoryItem> menuAnalysisHistory,
      String? selectedHistoryItemId,
      bool isEditingStoreName});

  @override
  $SakeMenuRecognitionResponseCopyWith<$Res>? get sakeMenuRecognitionResponse;
}

/// @nodoc
class __$$MenuSearchPageStateImplCopyWithImpl<$Res>
    extends _$MenuSearchPageStateCopyWithImpl<$Res, _$MenuSearchPageStateImpl>
    implements _$$MenuSearchPageStateImplCopyWith<$Res> {
  __$$MenuSearchPageStateImplCopyWithImpl(_$MenuSearchPageStateImpl _value,
      $Res Function(_$MenuSearchPageStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isExtractingInfo = null,
    Object? isGettingDetails = null,
    Object? isAdLoading = null,
    Object? isAnalyzingInBackground = null,
    Object? sakeName = freezed,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? geminiResponse = freezed,
    Object? extractedSakes = null,
    Object? sakeMenuRecognitionResponse = freezed,
    Object? errorMessage = freezed,
    Object? sakes = freezed,
    Object? sakeLoadingStatus = null,
    Object? nameMapping = null,
    Object? preferences = freezed,
    Object? hasScrolledToResults = null,
    Object? menuAnalysisHistory = null,
    Object? selectedHistoryItemId = freezed,
    Object? isEditingStoreName = null,
  }) {
    return _then(_$MenuSearchPageStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isExtractingInfo: null == isExtractingInfo
          ? _value.isExtractingInfo
          : isExtractingInfo // ignore: cast_nullable_to_non_nullable
              as bool,
      isGettingDetails: null == isGettingDetails
          ? _value.isGettingDetails
          : isGettingDetails // ignore: cast_nullable_to_non_nullable
              as bool,
      isAdLoading: null == isAdLoading
          ? _value.isAdLoading
          : isAdLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnalyzingInBackground: null == isAnalyzingInBackground
          ? _value.isAnalyzingInBackground
          : isAnalyzingInBackground // ignore: cast_nullable_to_non_nullable
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
      extractedSakes: null == extractedSakes
          ? _value._extractedSakes
          : extractedSakes // ignore: cast_nullable_to_non_nullable
              as List<Sake>,
      sakeMenuRecognitionResponse: freezed == sakeMenuRecognitionResponse
          ? _value.sakeMenuRecognitionResponse
          : sakeMenuRecognitionResponse // ignore: cast_nullable_to_non_nullable
              as SakeMenuRecognitionResponse?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      sakes: freezed == sakes
          ? _value._sakes
          : sakes // ignore: cast_nullable_to_non_nullable
              as List<Sake>?,
      sakeLoadingStatus: null == sakeLoadingStatus
          ? _value._sakeLoadingStatus
          : sakeLoadingStatus // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      nameMapping: null == nameMapping
          ? _value._nameMapping
          : nameMapping // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      preferences: freezed == preferences
          ? _value.preferences
          : preferences // ignore: cast_nullable_to_non_nullable
              as String?,
      hasScrolledToResults: null == hasScrolledToResults
          ? _value.hasScrolledToResults
          : hasScrolledToResults // ignore: cast_nullable_to_non_nullable
              as bool,
      menuAnalysisHistory: null == menuAnalysisHistory
          ? _value._menuAnalysisHistory
          : menuAnalysisHistory // ignore: cast_nullable_to_non_nullable
              as List<MenuAnalysisHistoryItem>,
      selectedHistoryItemId: freezed == selectedHistoryItemId
          ? _value.selectedHistoryItemId
          : selectedHistoryItemId // ignore: cast_nullable_to_non_nullable
              as String?,
      isEditingStoreName: null == isEditingStoreName
          ? _value.isEditingStoreName
          : isEditingStoreName // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$MenuSearchPageStateImpl implements _MenuSearchPageState {
  const _$MenuSearchPageStateImpl(
      {this.isLoading = false,
      this.isExtractingInfo = false,
      this.isGettingDetails = false,
      this.isAdLoading = false,
      this.isAnalyzingInBackground = false,
      this.sakeName,
      this.hint,
      this.sakeImage,
      this.geminiResponse,
      final List<Sake> extractedSakes = const [],
      this.sakeMenuRecognitionResponse,
      this.errorMessage,
      final List<Sake>? sakes,
      final Map<String, bool> sakeLoadingStatus = const {},
      final Map<String, String> nameMapping = const {},
      this.preferences,
      this.hasScrolledToResults = false,
      final List<MenuAnalysisHistoryItem> menuAnalysisHistory = const [],
      this.selectedHistoryItemId,
      this.isEditingStoreName = false})
      : _extractedSakes = extractedSakes,
        _sakes = sakes,
        _sakeLoadingStatus = sakeLoadingStatus,
        _nameMapping = nameMapping,
        _menuAnalysisHistory = menuAnalysisHistory;

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isExtractingInfo;
  @override
  @JsonKey()
  final bool isGettingDetails;
  @override
  @JsonKey()
  final bool isAdLoading;
  @override
  @JsonKey()
  final bool isAnalyzingInBackground;
  @override
  final String? sakeName;
  @override
  final String? hint;
  @override
  final File? sakeImage;
  @override
  final String? geminiResponse;
  final List<Sake> _extractedSakes;
  @override
  @JsonKey()
  List<Sake> get extractedSakes {
    if (_extractedSakes is EqualUnmodifiableListView) return _extractedSakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_extractedSakes);
  }

  @override
  final SakeMenuRecognitionResponse? sakeMenuRecognitionResponse;
  @override
  final String? errorMessage;
  final List<Sake>? _sakes;
  @override
  List<Sake>? get sakes {
    final value = _sakes;
    if (value == null) return null;
    if (_sakes is EqualUnmodifiableListView) return _sakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, bool> _sakeLoadingStatus;
  @override
  @JsonKey()
  Map<String, bool> get sakeLoadingStatus {
    if (_sakeLoadingStatus is EqualUnmodifiableMapView)
      return _sakeLoadingStatus;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_sakeLoadingStatus);
  }

// 元の名前と取得した詳細情報の名前のマッピング
  final Map<String, String> _nameMapping;
// 元の名前と取得した詳細情報の名前のマッピング
  @override
  @JsonKey()
  Map<String, String> get nameMapping {
    if (_nameMapping is EqualUnmodifiableMapView) return _nameMapping;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_nameMapping);
  }

// ユーザーの好み
  @override
  final String? preferences;
// 日本酒リストが表示された後にスクロールしたかどうか
  @override
  @JsonKey()
  final bool hasScrolledToResults;
// メニュー解析履歴
  final List<MenuAnalysisHistoryItem> _menuAnalysisHistory;
// メニュー解析履歴
  @override
  @JsonKey()
  List<MenuAnalysisHistoryItem> get menuAnalysisHistory {
    if (_menuAnalysisHistory is EqualUnmodifiableListView)
      return _menuAnalysisHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_menuAnalysisHistory);
  }

// 現在選択されている履歴項目のID
  @override
  final String? selectedHistoryItemId;
// 店舗名の編集中かどうか
  @override
  @JsonKey()
  final bool isEditingStoreName;

  @override
  String toString() {
    return 'MenuSearchPageState(isLoading: $isLoading, isExtractingInfo: $isExtractingInfo, isGettingDetails: $isGettingDetails, isAdLoading: $isAdLoading, isAnalyzingInBackground: $isAnalyzingInBackground, sakeName: $sakeName, hint: $hint, sakeImage: $sakeImage, geminiResponse: $geminiResponse, extractedSakes: $extractedSakes, sakeMenuRecognitionResponse: $sakeMenuRecognitionResponse, errorMessage: $errorMessage, sakes: $sakes, sakeLoadingStatus: $sakeLoadingStatus, nameMapping: $nameMapping, preferences: $preferences, hasScrolledToResults: $hasScrolledToResults, menuAnalysisHistory: $menuAnalysisHistory, selectedHistoryItemId: $selectedHistoryItemId, isEditingStoreName: $isEditingStoreName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuSearchPageStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isExtractingInfo, isExtractingInfo) ||
                other.isExtractingInfo == isExtractingInfo) &&
            (identical(other.isGettingDetails, isGettingDetails) ||
                other.isGettingDetails == isGettingDetails) &&
            (identical(other.isAdLoading, isAdLoading) ||
                other.isAdLoading == isAdLoading) &&
            (identical(
                    other.isAnalyzingInBackground, isAnalyzingInBackground) ||
                other.isAnalyzingInBackground == isAnalyzingInBackground) &&
            (identical(other.sakeName, sakeName) ||
                other.sakeName == sakeName) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.sakeImage, sakeImage) ||
                other.sakeImage == sakeImage) &&
            (identical(other.geminiResponse, geminiResponse) ||
                other.geminiResponse == geminiResponse) &&
            const DeepCollectionEquality()
                .equals(other._extractedSakes, _extractedSakes) &&
            (identical(other.sakeMenuRecognitionResponse,
                    sakeMenuRecognitionResponse) ||
                other.sakeMenuRecognitionResponse ==
                    sakeMenuRecognitionResponse) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(other._sakes, _sakes) &&
            const DeepCollectionEquality()
                .equals(other._sakeLoadingStatus, _sakeLoadingStatus) &&
            const DeepCollectionEquality()
                .equals(other._nameMapping, _nameMapping) &&
            (identical(other.preferences, preferences) ||
                other.preferences == preferences) &&
            (identical(other.hasScrolledToResults, hasScrolledToResults) ||
                other.hasScrolledToResults == hasScrolledToResults) &&
            const DeepCollectionEquality()
                .equals(other._menuAnalysisHistory, _menuAnalysisHistory) &&
            (identical(other.selectedHistoryItemId, selectedHistoryItemId) ||
                other.selectedHistoryItemId == selectedHistoryItemId) &&
            (identical(other.isEditingStoreName, isEditingStoreName) ||
                other.isEditingStoreName == isEditingStoreName));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        isLoading,
        isExtractingInfo,
        isGettingDetails,
        isAdLoading,
        isAnalyzingInBackground,
        sakeName,
        hint,
        sakeImage,
        geminiResponse,
        const DeepCollectionEquality().hash(_extractedSakes),
        sakeMenuRecognitionResponse,
        errorMessage,
        const DeepCollectionEquality().hash(_sakes),
        const DeepCollectionEquality().hash(_sakeLoadingStatus),
        const DeepCollectionEquality().hash(_nameMapping),
        preferences,
        hasScrolledToResults,
        const DeepCollectionEquality().hash(_menuAnalysisHistory),
        selectedHistoryItemId,
        isEditingStoreName
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuSearchPageStateImplCopyWith<_$MenuSearchPageStateImpl> get copyWith =>
      __$$MenuSearchPageStateImplCopyWithImpl<_$MenuSearchPageStateImpl>(
          this, _$identity);
}

abstract class _MenuSearchPageState implements MenuSearchPageState {
  const factory _MenuSearchPageState(
      {final bool isLoading,
      final bool isExtractingInfo,
      final bool isGettingDetails,
      final bool isAdLoading,
      final bool isAnalyzingInBackground,
      final String? sakeName,
      final String? hint,
      final File? sakeImage,
      final String? geminiResponse,
      final List<Sake> extractedSakes,
      final SakeMenuRecognitionResponse? sakeMenuRecognitionResponse,
      final String? errorMessage,
      final List<Sake>? sakes,
      final Map<String, bool> sakeLoadingStatus,
      final Map<String, String> nameMapping,
      final String? preferences,
      final bool hasScrolledToResults,
      final List<MenuAnalysisHistoryItem> menuAnalysisHistory,
      final String? selectedHistoryItemId,
      final bool isEditingStoreName}) = _$MenuSearchPageStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isExtractingInfo;
  @override
  bool get isGettingDetails;
  @override
  bool get isAdLoading;
  @override
  bool get isAnalyzingInBackground;
  @override
  String? get sakeName;
  @override
  String? get hint;
  @override
  File? get sakeImage;
  @override
  String? get geminiResponse;
  @override
  List<Sake> get extractedSakes;
  @override
  SakeMenuRecognitionResponse? get sakeMenuRecognitionResponse;
  @override
  String? get errorMessage;
  @override
  List<Sake>? get sakes;
  @override
  Map<String, bool> get sakeLoadingStatus;
  @override // 元の名前と取得した詳細情報の名前のマッピング
  Map<String, String> get nameMapping;
  @override // ユーザーの好み
  String? get preferences;
  @override // 日本酒リストが表示された後にスクロールしたかどうか
  bool get hasScrolledToResults;
  @override // メニュー解析履歴
  List<MenuAnalysisHistoryItem> get menuAnalysisHistory;
  @override // 現在選択されている履歴項目のID
  String? get selectedHistoryItemId;
  @override // 店舗名の編集中かどうか
  bool get isEditingStoreName;
  @override
  @JsonKey(ignore: true)
  _$$MenuSearchPageStateImplCopyWith<_$MenuSearchPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
