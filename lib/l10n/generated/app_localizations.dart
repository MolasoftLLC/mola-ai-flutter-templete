import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'SAKEPEDIA'**
  String get appTitle;

  /// No description provided for @navigationSearch.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get navigationSearch;

  /// No description provided for @navigationMap.
  ///
  /// In ja, this message translates to:
  /// **'マップ'**
  String get navigationMap;

  /// No description provided for @newFeatureBadge.
  ///
  /// In ja, this message translates to:
  /// **'NEW&便利'**
  String get newFeatureBadge;

  /// No description provided for @mapSearchShortcut.
  ///
  /// In ja, this message translates to:
  /// **'地図検索'**
  String get mapSearchShortcut;

  /// No description provided for @mapSearchShortcutDescription.
  ///
  /// In ja, this message translates to:
  /// **'お店から日本酒を探す'**
  String get mapSearchShortcutDescription;

  /// No description provided for @fastSearchShortcut.
  ///
  /// In ja, this message translates to:
  /// **'高速検索'**
  String get fastSearchShortcut;

  /// No description provided for @fastSearchShortcutDescription.
  ///
  /// In ja, this message translates to:
  /// **'ラベルを撮ってすぐ検索'**
  String get fastSearchShortcutDescription;

  /// No description provided for @registeredVenueCount.
  ///
  /// In ja, this message translates to:
  /// **'登録店舗 {count}件'**
  String registeredVenueCount(int count);

  /// No description provided for @navigationMenuAnalysis.
  ///
  /// In ja, this message translates to:
  /// **'メニュー解析'**
  String get navigationMenuAnalysis;

  /// No description provided for @navigationRecommendation.
  ///
  /// In ja, this message translates to:
  /// **'おすすめ'**
  String get navigationRecommendation;

  /// No description provided for @navigationScan.
  ///
  /// In ja, this message translates to:
  /// **'スキャン'**
  String get navigationScan;

  /// No description provided for @navigationTimeline.
  ///
  /// In ja, this message translates to:
  /// **'タイムライン'**
  String get navigationTimeline;

  /// No description provided for @navigationMyPage.
  ///
  /// In ja, this message translates to:
  /// **'マイページ'**
  String get navigationMyPage;

  /// No description provided for @newHomeSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'いろいろな条件で検索'**
  String get newHomeSearchHint;

  /// No description provided for @newHomeRecentSakes.
  ///
  /// In ja, this message translates to:
  /// **'最近調べたお酒'**
  String get newHomeRecentSakes;

  /// No description provided for @newHomeTimeline.
  ///
  /// In ja, this message translates to:
  /// **'タイムライン'**
  String get newHomeTimeline;

  /// No description provided for @searchPageTitle.
  ///
  /// In ja, this message translates to:
  /// **'日本酒検索'**
  String get searchPageTitle;

  /// No description provided for @menuSearchPageTitle.
  ///
  /// In ja, this message translates to:
  /// **'メニュー検索'**
  String get menuSearchPageTitle;

  /// No description provided for @preferenceSearchPageTitle.
  ///
  /// In ja, this message translates to:
  /// **'好みで検索'**
  String get preferenceSearchPageTitle;

  /// No description provided for @helpGuide.
  ///
  /// In ja, this message translates to:
  /// **'使い方ガイド'**
  String get helpGuide;

  /// No description provided for @back.
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// No description provided for @next.
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get next;

  /// No description provided for @done.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get done;

  /// No description provided for @mainSearchHelpTitle.
  ///
  /// In ja, this message translates to:
  /// **'日本酒検索の使い方'**
  String get mainSearchHelpTitle;

  /// No description provided for @menuSearchHelpTitle.
  ///
  /// In ja, this message translates to:
  /// **'メニュー検索の使い方'**
  String get menuSearchHelpTitle;

  /// No description provided for @myPageHelpTitle.
  ///
  /// In ja, this message translates to:
  /// **'マイページの使い方'**
  String get myPageHelpTitle;

  /// No description provided for @helpBottleFlowTitle.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶検索の流れ'**
  String get helpBottleFlowTitle;

  /// No description provided for @helpBottleFlowDescription.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶検索タブではカメラボタンから写真を撮影・選択できます。AIがラベルを解析し、日本酒情報を自動で取得します。解析した日本酒は保存ボタンでマイページに追加できます。'**
  String get helpBottleFlowDescription;

  /// No description provided for @helpAfterAnalysisTitle.
  ///
  /// In ja, this message translates to:
  /// **'解析が終わったら'**
  String get helpAfterAnalysisTitle;

  /// No description provided for @helpAfterAnalysisDescription.
  ///
  /// In ja, this message translates to:
  /// **'銘柄名を入力して「解析だけ」を押すと蔵元や味わいなどの詳細が表示されます。お気に入りや保存を活用して、自分だけのリストを作りましょう。'**
  String get helpAfterAnalysisDescription;

  /// No description provided for @helpMenuCaptureTitle.
  ///
  /// In ja, this message translates to:
  /// **'メニューを撮影・アップロード'**
  String get helpMenuCaptureTitle;

  /// No description provided for @helpMenuCaptureDescription.
  ///
  /// In ja, this message translates to:
  /// **'メニュー検索タブでは飲食店のメニュー写真をアップロードすると、写っている日本酒を自動でリスト化します。解析が終わるまで画面はそのままお待ちください。'**
  String get helpMenuCaptureDescription;

  /// No description provided for @helpMenuResultTitle.
  ///
  /// In ja, this message translates to:
  /// **'解析結果をチェック'**
  String get helpMenuResultTitle;

  /// No description provided for @helpMenuResultDescription.
  ///
  /// In ja, this message translates to:
  /// **'解析で取得した日本酒をタップすると蔵元や味わい、おすすめ度が表示されます。ハートでお気に入り登録、しおりでマイページに保存して飲み比べメモに活用しましょう。'**
  String get helpMenuResultDescription;

  /// No description provided for @helpSavedListTitle.
  ///
  /// In ja, this message translates to:
  /// **'保存した日本酒を一覧で確認'**
  String get helpSavedListTitle;

  /// No description provided for @helpSavedListDescription.
  ///
  /// In ja, this message translates to:
  /// **'マイページには保存した日本酒やお気に入りがまとまります。タイルをタップすると詳細やメモ、写真を編集できます。'**
  String get helpSavedListDescription;

  /// No description provided for @helpPreferenceAnalysisTitle.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りから好みを解析'**
  String get helpPreferenceAnalysisTitle;

  /// No description provided for @helpPreferenceAnalysisDescription.
  ///
  /// In ja, this message translates to:
  /// **'「お気に入り」の日本酒を元にAIがあなたの好みを解析します。解析した傾向は自分で変更することもできます。'**
  String get helpPreferenceAnalysisDescription;

  /// No description provided for @termsTitle.
  ///
  /// In ja, this message translates to:
  /// **'SAKEPEDIA利用規約'**
  String get termsTitle;

  /// No description provided for @termsAiUsage.
  ///
  /// In ja, this message translates to:
  /// **'SAKEPEDIAはGoogle LLCおよびOpenAI社が提供するAIを利用した日本酒特化型のアプリです。以下の内容に抵触する場合サービスがご利用いただけなくなる場合があります。\n\n・不必要な回数のリクエストを送る\n・生成されたデータの商用利用\n・その他Google LLCやOpenAI社が定める規約の違反'**
  String get termsAiUsage;

  /// No description provided for @termsAiDisclaimer.
  ///
  /// In ja, this message translates to:
  /// **'また、利用するAIの状況によっては応答しない、誤情報、信憑性が疑わしい情報が回答されるなどが発生する可能性がありますが、ユーザーの不都合について開発陣は一切の責任を負いません。ご了承ください。'**
  String get termsAiDisclaimer;

  /// No description provided for @termsAccount.
  ///
  /// In ja, this message translates to:
  /// **'本サービスではメールアドレスとパスワードによるログインを採用しており、不正利用が疑われる場合には機能の制限またはご利用を停止させていただくことがあります。'**
  String get termsAccount;

  /// No description provided for @termsContentPolicy.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーは以下のような不適切な写真や情報を投稿できません。\n\n・人物が写っている写真\n・暴力、脅迫、差別、ハラスメントなどの表現\n・性的内容（アルコール関連を除く）\n・著作権その他の知的財産権を侵害する内容\n・その他、当社が不適切と判断する内容\n\n本アプリではAIによって酒瓶以外の写真は投稿できない仕組みを採用していますが、不適切な投稿が確認された場合は投稿の非表示や削除を行うことがあります。'**
  String get termsContentPolicy;

  /// No description provided for @termsServiceAvailability.
  ///
  /// In ja, this message translates to:
  /// **'運営上の都合により予告なくサービスを停止・終了する場合があり、その際はサーバーに保存された解析画像や各種データが消去されることがあります。重要なデータは必ずご自身でも保管してください。'**
  String get termsServiceAvailability;

  /// No description provided for @termsClosing.
  ///
  /// In ja, this message translates to:
  /// **'以上をご承諾の上、SAKEPEDIAを楽しく使っていただけたらと思います。'**
  String get termsClosing;

  /// No description provided for @sakeTrivia.
  ///
  /// In ja, this message translates to:
  /// **'SAKE豆知識'**
  String get sakeTrivia;

  /// No description provided for @triviaLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'豆知識の読み込みに失敗しました'**
  String get triviaLoadFailed;

  /// No description provided for @triviaQuestionFallback.
  ///
  /// In ja, this message translates to:
  /// **'この豆知識って何？'**
  String get triviaQuestionFallback;

  /// No description provided for @triviaTailOne.
  ///
  /// In ja, this message translates to:
  /// **'覚えておくと注文のときにちょっと通っぽく語れるんだ。'**
  String get triviaTailOne;

  /// No description provided for @triviaTailTwo.
  ///
  /// In ja, this message translates to:
  /// **'知っているとペアリングの幅がぐっと広がるんだよね。'**
  String get triviaTailTwo;

  /// No description provided for @triviaTailThree.
  ///
  /// In ja, this message translates to:
  /// **'友だちに披露すると話のタネとして盛り上がるよ。'**
  String get triviaTailThree;

  /// No description provided for @triviaTailFour.
  ///
  /// In ja, this message translates to:
  /// **'蔵見学や試飲会で自信を持って語れる小ネタなんだ。'**
  String get triviaTailFour;

  /// No description provided for @triviaTailFive.
  ///
  /// In ja, this message translates to:
  /// **'頭の片隅に入れておくと日本酒選びがもっと楽しくなるんだ。'**
  String get triviaTailFive;

  /// No description provided for @everyoneSake.
  ///
  /// In ja, this message translates to:
  /// **'みんなの日本酒'**
  String get everyoneSake;

  /// No description provided for @publicTimelineEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだタイムラインには保存酒がありません。\nほかのユーザーが保存するとここに表示されます。'**
  String get publicTimelineEmpty;

  /// No description provided for @myPosts.
  ///
  /// In ja, this message translates to:
  /// **'自分の投稿'**
  String get myPosts;

  /// No description provided for @myPostsEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだタイムラインに公開した投稿がありません。\nお気に入りのお酒をシェアしてみましょう。'**
  String get myPostsEmpty;

  /// No description provided for @understood.
  ///
  /// In ja, this message translates to:
  /// **'了解'**
  String get understood;

  /// No description provided for @envyTutorialTitle.
  ///
  /// In ja, this message translates to:
  /// **'「うらやま」を送ってみよう'**
  String get envyTutorialTitle;

  /// No description provided for @envyTutorialDescription.
  ///
  /// In ja, this message translates to:
  /// **'気になった羨ましい日本酒に気軽Goodを送ろう！\n匿名だから気にせずどんどん押してね。'**
  String get envyTutorialDescription;

  /// No description provided for @timelineLoginTitle.
  ///
  /// In ja, this message translates to:
  /// **'ログインでさらに楽しもう'**
  String get timelineLoginTitle;

  /// No description provided for @timelineLoginMessage.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインから保存・お気に入り・うらやま・報告するにはログインが必要です。'**
  String get timelineLoginMessage;

  /// No description provided for @rankingLoginMessage.
  ///
  /// In ja, this message translates to:
  /// **'ランキングからうらやまを送るにはログインが必要です。'**
  String get rankingLoginMessage;

  /// No description provided for @dataFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'データの取得に失敗しました。通信環境をご確認ください。'**
  String get dataFetchFailed;

  /// No description provided for @reload.
  ///
  /// In ja, this message translates to:
  /// **'再読み込み'**
  String get reload;

  /// No description provided for @envySent.
  ///
  /// In ja, this message translates to:
  /// **'うらやまを送信しました！'**
  String get envySent;

  /// No description provided for @envySendFailed.
  ///
  /// In ja, this message translates to:
  /// **'うらやまの送信に失敗しました。通信環境をご確認ください。'**
  String get envySendFailed;

  /// No description provided for @envyAlready.
  ///
  /// In ja, this message translates to:
  /// **'すでにうらやま済みです！'**
  String get envyAlready;

  /// No description provided for @reportAccepted.
  ///
  /// In ja, this message translates to:
  /// **'ありがとうございました。報告を受け付けました。'**
  String get reportAccepted;

  /// No description provided for @reportAlready.
  ///
  /// In ja, this message translates to:
  /// **'この投稿は既に報告済みです。'**
  String get reportAlready;

  /// No description provided for @reportFailed.
  ///
  /// In ja, this message translates to:
  /// **'報告に失敗しました。通信環境をご確認ください。'**
  String get reportFailed;

  /// No description provided for @refresh.
  ///
  /// In ja, this message translates to:
  /// **'更新'**
  String get refresh;

  /// No description provided for @envyRankingTitle.
  ///
  /// In ja, this message translates to:
  /// **'羨ましい日本酒ランキング'**
  String get envyRankingTitle;

  /// No description provided for @envyRankingSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'うらやまが多い投稿ベスト20をチェック'**
  String get envyRankingSubtitle;

  /// No description provided for @tasteLabel.
  ///
  /// In ja, this message translates to:
  /// **'味わい: {taste}'**
  String tasteLabel(String taste);

  /// No description provided for @readMore.
  ///
  /// In ja, this message translates to:
  /// **'続きを読む'**
  String get readMore;

  /// No description provided for @anonymousUser.
  ///
  /// In ja, this message translates to:
  /// **'名無しユーザー'**
  String get anonymousUser;

  /// No description provided for @reportPostTitle.
  ///
  /// In ja, this message translates to:
  /// **'投稿を報告しますか？'**
  String get reportPostTitle;

  /// No description provided for @reportPostDescription.
  ///
  /// In ja, this message translates to:
  /// **'問題のある投稿として運営に報告します。よろしいですか？'**
  String get reportPostDescription;

  /// No description provided for @no.
  ///
  /// In ja, this message translates to:
  /// **'いいえ'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In ja, this message translates to:
  /// **'はい'**
  String get yes;

  /// No description provided for @rankingEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだランキングを表示できる投稿がありません。'**
  String get rankingEmpty;

  /// No description provided for @rankingFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'ランキングを取得できませんでした。時間をおいて再度お試しください。'**
  String get rankingFetchFailed;

  /// No description provided for @ownPostsLoginRequired.
  ///
  /// In ja, this message translates to:
  /// **'自分の投稿を表示するにはログインしてください。'**
  String get ownPostsLoginRequired;

  /// No description provided for @sessionExpired.
  ///
  /// In ja, this message translates to:
  /// **'認証の有効期限が切れました。再度ログインしてください。'**
  String get sessionExpired;

  /// No description provided for @timelineLoginRequired.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインを表示するにはログインしてください。'**
  String get timelineLoginRequired;

  /// No description provided for @preferenceSweet.
  ///
  /// In ja, this message translates to:
  /// **'甘口'**
  String get preferenceSweet;

  /// No description provided for @preferenceDry.
  ///
  /// In ja, this message translates to:
  /// **'辛口'**
  String get preferenceDry;

  /// No description provided for @preferenceClean.
  ///
  /// In ja, this message translates to:
  /// **'スッキリ'**
  String get preferenceClean;

  /// No description provided for @preferenceFruity.
  ///
  /// In ja, this message translates to:
  /// **'フルーティ'**
  String get preferenceFruity;

  /// No description provided for @preferenceNigori.
  ///
  /// In ja, this message translates to:
  /// **'にごり'**
  String get preferenceNigori;

  /// No description provided for @preferenceSparkling.
  ///
  /// In ja, this message translates to:
  /// **'微発泡'**
  String get preferenceSparkling;

  /// No description provided for @preferenceAcidic.
  ///
  /// In ja, this message translates to:
  /// **'酸味'**
  String get preferenceAcidic;

  /// No description provided for @favoriteSakeQuestion.
  ///
  /// In ja, this message translates to:
  /// **'どんな日本酒が好き？'**
  String get favoriteSakeQuestion;

  /// No description provided for @selectPreferenceFeatures.
  ///
  /// In ja, this message translates to:
  /// **'好みの特徴を選んでください（複数選択可）'**
  String get selectPreferenceFeatures;

  /// No description provided for @selectAtLeastOne.
  ///
  /// In ja, this message translates to:
  /// **'少なくとも1つは選択してください'**
  String get selectAtLeastOne;

  /// No description provided for @preferencesChangeAnytime.
  ///
  /// In ja, this message translates to:
  /// **'マイページからいつでも変更できます！'**
  String get preferencesChangeAnytime;

  /// No description provided for @betaVersion.
  ///
  /// In ja, this message translates to:
  /// **'ベータ版 {version}'**
  String betaVersion(String version);

  /// No description provided for @bottleListClosingNotice.
  ///
  /// In ja, this message translates to:
  /// **'こちらの機能は保存酒とかぶってきたためひっそりとクローズ予定です。'**
  String get bottleListClosingNotice;

  /// No description provided for @noBottleImages.
  ///
  /// In ja, this message translates to:
  /// **'保存された酒瓶画像はありません'**
  String get noBottleImages;

  /// No description provided for @captureBottleHint.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶検索で画像を撮影してみましょう'**
  String get captureBottleHint;

  /// No description provided for @errorOccurred.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get errorOccurred;

  /// No description provided for @unknownSake.
  ///
  /// In ja, this message translates to:
  /// **'不明な酒'**
  String get unknownSake;

  /// No description provided for @capturedDate.
  ///
  /// In ja, this message translates to:
  /// **'撮影日: {date}'**
  String capturedDate(String date);

  /// No description provided for @deleteBottleImageTitle.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除'**
  String get deleteBottleImageTitle;

  /// No description provided for @deleteBottleImageDescription.
  ///
  /// In ja, this message translates to:
  /// **'この酒瓶画像を削除してもよろしいですか？'**
  String get deleteBottleImageDescription;

  /// No description provided for @errorSelectImage.
  ///
  /// In ja, this message translates to:
  /// **'画像の選択に失敗しました'**
  String get errorSelectImage;

  /// No description provided for @unanalyzedBottle.
  ///
  /// In ja, this message translates to:
  /// **'未分析の酒瓶'**
  String get unanalyzedBottle;

  /// No description provided for @errorSaveBottleImage.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶画像の保存に失敗しました'**
  String get errorSaveBottleImage;

  /// No description provided for @errorLoadBottleImages.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶画像の読み込みに失敗しました'**
  String get errorLoadBottleImages;

  /// No description provided for @errorDeleteBottleImage.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶画像の削除に失敗しました'**
  String get errorDeleteBottleImage;

  /// No description provided for @axisFruity.
  ///
  /// In ja, this message translates to:
  /// **'フルーティ'**
  String get axisFruity;

  /// No description provided for @axisCalm.
  ///
  /// In ja, this message translates to:
  /// **'穏やか'**
  String get axisCalm;

  /// No description provided for @axisSweetness.
  ///
  /// In ja, this message translates to:
  /// **'甘味'**
  String get axisSweetness;

  /// No description provided for @axisDry.
  ///
  /// In ja, this message translates to:
  /// **'辛口'**
  String get axisDry;

  /// No description provided for @axisSweet.
  ///
  /// In ja, this message translates to:
  /// **'甘口'**
  String get axisSweet;

  /// No description provided for @axisAcidity.
  ///
  /// In ja, this message translates to:
  /// **'酸味'**
  String get axisAcidity;

  /// No description provided for @axisLowAcid.
  ///
  /// In ja, this message translates to:
  /// **'低酸'**
  String get axisLowAcid;

  /// No description provided for @axisHighAcid.
  ///
  /// In ja, this message translates to:
  /// **'高酸'**
  String get axisHighAcid;

  /// No description provided for @axisUmami.
  ///
  /// In ja, this message translates to:
  /// **'旨味'**
  String get axisUmami;

  /// No description provided for @axisLight.
  ///
  /// In ja, this message translates to:
  /// **'淡麗'**
  String get axisLight;

  /// No description provided for @axisRich.
  ///
  /// In ja, this message translates to:
  /// **'濃醇'**
  String get axisRich;

  /// No description provided for @axisFinish.
  ///
  /// In ja, this message translates to:
  /// **'キレ'**
  String get axisFinish;

  /// No description provided for @axisMellow.
  ///
  /// In ja, this message translates to:
  /// **'まろやか'**
  String get axisMellow;

  /// No description provided for @axisSharp.
  ///
  /// In ja, this message translates to:
  /// **'シャープ'**
  String get axisSharp;

  /// No description provided for @axisSpiciness.
  ///
  /// In ja, this message translates to:
  /// **'辛さ'**
  String get axisSpiciness;

  /// No description provided for @axisGentle.
  ///
  /// In ja, this message translates to:
  /// **'穏やか'**
  String get axisGentle;

  /// No description provided for @axisKick.
  ///
  /// In ja, this message translates to:
  /// **'ピリッ'**
  String get axisKick;

  /// No description provided for @tasteTrendSample.
  ///
  /// In ja, this message translates to:
  /// **'好きなお酒の傾向（サンプル表示）'**
  String get tasteTrendSample;

  /// No description provided for @tasteTrend.
  ///
  /// In ja, this message translates to:
  /// **'好きなお酒の傾向'**
  String get tasteTrend;

  /// No description provided for @tasteTrendSampleDescription.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りデータがそろったら、あなた専用のチャートをここに表示します。'**
  String get tasteTrendSampleDescription;

  /// No description provided for @tasteTrendDescription.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りの日本酒から算出した平均傾向です。あくまでAIの解析なのでお手柔らかに。'**
  String get tasteTrendDescription;

  /// No description provided for @signedInUsersOnly.
  ///
  /// In ja, this message translates to:
  /// **'ログインユーザー限定'**
  String get signedInUsersOnly;

  /// No description provided for @tasteChartLoginDescription.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りの日本酒から傾向チャートを自動生成します。ログインして自分専用の分析を確認しましょう。'**
  String get tasteChartLoginDescription;

  /// No description provided for @loginToViewChart.
  ///
  /// In ja, this message translates to:
  /// **'ログインしてチャートを見る'**
  String get loginToViewChart;

  /// No description provided for @sakeDiagnosisTitle.
  ///
  /// In ja, this message translates to:
  /// **'あなたにぴったりのお酒診断'**
  String get sakeDiagnosisTitle;

  /// No description provided for @tasteChartUpdated.
  ///
  /// In ja, this message translates to:
  /// **'味覚チャートを更新しました！\nお気に入りを増やすとさらに精度が上がります。'**
  String get tasteChartUpdated;

  /// No description provided for @sakeDiagnosisFailed.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りのお酒から診断できませんでした。別のお酒を登録してみてください。'**
  String get sakeDiagnosisFailed;

  /// No description provided for @savePreferenceAndClose.
  ///
  /// In ja, this message translates to:
  /// **'好きな傾向に保存して閉じる'**
  String get savePreferenceAndClose;

  /// No description provided for @badges.
  ///
  /// In ja, this message translates to:
  /// **'バッジ'**
  String get badges;

  /// No description provided for @achievementWelcomeTitle.
  ///
  /// In ja, this message translates to:
  /// **'ウェルカム乾杯'**
  String get achievementWelcomeTitle;

  /// No description provided for @achievementWelcomeDescription.
  ///
  /// In ja, this message translates to:
  /// **'たくさん利用してバッジを集めましょう'**
  String get achievementWelcomeDescription;

  /// No description provided for @achievementBottleTitle.
  ///
  /// In ja, this message translates to:
  /// **'ボトルマスター'**
  String get achievementBottleTitle;

  /// No description provided for @achievementBottleDescription.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶解析で日本酒の知識を深めよう'**
  String get achievementBottleDescription;

  /// No description provided for @achievementEnvyTitle.
  ///
  /// In ja, this message translates to:
  /// **'うらやまコレクター'**
  String get achievementEnvyTitle;

  /// No description provided for @achievementEnvyDescription.
  ///
  /// In ja, this message translates to:
  /// **'うらやまを集めて注目の的になろう'**
  String get achievementEnvyDescription;

  /// No description provided for @badgeComplete.
  ///
  /// In ja, this message translates to:
  /// **'コンプリート！バッジを獲得しました'**
  String get badgeComplete;

  /// No description provided for @badgeRemaining.
  ///
  /// In ja, this message translates to:
  /// **'あと{count}回で次のバッジ'**
  String badgeRemaining(int count);

  /// No description provided for @badgeStart.
  ///
  /// In ja, this message translates to:
  /// **'まずは最初の挑戦から始めてみましょう'**
  String get badgeStart;

  /// No description provided for @goldBadge.
  ///
  /// In ja, this message translates to:
  /// **'ゴールドバッジ'**
  String get goldBadge;

  /// No description provided for @silverBadge.
  ///
  /// In ja, this message translates to:
  /// **'シルバーバッジ'**
  String get silverBadge;

  /// No description provided for @bronzeBadge.
  ///
  /// In ja, this message translates to:
  /// **'ブロンズバッジ'**
  String get bronzeBadge;

  /// No description provided for @badgeNotEarned.
  ///
  /// In ja, this message translates to:
  /// **'未獲得'**
  String get badgeNotEarned;

  /// No description provided for @totalEnvyPoints.
  ///
  /// In ja, this message translates to:
  /// **'累計うらやまポイント'**
  String get totalEnvyPoints;

  /// No description provided for @mapContributionPoints.
  ///
  /// In ja, this message translates to:
  /// **'マップ貢献ポイント'**
  String get mapContributionPoints;

  /// No description provided for @mapContributionPointCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} pt'**
  String mapContributionPointCount(int count);

  /// No description provided for @mapContributionHint.
  ///
  /// In ja, this message translates to:
  /// **'店舗と日本酒の登録で5pt、写真公開で追加10pt'**
  String get mapContributionHint;

  /// No description provided for @collectEnvy.
  ///
  /// In ja, this message translates to:
  /// **'うらやまを集めよう'**
  String get collectEnvy;

  /// No description provided for @envyEarnedCount.
  ///
  /// In ja, this message translates to:
  /// **'これまでに {count} 件のうらやまを獲得しています'**
  String envyEarnedCount(int count);

  /// No description provided for @envyShareHint.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインで共有すると仲間からうらやまが届きます'**
  String get envyShareHint;

  /// No description provided for @everyonePraises.
  ///
  /// In ja, this message translates to:
  /// **'みんなが賞賛！'**
  String get everyonePraises;

  /// No description provided for @tryCollecting.
  ///
  /// In ja, this message translates to:
  /// **'集めてみよう'**
  String get tryCollecting;

  /// No description provided for @timelineIntroTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインへようこそ'**
  String get timelineIntroTitle;

  /// No description provided for @timelineIntroDescription.
  ///
  /// In ja, this message translates to:
  /// **'みんなが飲んだお酒がここにずらり。\n気になる一杯は保存して、あなただけのリストに加えましょう！'**
  String get timelineIntroDescription;

  /// No description provided for @timelineIntroEnvyHint.
  ///
  /// In ja, this message translates to:
  /// **'うらやましい日本酒は気軽に👍ボタンしてあげよう。'**
  String get timelineIntroEnvyHint;

  /// No description provided for @timelinePublishingTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインへの掲載について'**
  String get timelinePublishingTitle;

  /// No description provided for @timelinePublishingDescription.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインで表示されるのは日本酒情報と1枚目の写真だけです。あなたの感想やメモなどは表示されません。ぜひみんなが日本酒を知る機会にご協力ください。'**
  String get timelinePublishingDescription;

  /// No description provided for @continueAnalysis.
  ///
  /// In ja, this message translates to:
  /// **'このまま解析'**
  String get continueAnalysis;

  /// No description provided for @removeCheck.
  ///
  /// In ja, this message translates to:
  /// **'チェックを外す'**
  String get removeCheck;

  /// No description provided for @loginToToggleAutoPost.
  ///
  /// In ja, this message translates to:
  /// **'ログインすると自動投稿を切り替えられます。'**
  String get loginToToggleAutoPost;

  /// No description provided for @autoPostUpdateFailed.
  ///
  /// In ja, this message translates to:
  /// **'自動投稿の更新に失敗しました。時間をおいて再試行してください。'**
  String get autoPostUpdateFailed;

  /// No description provided for @autoPostUpdated.
  ///
  /// In ja, this message translates to:
  /// **'Xへの自動投稿を{status}にしました。'**
  String autoPostUpdated(String status);

  /// No description provided for @statusOn.
  ///
  /// In ja, this message translates to:
  /// **'オン'**
  String get statusOn;

  /// No description provided for @statusOff.
  ///
  /// In ja, this message translates to:
  /// **'オフ'**
  String get statusOff;

  /// No description provided for @autoPostDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'Xへの自動投稿について'**
  String get autoPostDialogTitle;

  /// No description provided for @autoPostDialogDescription.
  ///
  /// In ja, this message translates to:
  /// **'この画像と解析結果だけがツイートされます。\n日本酒を広めるためにご協力お願いします。'**
  String get autoPostDialogDescription;

  /// No description provided for @continuePosting.
  ///
  /// In ja, this message translates to:
  /// **'このまま投稿する'**
  String get continuePosting;

  /// No description provided for @disableAutoPost.
  ///
  /// In ja, this message translates to:
  /// **'自動投稿をオフにする'**
  String get disableAutoPost;

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ja, this message translates to:
  /// **'端末の設定に従う'**
  String get languageSystem;

  /// No description provided for @languageJapanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageEnglish.
  ///
  /// In ja, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @termsOfUse.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get termsOfUse;

  /// No description provided for @developer.
  ///
  /// In ja, this message translates to:
  /// **'開発会社'**
  String get developer;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @saveAction.
  ///
  /// In ja, this message translates to:
  /// **'保存する'**
  String get saveAction;

  /// No description provided for @apply.
  ///
  /// In ja, this message translates to:
  /// **'適用する'**
  String get apply;

  /// No description provided for @clearFilters.
  ///
  /// In ja, this message translates to:
  /// **'絞り込みを解除'**
  String get clearFilters;

  /// No description provided for @search.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get search;

  /// No description provided for @close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @unknown.
  ///
  /// In ja, this message translates to:
  /// **'不明'**
  String get unknown;

  /// No description provided for @unknownName.
  ///
  /// In ja, this message translates to:
  /// **'名称不明'**
  String get unknownName;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In ja, this message translates to:
  /// **'ご利用ありがとうございます。現在のバージョンではご利用いただけないため、ストアからアプリをアップデートしてください。'**
  String get updateRequiredMessage;

  /// No description provided for @openAppStore.
  ///
  /// In ja, this message translates to:
  /// **'App Storeを開く'**
  String get openAppStore;

  /// No description provided for @openPlayStore.
  ///
  /// In ja, this message translates to:
  /// **'Google Playを開く'**
  String get openPlayStore;

  /// No description provided for @welcomeTitle.
  ///
  /// In ja, this message translates to:
  /// **'Sakepediaにようこそ！'**
  String get welcomeTitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスでログインしておくと、保存酒やお気に入りを端末間で同期できます。ログイン後に届く確認メールから認証を完了してください。'**
  String get welcomeDescription;

  /// No description provided for @welcomeFree.
  ///
  /// In ja, this message translates to:
  /// **'もちろん無料で利用可能'**
  String get welcomeFree;

  /// No description provided for @welcomeBackup.
  ///
  /// In ja, this message translates to:
  /// **'保存酒やお気に入りを自動バックアップ'**
  String get welcomeBackup;

  /// No description provided for @welcomeMoreStorage.
  ///
  /// In ja, this message translates to:
  /// **'保存できるお酒が増える！'**
  String get welcomeMoreStorage;

  /// No description provided for @loginOrRegisterWithEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスでログイン・登録'**
  String get loginOrRegisterWithEmail;

  /// No description provided for @continueAsGuest.
  ///
  /// In ja, this message translates to:
  /// **'今はログインせずに使う'**
  String get continueAsGuest;

  /// No description provided for @loginLaterHint.
  ///
  /// In ja, this message translates to:
  /// **'あとからマイページでもログインできます。'**
  String get loginLaterHint;

  /// No description provided for @loginBenefitsTitle.
  ///
  /// In ja, this message translates to:
  /// **'ログインでさらに便利に'**
  String get loginBenefitsTitle;

  /// No description provided for @loginBenefitsDescription.
  ///
  /// In ja, this message translates to:
  /// **'登録なしでも利用できますが、ログインすると保存数が増え、保存酒リストのバックアップや端末間同期が利用できます。'**
  String get loginBenefitsDescription;

  /// No description provided for @userFallbackName.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get userFallbackName;

  /// No description provided for @signedIn.
  ///
  /// In ja, this message translates to:
  /// **'ログイン中'**
  String get signedIn;

  /// No description provided for @helloUser.
  ///
  /// In ja, this message translates to:
  /// **'こんにちは{name}さん！'**
  String helloUser(String name);

  /// No description provided for @authPageTitle.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスでログイン・登録'**
  String get authPageTitle;

  /// No description provided for @signIn.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ja, this message translates to:
  /// **'新規登録'**
  String get signUp;

  /// No description provided for @signInAction.
  ///
  /// In ja, this message translates to:
  /// **'ログインする'**
  String get signInAction;

  /// No description provided for @signUpAction.
  ///
  /// In ja, this message translates to:
  /// **'登録する'**
  String get signUpAction;

  /// No description provided for @signInDescription.
  ///
  /// In ja, this message translates to:
  /// **'登録済みのメールアドレスとパスワードでログインします。パスワードを忘れた場合は再設定メールを送信できます。'**
  String get signInDescription;

  /// No description provided for @signUpDescription.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスとパスワードを設定してアカウントを作成できます。登録後は同じ情報でログインできます。'**
  String get signUpDescription;

  /// No description provided for @emailAddress.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワード（確認用）'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードをお忘れの方はこちら'**
  String get forgotPassword;

  /// No description provided for @guestUseAvailable.
  ///
  /// In ja, this message translates to:
  /// **'登録しなくてもアプリをご利用いただけます。'**
  String get guestUseAvailable;

  /// No description provided for @passwordMismatch.
  ///
  /// In ja, this message translates to:
  /// **'確認用パスワードが一致しません。'**
  String get passwordMismatch;

  /// No description provided for @passwordResetSent.
  ///
  /// In ja, this message translates to:
  /// **'パスワード再設定メールを送信しました。迷惑メールフォルダもご確認ください。'**
  String get passwordResetSent;

  /// No description provided for @verificationEmailSent.
  ///
  /// In ja, this message translates to:
  /// **'確認メールを送信しました。迷惑メールもご確認ください。メール内のリンクから認証を完了し、再度ログインしてください。'**
  String get verificationEmailSent;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In ja, this message translates to:
  /// **'パスワード再設定用のメールを送信しました。'**
  String get passwordResetEmailSent;

  /// No description provided for @loginCompleted.
  ///
  /// In ja, this message translates to:
  /// **'ログインしました。'**
  String get loginCompleted;

  /// No description provided for @logoutCompleted.
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしました。'**
  String get logoutCompleted;

  /// No description provided for @accountDeleted.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除しました。'**
  String get accountDeleted;

  /// No description provided for @nicknameUpdated.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを更新しました。'**
  String get nicknameUpdated;

  /// No description provided for @accountSettings.
  ///
  /// In ja, this message translates to:
  /// **'アカウント設定'**
  String get accountSettings;

  /// No description provided for @notSet.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get notSet;

  /// No description provided for @nickname.
  ///
  /// In ja, this message translates to:
  /// **'ニックネーム'**
  String get nickname;

  /// No description provided for @nicknameHint.
  ///
  /// In ja, this message translates to:
  /// **'例）日本酒好き太郎'**
  String get nicknameHint;

  /// No description provided for @saveNickname.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを保存'**
  String get saveNickname;

  /// No description provided for @errorEnterNickname.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを入力してください。'**
  String get errorEnterNickname;

  /// No description provided for @errorNicknameLength.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームは10文字以内で入力してください。'**
  String get errorNicknameLength;

  /// No description provided for @errorNicknameUpdate.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームの更新に失敗しました。時間をおいて再度お試しください。'**
  String get errorNicknameUpdate;

  /// No description provided for @updating.
  ///
  /// In ja, this message translates to:
  /// **'更新中...'**
  String get updating;

  /// No description provided for @changeIcon.
  ///
  /// In ja, this message translates to:
  /// **'アイコンを変更'**
  String get changeIcon;

  /// No description provided for @iconUpdated.
  ///
  /// In ja, this message translates to:
  /// **'アイコンを更新しました。'**
  String get iconUpdated;

  /// No description provided for @errorIconUpdate.
  ///
  /// In ja, this message translates to:
  /// **'アイコンの更新に失敗しました。時間をおいて再度お試しください。'**
  String get errorIconUpdate;

  /// No description provided for @selectFromPhotoLibrary.
  ///
  /// In ja, this message translates to:
  /// **'フォトライブラリから選択'**
  String get selectFromPhotoLibrary;

  /// No description provided for @emailChangeUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'※ 現在アプリ内でメールアドレスの変更はできません。'**
  String get emailChangeUnavailable;

  /// No description provided for @signingOut.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト中...'**
  String get signingOut;

  /// No description provided for @signOut.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get signOut;

  /// No description provided for @accountDeletion.
  ///
  /// In ja, this message translates to:
  /// **'アカウント削除'**
  String get accountDeletion;

  /// No description provided for @accountDeletionConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'アカウント削除の確認'**
  String get accountDeletionConfirmation;

  /// No description provided for @accountDeletionWarning.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除すると、保存酒・お気に入り・嗜好設定などのデータはすべて削除されます。削除後は元に戻せません。'**
  String get accountDeletionWarning;

  /// No description provided for @accountDeletionWarningShort.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除すると、保存酒・お気に入り・嗜好設定などのデータはすべて削除されます。'**
  String get accountDeletionWarningShort;

  /// No description provided for @enterPasswordToConfirm.
  ///
  /// In ja, this message translates to:
  /// **'確認のため、パスワードを入力してください。'**
  String get enterPasswordToConfirm;

  /// No description provided for @deleteAction.
  ///
  /// In ja, this message translates to:
  /// **'削除する'**
  String get deleteAction;

  /// No description provided for @deleteAccountAction.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除する'**
  String get deleteAccountAction;

  /// No description provided for @nameSearch.
  ///
  /// In ja, this message translates to:
  /// **'名前で検索'**
  String get nameSearch;

  /// No description provided for @bottleSearch.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶検索'**
  String get bottleSearch;

  /// No description provided for @sakeName.
  ///
  /// In ja, this message translates to:
  /// **'日本酒名'**
  String get sakeName;

  /// No description provided for @enterSakeName.
  ///
  /// In ja, this message translates to:
  /// **'日本酒名を入力'**
  String get enterSakeName;

  /// No description provided for @sakeType.
  ///
  /// In ja, this message translates to:
  /// **'種類'**
  String get sakeType;

  /// No description provided for @enterOptionalSakeType.
  ///
  /// In ja, this message translates to:
  /// **'種類を入力（任意）'**
  String get enterOptionalSakeType;

  /// No description provided for @selectBottleImage.
  ///
  /// In ja, this message translates to:
  /// **'日本酒のラベルや瓶の画像を選択してください'**
  String get selectBottleImage;

  /// No description provided for @tapToSelectImage.
  ///
  /// In ja, this message translates to:
  /// **'タップして画像を選択'**
  String get tapToSelectImage;

  /// No description provided for @takePhoto.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get takePhoto;

  /// No description provided for @shareToTimeline.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインにも表示する'**
  String get shareToTimeline;

  /// No description provided for @onlyFirstImageShared.
  ///
  /// In ja, this message translates to:
  /// **'画像は1枚目だけ共有されます。'**
  String get onlyFirstImageShared;

  /// No description provided for @autoPostToX.
  ///
  /// In ja, this message translates to:
  /// **'Xに自動投稿'**
  String get autoPostToX;

  /// No description provided for @autoPostToXDescription.
  ///
  /// In ja, this message translates to:
  /// **'解析完了時に結果をXにも自動投稿します。'**
  String get autoPostToXDescription;

  /// No description provided for @loginToChangeSetting.
  ///
  /// In ja, this message translates to:
  /// **'ログインすると設定を変更できます。'**
  String get loginToChangeSetting;

  /// No description provided for @loadingAutoPostSetting.
  ///
  /// In ja, this message translates to:
  /// **'自動投稿の設定を取得中です...'**
  String get loadingAutoPostSetting;

  /// No description provided for @updatingSetting.
  ///
  /// In ja, this message translates to:
  /// **'設定を更新中...'**
  String get updatingSetting;

  /// No description provided for @analyzeAndSave.
  ///
  /// In ja, this message translates to:
  /// **'解析して保存'**
  String get analyzeAndSave;

  /// No description provided for @analyzeOnly.
  ///
  /// In ja, this message translates to:
  /// **'解析だけ'**
  String get analyzeOnly;

  /// No description provided for @analyzingWithAd.
  ///
  /// In ja, this message translates to:
  /// **'解析中...広告の表示にご協力ください...'**
  String get analyzingWithAd;

  /// No description provided for @loadingSakeInfo.
  ///
  /// In ja, this message translates to:
  /// **'日本酒情報を取得しています...'**
  String get loadingSakeInfo;

  /// No description provided for @aiAnalysisResult.
  ///
  /// In ja, this message translates to:
  /// **'AIの解析結果'**
  String get aiAnalysisResult;

  /// No description provided for @tryBackLabelHint.
  ///
  /// In ja, this message translates to:
  /// **'裏のラベルなら解析できるかもしれません。'**
  String get tryBackLabelHint;

  /// No description provided for @saveSake.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get saveSake;

  /// No description provided for @removeSavedSake.
  ///
  /// In ja, this message translates to:
  /// **'保存を解除'**
  String get removeSavedSake;

  /// No description provided for @savedToMyPage.
  ///
  /// In ja, this message translates to:
  /// **'マイページに保存しました！'**
  String get savedToMyPage;

  /// No description provided for @favorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り'**
  String get favorite;

  /// No description provided for @removeFavorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り解除'**
  String get removeFavorite;

  /// No description provided for @unknownType.
  ///
  /// In ja, this message translates to:
  /// **'種類不明'**
  String get unknownType;

  /// No description provided for @loadingDetails.
  ///
  /// In ja, this message translates to:
  /// **'詳細情報を取得中...'**
  String get loadingDetails;

  /// No description provided for @detailsUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'詳細情報を取得できませんでした'**
  String get detailsUnavailable;

  /// No description provided for @expand.
  ///
  /// In ja, this message translates to:
  /// **'展開'**
  String get expand;

  /// No description provided for @highlyRecommended.
  ///
  /// In ja, this message translates to:
  /// **'超おすすめ！'**
  String get highlyRecommended;

  /// No description provided for @recommended.
  ///
  /// In ja, this message translates to:
  /// **'おすすめ！'**
  String get recommended;

  /// No description provided for @goodSake.
  ///
  /// In ja, this message translates to:
  /// **'良い日本酒'**
  String get goodSake;

  /// No description provided for @characteristics.
  ///
  /// In ja, this message translates to:
  /// **'特徴'**
  String get characteristics;

  /// No description provided for @brewery.
  ///
  /// In ja, this message translates to:
  /// **'蔵元'**
  String get brewery;

  /// No description provided for @sakeMeterValue.
  ///
  /// In ja, this message translates to:
  /// **'日本酒度'**
  String get sakeMeterValue;

  /// No description provided for @searchByType.
  ///
  /// In ja, this message translates to:
  /// **'タイプ別検索'**
  String get searchByType;

  /// No description provided for @sweet.
  ///
  /// In ja, this message translates to:
  /// **'甘口'**
  String get sweet;

  /// No description provided for @dry.
  ///
  /// In ja, this message translates to:
  /// **'辛口'**
  String get dry;

  /// No description provided for @savedSake.
  ///
  /// In ja, this message translates to:
  /// **'保存酒'**
  String get savedSake;

  /// No description provided for @savedSakeEmpty.
  ///
  /// In ja, this message translates to:
  /// **'保存した日本酒はまだありません。'**
  String get savedSakeEmpty;

  /// No description provided for @savedSakeEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'まだ保存したお酒はありません。\nメニュー検索からブックマークしてみましょう！'**
  String get savedSakeEmptyHint;

  /// No description provided for @sort.
  ///
  /// In ja, this message translates to:
  /// **'並び替え'**
  String get sort;

  /// No description provided for @gridView.
  ///
  /// In ja, this message translates to:
  /// **'グリッド表示'**
  String get gridView;

  /// No description provided for @listView.
  ///
  /// In ja, this message translates to:
  /// **'リスト表示'**
  String get listView;

  /// No description provided for @filterByTag.
  ///
  /// In ja, this message translates to:
  /// **'タグで絞り込む'**
  String get filterByTag;

  /// No description provided for @noAvailableTags.
  ///
  /// In ja, this message translates to:
  /// **'利用可能なタグがまだありません。'**
  String get noAvailableTags;

  /// No description provided for @savedSakeLimit.
  ///
  /// In ja, this message translates to:
  /// **'保存酒は{count}件まで保存できます。不要な保存酒を削除してください。'**
  String savedSakeLimit(int count);

  /// No description provided for @removedFromSaved.
  ///
  /// In ja, this message translates to:
  /// **'{name} を保存リストから削除しました'**
  String removedFromSaved(String name);

  /// No description provided for @bottleList.
  ///
  /// In ja, this message translates to:
  /// **'酒瓶リスト'**
  String get bottleList;

  /// No description provided for @sakeDetails.
  ///
  /// In ja, this message translates to:
  /// **'日本酒詳細'**
  String get sakeDetails;

  /// No description provided for @price.
  ///
  /// In ja, this message translates to:
  /// **'価格'**
  String get price;

  /// No description provided for @recommendationScore.
  ///
  /// In ja, this message translates to:
  /// **'おすすめ度'**
  String get recommendationScore;

  /// No description provided for @tasteAndFeatures.
  ///
  /// In ja, this message translates to:
  /// **'テイスト・特徴'**
  String get tasteAndFeatures;

  /// No description provided for @description.
  ///
  /// In ja, this message translates to:
  /// **'説明'**
  String get description;

  /// No description provided for @basicInformation.
  ///
  /// In ja, this message translates to:
  /// **'基本情報'**
  String get basicInformation;

  /// No description provided for @noDetailedInformation.
  ///
  /// In ja, this message translates to:
  /// **'詳細情報が登録されていません。'**
  String get noDetailedInformation;

  /// No description provided for @processing.
  ///
  /// In ja, this message translates to:
  /// **'処理中…'**
  String get processing;

  /// No description provided for @savedDate.
  ///
  /// In ja, this message translates to:
  /// **'保存日 {date}'**
  String savedDate(String date);

  /// No description provided for @syncedToServer.
  ///
  /// In ja, this message translates to:
  /// **'サーバーに保存済み'**
  String get syncedToServer;

  /// No description provided for @localOnly.
  ///
  /// In ja, this message translates to:
  /// **'未同期（この端末にのみ保存されています）'**
  String get localOnly;

  /// No description provided for @notSynced.
  ///
  /// In ja, this message translates to:
  /// **'未同期'**
  String get notSynced;

  /// No description provided for @consumedAt.
  ///
  /// In ja, this message translates to:
  /// **'飲んだ場所: {place}'**
  String consumedAt(String place);

  /// No description provided for @noMatchingTags.
  ///
  /// In ja, this message translates to:
  /// **'選択中のタグに該当するお酒がありません。'**
  String get noMatchingTags;

  /// No description provided for @syncToServer.
  ///
  /// In ja, this message translates to:
  /// **'サーバーへ同期'**
  String get syncToServer;

  /// No description provided for @manualNameSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'名前を手動で検索可能です'**
  String get manualNameSearchHint;

  /// No description provided for @syncToChangeVisibility.
  ///
  /// In ja, this message translates to:
  /// **'サーバーに同期するとタイムライン公開を切り替えられます。'**
  String get syncToChangeVisibility;

  /// No description provided for @loginToChangeVisibility.
  ///
  /// In ja, this message translates to:
  /// **'ログインすると公開設定を変更できます。'**
  String get loginToChangeVisibility;

  /// No description provided for @visibilityChangeHint.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインへの公開／非公開をいつでも切り替えられます。'**
  String get visibilityChangeHint;

  /// No description provided for @showOnTimeline.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインに表示する'**
  String get showOnTimeline;

  /// No description provided for @reanalyze.
  ///
  /// In ja, this message translates to:
  /// **'再解析'**
  String get reanalyze;

  /// No description provided for @change.
  ///
  /// In ja, this message translates to:
  /// **'変更'**
  String get change;

  /// No description provided for @loginToReanalyze.
  ///
  /// In ja, this message translates to:
  /// **'ログインすると再解析できます'**
  String get loginToReanalyze;

  /// No description provided for @loginToReanalyzeAfterRename.
  ///
  /// In ja, this message translates to:
  /// **'ログインすると名前変更後に再解析できます'**
  String get loginToReanalyzeAfterRename;

  /// No description provided for @memo.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get memo;

  /// No description provided for @memoFilterHint.
  ///
  /// In ja, this message translates to:
  /// **'設定しておくと一覧でフィルタリングできます。'**
  String get memoFilterHint;

  /// No description provided for @impressionLabel.
  ///
  /// In ja, this message translates to:
  /// **'感想（200文字まで）'**
  String get impressionLabel;

  /// No description provided for @impressionHint.
  ///
  /// In ja, this message translates to:
  /// **'味わいや香りの印象を記録しましょう'**
  String get impressionHint;

  /// No description provided for @placeConsumed.
  ///
  /// In ja, this message translates to:
  /// **'この日本酒がある店舗'**
  String get placeConsumed;

  /// No description provided for @registeredShop.
  ///
  /// In ja, this message translates to:
  /// **'登録店舗：{shop}'**
  String registeredShop(String shop);

  /// No description provided for @placeConsumedHint.
  ///
  /// In ja, this message translates to:
  /// **'Google検索候補から店舗を登録できます'**
  String get placeConsumedHint;

  /// No description provided for @addConsumedPlace.
  ///
  /// In ja, this message translates to:
  /// **'店舗を登録'**
  String get addConsumedPlace;

  /// No description provided for @changeConsumedPlace.
  ///
  /// In ja, this message translates to:
  /// **'登録店舗を変更'**
  String get changeConsumedPlace;

  /// No description provided for @shopContributionNotice.
  ///
  /// In ja, this message translates to:
  /// **'店舗を選ぶと、この店舗と日本酒が匿名でマップに登録され、5ptを獲得します。'**
  String get shopContributionNotice;

  /// No description provided for @findPlaceNearby.
  ///
  /// In ja, this message translates to:
  /// **'近くで探す'**
  String get findPlaceNearby;

  /// No description provided for @findPlaceByName.
  ///
  /// In ja, this message translates to:
  /// **'名前で探す'**
  String get findPlaceByName;

  /// No description provided for @placeNameSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'店名・施設名を入力'**
  String get placeNameSearchHint;

  /// No description provided for @searchingNearbyPlaces.
  ///
  /// In ja, this message translates to:
  /// **'現在地付近を検索しています…'**
  String get searchingNearbyPlaces;

  /// No description provided for @searchingPlaces.
  ///
  /// In ja, this message translates to:
  /// **'場所を検索しています…'**
  String get searchingPlaces;

  /// No description provided for @noNearbyPlaces.
  ///
  /// In ja, this message translates to:
  /// **'近くに候補が見つかりませんでした'**
  String get noNearbyPlaces;

  /// No description provided for @noPlaceResults.
  ///
  /// In ja, this message translates to:
  /// **'一致する場所が見つかりませんでした'**
  String get noPlaceResults;

  /// No description provided for @useEnteredPlace.
  ///
  /// In ja, this message translates to:
  /// **'「{place}」を入力する'**
  String useEnteredPlace(String place);

  /// No description provided for @placeSearchFailed.
  ///
  /// In ja, this message translates to:
  /// **'店舗を検索できませんでした。時間をおいて再度お試しください。'**
  String get placeSearchFailed;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In ja, this message translates to:
  /// **'端末の位置情報をオンにしてください'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ja, this message translates to:
  /// **'近くのお店を探すには位置情報の許可が必要です'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In ja, this message translates to:
  /// **'設定画面から位置情報を許可してください'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @openSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定を開く'**
  String get openSettings;

  /// No description provided for @poweredByGoogle.
  ///
  /// In ja, this message translates to:
  /// **'Powered by Google'**
  String get poweredByGoogle;

  /// No description provided for @saveMemories.
  ///
  /// In ja, this message translates to:
  /// **'思い出も残そう'**
  String get saveMemories;

  /// No description provided for @recordPrompt.
  ///
  /// In ja, this message translates to:
  /// **'このお酒の記録を残しませんか？'**
  String get recordPrompt;

  /// No description provided for @add.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get add;

  /// No description provided for @maxThreeImages.
  ///
  /// In ja, this message translates to:
  /// **'画像は最大3枚までです'**
  String get maxThreeImages;

  /// No description provided for @syncToAddImages.
  ///
  /// In ja, this message translates to:
  /// **'サーバー同期をすると画像を追加できます'**
  String get syncToAddImages;

  /// No description provided for @memoSaved.
  ///
  /// In ja, this message translates to:
  /// **'メモを保存しました'**
  String get memoSaved;

  /// No description provided for @savingToServer.
  ///
  /// In ja, this message translates to:
  /// **'サーバーに保存中…'**
  String get savingToServer;

  /// No description provided for @savedToServer.
  ///
  /// In ja, this message translates to:
  /// **'サーバーに保存しました'**
  String get savedToServer;

  /// No description provided for @errorSaveToServer.
  ///
  /// In ja, this message translates to:
  /// **'サーバーへの保存に失敗しました。通信環境をご確認ください。'**
  String get errorSaveToServer;

  /// No description provided for @errorEnterSakeNameDetail.
  ///
  /// In ja, this message translates to:
  /// **'日本酒の名前を入力してください'**
  String get errorEnterSakeNameDetail;

  /// No description provided for @noChanges.
  ///
  /// In ja, this message translates to:
  /// **'変更された内容がありません'**
  String get noChanges;

  /// No description provided for @nameSaved.
  ///
  /// In ja, this message translates to:
  /// **'名前を保存しました'**
  String get nameSaved;

  /// No description provided for @reanalyzing.
  ///
  /// In ja, this message translates to:
  /// **'再解析中…'**
  String get reanalyzing;

  /// No description provided for @reanalyzeCompleted.
  ///
  /// In ja, this message translates to:
  /// **'再解析が完了しました'**
  String get reanalyzeCompleted;

  /// No description provided for @errorReanalyze.
  ///
  /// In ja, this message translates to:
  /// **'再解析に失敗しました。通信環境をご確認のうえ再度お試しください。'**
  String get errorReanalyze;

  /// No description provided for @syncingWithServer.
  ///
  /// In ja, this message translates to:
  /// **'サーバーと同期中…'**
  String get syncingWithServer;

  /// No description provided for @syncedWithServer.
  ///
  /// In ja, this message translates to:
  /// **'サーバーと同期しました！'**
  String get syncedWithServer;

  /// No description provided for @errorSync.
  ///
  /// In ja, this message translates to:
  /// **'同期に失敗しました。通信環境をご確認のうえ再度お試しください。'**
  String get errorSync;

  /// No description provided for @imageAdded.
  ///
  /// In ja, this message translates to:
  /// **'画像を追加しました'**
  String get imageAdded;

  /// No description provided for @deleteImageConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除しますか？'**
  String get deleteImageConfirmation;

  /// No description provided for @deleteImageDescription.
  ///
  /// In ja, this message translates to:
  /// **'この画像をリストから削除します。'**
  String get deleteImageDescription;

  /// No description provided for @deleteImage.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除'**
  String get deleteImage;

  /// No description provided for @imageDeleted.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除しました'**
  String get imageDeleted;

  /// No description provided for @errorImageAdd.
  ///
  /// In ja, this message translates to:
  /// **'画像の追加に失敗しました'**
  String get errorImageAdd;

  /// No description provided for @errorImageDelete.
  ///
  /// In ja, this message translates to:
  /// **'画像の削除に失敗しました'**
  String get errorImageDelete;

  /// No description provided for @addedToFavorites.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りに追加しました'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavoritesToast.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りから削除しました'**
  String get removedFromFavoritesToast;

  /// No description provided for @missingSavedIdReanalyze.
  ///
  /// In ja, this message translates to:
  /// **'保存IDが未設定のため再解析は利用できません'**
  String get missingSavedIdReanalyze;

  /// No description provided for @syncBeforeVisibility.
  ///
  /// In ja, this message translates to:
  /// **'サーバーに同期するとタイムライン公開を設定できます'**
  String get syncBeforeVisibility;

  /// No description provided for @errorVisibilityUpdate.
  ///
  /// In ja, this message translates to:
  /// **'公開設定の更新に失敗しました。通信環境をご確認ください。'**
  String get errorVisibilityUpdate;

  /// No description provided for @publishedToTimeline.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインに公開しました'**
  String get publishedToTimeline;

  /// No description provided for @hiddenFromTimeline.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインでの表示をオフにしました'**
  String get hiddenFromTimeline;

  /// No description provided for @missingSavedIdServerSave.
  ///
  /// In ja, this message translates to:
  /// **'保存IDが未設定のためサーバー保存はできません'**
  String get missingSavedIdServerSave;

  /// No description provided for @loginForServerReanalyze.
  ///
  /// In ja, this message translates to:
  /// **'ログインするとサーバー再解析を利用できます'**
  String get loginForServerReanalyze;

  /// No description provided for @savedIdNotFound.
  ///
  /// In ja, this message translates to:
  /// **'保存IDが見つかりませんでした'**
  String get savedIdNotFound;

  /// No description provided for @syncableSavedIdNotFound.
  ///
  /// In ja, this message translates to:
  /// **'同期できる保存IDが見つかりませんでした。'**
  String get syncableSavedIdNotFound;

  /// No description provided for @savedInformationNotFound.
  ///
  /// In ja, this message translates to:
  /// **'保存情報が見つかりません'**
  String get savedInformationNotFound;

  /// No description provided for @favoriteSake.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りのお酒'**
  String get favoriteSake;

  /// No description provided for @favoriteEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだお気に入りはありません。\n日本酒を検索して♡マークを押してみましょう！'**
  String get favoriteEmpty;

  /// No description provided for @removedFromFavorites.
  ///
  /// In ja, this message translates to:
  /// **'{name} をお気に入りから削除しました'**
  String removedFromFavorites(String name);

  /// No description provided for @favoriteDiagnosis.
  ///
  /// In ja, this message translates to:
  /// **'あなたにぴったりのお酒診断'**
  String get favoriteDiagnosis;

  /// No description provided for @diagnosisDailyLimit.
  ///
  /// In ja, this message translates to:
  /// **'診断は1日に3回までです。時間をおいてお試しください。'**
  String get diagnosisDailyLimit;

  /// No description provided for @needMoreFavorites.
  ///
  /// In ja, this message translates to:
  /// **'もう少しお気に入りのお酒を登録してください。'**
  String get needMoreFavorites;

  /// No description provided for @tastePreferences.
  ///
  /// In ja, this message translates to:
  /// **'好きなお酒の傾向'**
  String get tastePreferences;

  /// No description provided for @tastePreferencesDescription.
  ///
  /// In ja, this message translates to:
  /// **'好みのお酒の特徴を入力すると、おすすめの日本酒を探しやすくなります。'**
  String get tastePreferencesDescription;

  /// No description provided for @tastePreferencesHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 甘口でフルーティな香りが好きです。辛すぎるのは苦手です。'**
  String get tastePreferencesHint;

  /// No description provided for @preferencesSaved.
  ///
  /// In ja, this message translates to:
  /// **'好みを保存しました'**
  String get preferencesSaved;

  /// No description provided for @menuPhotoDescription.
  ///
  /// In ja, this message translates to:
  /// **'メニューの写真をアップロードして日本酒を検索'**
  String get menuPhotoDescription;

  /// No description provided for @searchSakeFromMenu.
  ///
  /// In ja, this message translates to:
  /// **'日本酒を検索'**
  String get searchSakeFromMenu;

  /// No description provided for @detectedSake.
  ///
  /// In ja, this message translates to:
  /// **'検出された日本酒'**
  String get detectedSake;

  /// No description provided for @menuHistory.
  ///
  /// In ja, this message translates to:
  /// **'解析履歴'**
  String get menuHistory;

  /// No description provided for @noMenuHistory.
  ///
  /// In ja, this message translates to:
  /// **'解析履歴はありません'**
  String get noMenuHistory;

  /// No description provided for @pastMenuAnalysis.
  ///
  /// In ja, this message translates to:
  /// **'過去のメニュー解析'**
  String get pastMenuAnalysis;

  /// No description provided for @deleteConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'削除の確認'**
  String get deleteConfirmation;

  /// No description provided for @deleteMenuHistoryConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'この解析履歴を削除してもよろしいですか？'**
  String get deleteMenuHistoryConfirmation;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @sakeCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件の日本酒'**
  String sakeCount(int count);

  /// No description provided for @enterStoreName.
  ///
  /// In ja, this message translates to:
  /// **'店舗名を入力'**
  String get enterStoreName;

  /// No description provided for @enterStoreNameHint.
  ///
  /// In ja, this message translates to:
  /// **'店舗名を入力してください'**
  String get enterStoreNameHint;

  /// No description provided for @preferenceSearchDescription.
  ///
  /// In ja, this message translates to:
  /// **'産地や味わいから好きな日本酒を見つけよう！'**
  String get preferenceSearchDescription;

  /// No description provided for @searchByRegion.
  ///
  /// In ja, this message translates to:
  /// **'産地で検索'**
  String get searchByRegion;

  /// No description provided for @continueInquiry.
  ///
  /// In ja, this message translates to:
  /// **'続けて問い合わせる'**
  String get continueInquiry;

  /// No description provided for @flavorGroupOne.
  ///
  /// In ja, this message translates to:
  /// **'味わい 1'**
  String get flavorGroupOne;

  /// No description provided for @flavorGroupTwo.
  ///
  /// In ja, this message translates to:
  /// **'味わい 2'**
  String get flavorGroupTwo;

  /// No description provided for @specificDesignation.
  ///
  /// In ja, this message translates to:
  /// **'特定名称ほか'**
  String get specificDesignation;

  /// No description provided for @selectRegion.
  ///
  /// In ja, this message translates to:
  /// **'産地を選択'**
  String get selectRegion;

  /// No description provided for @region.
  ///
  /// In ja, this message translates to:
  /// **'産地'**
  String get region;

  /// No description provided for @flavor.
  ///
  /// In ja, this message translates to:
  /// **'香り・印象'**
  String get flavor;

  /// No description provided for @taste.
  ///
  /// In ja, this message translates to:
  /// **'味わい'**
  String get taste;

  /// No description provided for @type.
  ///
  /// In ja, this message translates to:
  /// **'種類'**
  String get type;

  /// No description provided for @askAi.
  ///
  /// In ja, this message translates to:
  /// **'AIに質問'**
  String get askAi;

  /// No description provided for @savedLimitTitle.
  ///
  /// In ja, this message translates to:
  /// **'保存枠が上限に達しました'**
  String get savedLimitTitle;

  /// No description provided for @savedLimitMessage.
  ///
  /// In ja, this message translates to:
  /// **'無料会員登録で保存枠が増えます。\n現在の保存上限は{count}件です。\n解析前に会員登録すると無料で保存がもっとできます！'**
  String savedLimitMessage(int count);

  /// No description provided for @favoriteLimitTitle.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り枠が上限に達しました'**
  String get favoriteLimitTitle;

  /// No description provided for @favoriteLimitMessage.
  ///
  /// In ja, this message translates to:
  /// **'無料会員登録でお気に入り枠が増えます。\n現在の上限は{count}件です。\n会員登録するとお気に入りを無制限に登録できます！'**
  String favoriteLimitMessage(int count);

  /// No description provided for @goToLoginOrRegister.
  ///
  /// In ja, this message translates to:
  /// **'ログイン・登録へ'**
  String get goToLoginOrRegister;

  /// No description provided for @adConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'広告視聴の確認'**
  String get adConfirmation;

  /// No description provided for @adFeatureDescription.
  ///
  /// In ja, this message translates to:
  /// **'広告を視聴すると、特別な機能が利用できます。'**
  String get adFeatureDescription;

  /// No description provided for @searchAdDescription.
  ///
  /// In ja, this message translates to:
  /// **'広告を視聴すると、日本酒情報を検索できます。広告の視聴にご協力ください。'**
  String get searchAdDescription;

  /// No description provided for @bottleAdDescription.
  ///
  /// In ja, this message translates to:
  /// **'広告を視聴すると、酒瓶を解析できます。続行しますか？'**
  String get bottleAdDescription;

  /// No description provided for @menuAdDescription.
  ///
  /// In ja, this message translates to:
  /// **'メニューから日本酒情報を解析するには広告の視聴が必要です。'**
  String get menuAdDescription;

  /// No description provided for @searchCancelled.
  ///
  /// In ja, this message translates to:
  /// **'検索をキャンセルしました。次回は広告視聴へのご協力をお願いします。'**
  String get searchCancelled;

  /// No description provided for @analysisCancelled.
  ///
  /// In ja, this message translates to:
  /// **'解析をキャンセルしました。次回は広告視聴へのご協力をお願いします。'**
  String get analysisCancelled;

  /// No description provided for @imageSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'画像の保存に失敗しました'**
  String get imageSaveFailed;

  /// No description provided for @agree.
  ///
  /// In ja, this message translates to:
  /// **'同意する'**
  String get agree;

  /// No description provided for @errorEnterEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスを入力してください。'**
  String get errorEnterEmail;

  /// No description provided for @errorEnterPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを入力してください。'**
  String get errorEnterPassword;

  /// No description provided for @errorPasswordLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上で入力してください。'**
  String get errorPasswordLength;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません。'**
  String get errorInvalidEmail;

  /// No description provided for @errorInvalidCredential.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスまたはパスワードが正しくありません。'**
  String get errorInvalidCredential;

  /// No description provided for @errorUserNotFound.
  ///
  /// In ja, this message translates to:
  /// **'該当するユーザーが見つかりません。登録済みかご確認ください。'**
  String get errorUserNotFound;

  /// No description provided for @errorEmailInUse.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に使用されています。'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In ja, this message translates to:
  /// **'より複雑なパスワードを設定してください。'**
  String get errorWeakPassword;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In ja, this message translates to:
  /// **'リクエストが集中しています。少し時間をおいてから再度お試しください。'**
  String get errorTooManyRequests;

  /// No description provided for @errorSignInFailed.
  ///
  /// In ja, this message translates to:
  /// **'ログインに失敗しました。通信環境をご確認のうえ再度お試しください。'**
  String get errorSignInFailed;

  /// No description provided for @errorSignUpFailed.
  ///
  /// In ja, this message translates to:
  /// **'登録に失敗しました。時間をおいて再度お試しください。'**
  String get errorSignUpFailed;

  /// No description provided for @errorVerificationEmailFailed.
  ///
  /// In ja, this message translates to:
  /// **'確認メールの送信に失敗しました。時間をおいて再度お試しください。'**
  String get errorVerificationEmailFailed;

  /// No description provided for @errorEmailSendFailed.
  ///
  /// In ja, this message translates to:
  /// **'メールの送信に失敗しました。通信環境をご確認のうえ再度お試しください。'**
  String get errorEmailSendFailed;

  /// No description provided for @errorSignOutFailed.
  ///
  /// In ja, this message translates to:
  /// **'ログアウトに失敗しました。時間をおいて再度お試しください。'**
  String get errorSignOutFailed;

  /// No description provided for @errorUserDisabled.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは利用できません。別のメールアドレスでお試しください。'**
  String get errorUserDisabled;

  /// No description provided for @errorRecentLoginRequired.
  ///
  /// In ja, this message translates to:
  /// **'安全のため再ログインが必要です。ログアウト後に再度ログインしてお試しください。'**
  String get errorRecentLoginRequired;

  /// No description provided for @errorLoginStateUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'ログイン状態を確認できませんでした。再度ログインしてお試しください。'**
  String get errorLoginStateUnavailable;

  /// No description provided for @errorAuthenticationFailed.
  ///
  /// In ja, this message translates to:
  /// **'認証に失敗しました。通信環境をご確認のうえ再度お試しください。'**
  String get errorAuthenticationFailed;

  /// No description provided for @errorAccountDeletion.
  ///
  /// In ja, this message translates to:
  /// **'アカウント削除に失敗しました。時間をおいて再度お試しください。'**
  String get errorAccountDeletion;

  /// No description provided for @errorGeneric.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました。お手数ですが再度お試しください。'**
  String get errorGeneric;

  /// No description provided for @errorEnterSakeName.
  ///
  /// In ja, this message translates to:
  /// **'日本酒名を入力してください'**
  String get errorEnterSakeName;

  /// No description provided for @errorSakeNotFound.
  ///
  /// In ja, this message translates to:
  /// **'日本酒情報が見つかりませんでした'**
  String get errorSakeNotFound;

  /// No description provided for @errorSakeFetch.
  ///
  /// In ja, this message translates to:
  /// **'日本酒情報の取得に失敗しました'**
  String get errorSakeFetch;

  /// No description provided for @errorImageNotFound.
  ///
  /// In ja, this message translates to:
  /// **'解析に使用する画像が見つかりませんでした'**
  String get errorImageNotFound;

  /// No description provided for @errorMenuExtraction.
  ///
  /// In ja, this message translates to:
  /// **'日本酒情報の抽出に失敗しました'**
  String get errorMenuExtraction;

  /// No description provided for @errorNoSakeExtracted.
  ///
  /// In ja, this message translates to:
  /// **'日本酒情報を抽出できませんでした'**
  String get errorNoSakeExtracted;

  /// No description provided for @errorSakeDetailFetch.
  ///
  /// In ja, this message translates to:
  /// **'日本酒の詳細情報の取得に失敗しました'**
  String get errorSakeDetailFetch;

  /// No description provided for @noPreferenceConfigured.
  ///
  /// In ja, this message translates to:
  /// **'好みの設定が完了していません。好みを登録してからお試しください。'**
  String get noPreferenceConfigured;

  /// No description provided for @fastLabelScan.
  ///
  /// In ja, this message translates to:
  /// **'ラベルを撮る'**
  String get fastLabelScan;

  /// No description provided for @frontLabelScanTitle.
  ///
  /// In ja, this message translates to:
  /// **'正面ラベルを撮影'**
  String get frontLabelScanTitle;

  /// No description provided for @frontLabelScanDescription.
  ///
  /// In ja, this message translates to:
  /// **'ラベル全体がガイド枠に収まるように撮影してください。'**
  String get frontLabelScanDescription;

  /// No description provided for @backLabelScanTitle.
  ///
  /// In ja, this message translates to:
  /// **'裏ラベルを撮影'**
  String get backLabelScanTitle;

  /// No description provided for @backLabelScanDescription.
  ///
  /// In ja, this message translates to:
  /// **'商品名・製造者・容量などが読めるように裏ラベルを撮影してください。'**
  String get backLabelScanDescription;

  /// No description provided for @scanBackPromptTitle.
  ///
  /// In ja, this message translates to:
  /// **'裏ラベルを撮影しましょう'**
  String get scanBackPromptTitle;

  /// No description provided for @scanBackPromptOcrUnreadable.
  ///
  /// In ja, this message translates to:
  /// **'正面ラベルの文字を認識できませんでした。商品名や製造者が読めるように、裏ラベルを撮影してください。'**
  String get scanBackPromptOcrUnreadable;

  /// No description provided for @scanBackPromptNoCatalogMatch.
  ///
  /// In ja, this message translates to:
  /// **'正面ラベルだけでは商品を特定できませんでした。商品名や製造者が書かれた裏ラベルを撮影してください。'**
  String get scanBackPromptNoCatalogMatch;

  /// No description provided for @scanBackPromptLowConfidence.
  ///
  /// In ja, this message translates to:
  /// **'正面ラベルの情報だけでは候補を絞り切れませんでした。確認のため裏ラベルを撮影してください。'**
  String get scanBackPromptLowConfidence;

  /// No description provided for @scanBackPromptAction.
  ///
  /// In ja, this message translates to:
  /// **'裏ラベルを撮影する'**
  String get scanBackPromptAction;

  /// No description provided for @captureLabel.
  ///
  /// In ja, this message translates to:
  /// **'ラベルを撮影'**
  String get captureLabel;

  /// No description provided for @closeUpMode.
  ///
  /// In ja, this message translates to:
  /// **'近接'**
  String get closeUpMode;

  /// No description provided for @selectFromGallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選ぶ'**
  String get selectFromGallery;

  /// No description provided for @searchingLabel.
  ///
  /// In ja, this message translates to:
  /// **'日本酒を照合しています…'**
  String get searchingLabel;

  /// No description provided for @isThisSake.
  ///
  /// In ja, this message translates to:
  /// **'この日本酒ですか？'**
  String get isThisSake;

  /// No description provided for @yesThisSake.
  ///
  /// In ja, this message translates to:
  /// **'はい、この日本酒です'**
  String get yesThisSake;

  /// No description provided for @showOtherCandidate.
  ///
  /// In ja, this message translates to:
  /// **'ほかの候補'**
  String get showOtherCandidate;

  /// No description provided for @wrongTakeBackLabel.
  ///
  /// In ja, this message translates to:
  /// **'違います・裏ラベルを撮る'**
  String get wrongTakeBackLabel;

  /// No description provided for @loadingSakeOverview.
  ///
  /// In ja, this message translates to:
  /// **'日本酒の情報を読み込んでいます…'**
  String get loadingSakeOverview;

  /// No description provided for @scanAiAnalyzing.
  ///
  /// In ja, this message translates to:
  /// **'基本情報が見つかりました。詳しい解析は続いています…'**
  String get scanAiAnalyzing;

  /// No description provided for @scanCompleted.
  ///
  /// In ja, this message translates to:
  /// **'日本酒を特定しました'**
  String get scanCompleted;

  /// No description provided for @finishScan.
  ///
  /// In ja, this message translates to:
  /// **'詳しく見る'**
  String get finishScan;

  /// No description provided for @scanNextBottle.
  ///
  /// In ja, this message translates to:
  /// **'次の一本'**
  String get scanNextBottle;

  /// No description provided for @scanCameraPermissionDenied.
  ///
  /// In ja, this message translates to:
  /// **'カメラの使用が許可されていません。端末の設定でカメラを許可するか、ギャラリーから画像を選択してください。'**
  String get scanCameraPermissionDenied;

  /// No description provided for @scanCameraUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'カメラを利用できません。ギャラリーから画像を選択してください。'**
  String get scanCameraUnavailable;

  /// No description provided for @retryScan.
  ///
  /// In ja, this message translates to:
  /// **'最初からやり直す'**
  String get retryScan;

  /// No description provided for @scanErrorCompression.
  ///
  /// In ja, this message translates to:
  /// **'画像を準備できませんでした。別の画像でもう一度お試しください。'**
  String get scanErrorCompression;

  /// No description provided for @scanErrorTimeout.
  ///
  /// In ja, this message translates to:
  /// **'通信がタイムアウトしました。通信環境を確認してください。'**
  String get scanErrorTimeout;

  /// No description provided for @scanErrorNoCandidates.
  ///
  /// In ja, this message translates to:
  /// **'候補の日本酒が見つかりませんでした。'**
  String get scanErrorNoCandidates;

  /// No description provided for @scanErrorSessionExpired.
  ///
  /// In ja, this message translates to:
  /// **'スキャンの有効期限が切れました。最初からお試しください。'**
  String get scanErrorSessionExpired;

  /// No description provided for @scanErrorRateLimited.
  ///
  /// In ja, this message translates to:
  /// **'リクエストが集中しています。少し待ってからお試しください。'**
  String get scanErrorRateLimited;

  /// No description provided for @scanErrorServer.
  ///
  /// In ja, this message translates to:
  /// **'サーバーで問題が発生しました。時間をおいてお試しください。'**
  String get scanErrorServer;

  /// No description provided for @scanErrorAi.
  ///
  /// In ja, this message translates to:
  /// **'AI解析に失敗しました。時間をおいてお試しください。'**
  String get scanErrorAi;

  /// No description provided for @scanErrorGeneric.
  ///
  /// In ja, this message translates to:
  /// **'ラベルのスキャンに失敗しました。もう一度お試しください。'**
  String get scanErrorGeneric;

  /// No description provided for @shareScannedSakeToTimeline.
  ///
  /// In ja, this message translates to:
  /// **'保存後にタイムラインへ公開する'**
  String get shareScannedSakeToTimeline;

  /// No description provided for @communityImpressions.
  ///
  /// In ja, this message translates to:
  /// **'この日本酒を飲んだ人の感想'**
  String get communityImpressions;

  /// No description provided for @communityImpressionCount.
  ///
  /// In ja, this message translates to:
  /// **'感想 {count}件'**
  String communityImpressionCount(int count);

  /// No description provided for @recentPublicPosts.
  ///
  /// In ja, this message translates to:
  /// **'最近の公開投稿'**
  String get recentPublicPosts;

  /// No description provided for @sameBrandSakes.
  ///
  /// In ja, this message translates to:
  /// **'同じ銘柄の日本酒'**
  String get sameBrandSakes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
