// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'SAKEPEDIA';

  @override
  String get navigationSearch => '検索';

  @override
  String get navigationMenuAnalysis => 'メニュー解析';

  @override
  String get navigationTimeline => 'タイムライン';

  @override
  String get navigationMyPage => 'マイページ';

  @override
  String get searchPageTitle => '日本酒検索';

  @override
  String get menuSearchPageTitle => 'メニュー検索';

  @override
  String get preferenceSearchPageTitle => '好みで検索';

  @override
  String get helpGuide => '使い方ガイド';

  @override
  String get back => '戻る';

  @override
  String get next => '次へ';

  @override
  String get done => '完了';

  @override
  String get mainSearchHelpTitle => '日本酒検索の使い方';

  @override
  String get menuSearchHelpTitle => 'メニュー検索の使い方';

  @override
  String get myPageHelpTitle => 'マイページの使い方';

  @override
  String get helpBottleFlowTitle => '酒瓶検索の流れ';

  @override
  String get helpBottleFlowDescription =>
      '酒瓶検索タブではカメラボタンから写真を撮影・選択できます。AIがラベルを解析し、日本酒情報を自動で取得します。解析した日本酒は保存ボタンでマイページに追加できます。';

  @override
  String get helpAfterAnalysisTitle => '解析が終わったら';

  @override
  String get helpAfterAnalysisDescription =>
      '銘柄名を入力して「解析だけ」を押すと蔵元や味わいなどの詳細が表示されます。お気に入りや保存を活用して、自分だけのリストを作りましょう。';

  @override
  String get helpMenuCaptureTitle => 'メニューを撮影・アップロード';

  @override
  String get helpMenuCaptureDescription =>
      'メニュー検索タブでは飲食店のメニュー写真をアップロードすると、写っている日本酒を自動でリスト化します。解析が終わるまで画面はそのままお待ちください。';

  @override
  String get helpMenuResultTitle => '解析結果をチェック';

  @override
  String get helpMenuResultDescription =>
      '解析で取得した日本酒をタップすると蔵元や味わい、おすすめ度が表示されます。ハートでお気に入り登録、しおりでマイページに保存して飲み比べメモに活用しましょう。';

  @override
  String get helpSavedListTitle => '保存した日本酒を一覧で確認';

  @override
  String get helpSavedListDescription =>
      'マイページには保存した日本酒やお気に入りがまとまります。タイルをタップすると詳細やメモ、写真を編集できます。';

  @override
  String get helpPreferenceAnalysisTitle => 'お気に入りから好みを解析';

  @override
  String get helpPreferenceAnalysisDescription =>
      '「お気に入り」の日本酒を元にAIがあなたの好みを解析します。解析した傾向は自分で変更することもできます。';

  @override
  String get termsTitle => 'SAKEPEDIA利用規約';

  @override
  String get termsAiUsage =>
      'SAKEPEDIAはGoogle LLCおよびOpenAI社が提供するAIを利用した日本酒特化型のアプリです。以下の内容に抵触する場合サービスがご利用いただけなくなる場合があります。\n\n・不必要な回数のリクエストを送る\n・生成されたデータの商用利用\n・その他Google LLCやOpenAI社が定める規約の違反';

  @override
  String get termsAiDisclaimer =>
      'また、利用するAIの状況によっては応答しない、誤情報、信憑性が疑わしい情報が回答されるなどが発生する可能性がありますが、ユーザーの不都合について開発陣は一切の責任を負いません。ご了承ください。';

  @override
  String get termsAccount =>
      '本サービスではメールアドレスとパスワードによるログインを採用しており、不正利用が疑われる場合には機能の制限またはご利用を停止させていただくことがあります。';

  @override
  String get termsContentPolicy =>
      'ユーザーは以下のような不適切な写真や情報を投稿できません。\n\n・人物が写っている写真\n・暴力、脅迫、差別、ハラスメントなどの表現\n・性的内容（アルコール関連を除く）\n・著作権その他の知的財産権を侵害する内容\n・その他、当社が不適切と判断する内容\n\n本アプリではAIによって酒瓶以外の写真は投稿できない仕組みを採用していますが、不適切な投稿が確認された場合は投稿の非表示や削除を行うことがあります。';

  @override
  String get termsServiceAvailability =>
      '運営上の都合により予告なくサービスを停止・終了する場合があり、その際はサーバーに保存された解析画像や各種データが消去されることがあります。重要なデータは必ずご自身でも保管してください。';

  @override
  String get termsClosing => '以上をご承諾の上、SAKEPEDIAを楽しく使っていただけたらと思います。';

  @override
  String get sakeTrivia => 'SAKE豆知識';

  @override
  String get triviaLoadFailed => '豆知識の読み込みに失敗しました';

  @override
  String get triviaQuestionFallback => 'この豆知識って何？';

  @override
  String get triviaTailOne => '覚えておくと注文のときにちょっと通っぽく語れるんだ。';

  @override
  String get triviaTailTwo => '知っているとペアリングの幅がぐっと広がるんだよね。';

  @override
  String get triviaTailThree => '友だちに披露すると話のタネとして盛り上がるよ。';

  @override
  String get triviaTailFour => '蔵見学や試飲会で自信を持って語れる小ネタなんだ。';

  @override
  String get triviaTailFive => '頭の片隅に入れておくと日本酒選びがもっと楽しくなるんだ。';

  @override
  String get everyoneSake => 'みんなの日本酒';

  @override
  String get publicTimelineEmpty =>
      'まだタイムラインには保存酒がありません。\nほかのユーザーが保存するとここに表示されます。';

  @override
  String get myPosts => '自分の投稿';

  @override
  String get myPostsEmpty => 'まだタイムラインに公開した投稿がありません。\nお気に入りのお酒をシェアしてみましょう。';

  @override
  String get understood => '了解';

  @override
  String get envyTutorialTitle => '「うらやま」を送ってみよう';

  @override
  String get envyTutorialDescription =>
      '気になった羨ましい日本酒に気軽Goodを送ろう！\n匿名だから気にせずどんどん押してね。';

  @override
  String get timelineLoginTitle => 'ログインでさらに楽しもう';

  @override
  String get timelineLoginMessage => 'タイムラインから保存・お気に入り・うらやま・報告するにはログインが必要です。';

  @override
  String get rankingLoginMessage => 'ランキングからうらやまを送るにはログインが必要です。';

  @override
  String get dataFetchFailed => 'データの取得に失敗しました。通信環境をご確認ください。';

  @override
  String get reload => '再読み込み';

  @override
  String get envySent => 'うらやまを送信しました！';

  @override
  String get envySendFailed => 'うらやまの送信に失敗しました。通信環境をご確認ください。';

  @override
  String get envyAlready => 'すでにうらやま済みです！';

  @override
  String get reportAccepted => 'ありがとうございました。報告を受け付けました。';

  @override
  String get reportAlready => 'この投稿は既に報告済みです。';

  @override
  String get reportFailed => '報告に失敗しました。通信環境をご確認ください。';

  @override
  String get refresh => '更新';

  @override
  String get envyRankingTitle => '羨ましい日本酒ランキング';

  @override
  String get envyRankingSubtitle => 'うらやまが多い投稿ベスト20をチェック';

  @override
  String tasteLabel(String taste) {
    return '味わい: $taste';
  }

  @override
  String get readMore => '続きを読む';

  @override
  String get anonymousUser => '名無しユーザー';

  @override
  String get reportPostTitle => '投稿を報告しますか？';

  @override
  String get reportPostDescription => '問題のある投稿として運営に報告します。よろしいですか？';

  @override
  String get no => 'いいえ';

  @override
  String get yes => 'はい';

  @override
  String get rankingEmpty => 'まだランキングを表示できる投稿がありません。';

  @override
  String get rankingFetchFailed => 'ランキングを取得できませんでした。時間をおいて再度お試しください。';

  @override
  String get ownPostsLoginRequired => '自分の投稿を表示するにはログインしてください。';

  @override
  String get sessionExpired => '認証の有効期限が切れました。再度ログインしてください。';

  @override
  String get timelineLoginRequired => 'タイムラインを表示するにはログインしてください。';

  @override
  String get preferenceSweet => '甘口';

  @override
  String get preferenceDry => '辛口';

  @override
  String get preferenceClean => 'スッキリ';

  @override
  String get preferenceFruity => 'フルーティ';

  @override
  String get preferenceNigori => 'にごり';

  @override
  String get preferenceSparkling => '微発泡';

  @override
  String get preferenceAcidic => '酸味';

  @override
  String get favoriteSakeQuestion => 'どんな日本酒が好き？';

  @override
  String get selectPreferenceFeatures => '好みの特徴を選んでください（複数選択可）';

  @override
  String get selectAtLeastOne => '少なくとも1つは選択してください';

  @override
  String get preferencesChangeAnytime => 'マイページからいつでも変更できます！';

  @override
  String betaVersion(String version) {
    return 'ベータ版 $version';
  }

  @override
  String get bottleListClosingNotice => 'こちらの機能は保存酒とかぶってきたためひっそりとクローズ予定です。';

  @override
  String get noBottleImages => '保存された酒瓶画像はありません';

  @override
  String get captureBottleHint => '酒瓶検索で画像を撮影してみましょう';

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String get unknownSake => '不明な酒';

  @override
  String capturedDate(String date) {
    return '撮影日: $date';
  }

  @override
  String get deleteBottleImageTitle => '画像を削除';

  @override
  String get deleteBottleImageDescription => 'この酒瓶画像を削除してもよろしいですか？';

  @override
  String get errorSelectImage => '画像の選択に失敗しました';

  @override
  String get unanalyzedBottle => '未分析の酒瓶';

  @override
  String get errorSaveBottleImage => '酒瓶画像の保存に失敗しました';

  @override
  String get errorLoadBottleImages => '酒瓶画像の読み込みに失敗しました';

  @override
  String get errorDeleteBottleImage => '酒瓶画像の削除に失敗しました';

  @override
  String get axisFruity => 'フルーティ';

  @override
  String get axisCalm => '穏やか';

  @override
  String get axisSweetness => '甘味';

  @override
  String get axisDry => '辛口';

  @override
  String get axisSweet => '甘口';

  @override
  String get axisAcidity => '酸味';

  @override
  String get axisLowAcid => '低酸';

  @override
  String get axisHighAcid => '高酸';

  @override
  String get axisUmami => '旨味';

  @override
  String get axisLight => '淡麗';

  @override
  String get axisRich => '濃醇';

  @override
  String get axisFinish => 'キレ';

  @override
  String get axisMellow => 'まろやか';

  @override
  String get axisSharp => 'シャープ';

  @override
  String get axisSpiciness => '辛さ';

  @override
  String get axisGentle => '穏やか';

  @override
  String get axisKick => 'ピリッ';

  @override
  String get tasteTrendSample => '好きなお酒の傾向（サンプル表示）';

  @override
  String get tasteTrend => '好きなお酒の傾向';

  @override
  String get tasteTrendSampleDescription =>
      'お気に入りデータがそろったら、あなた専用のチャートをここに表示します。';

  @override
  String get tasteTrendDescription =>
      'お気に入りの日本酒から算出した平均傾向です。あくまでAIの解析なのでお手柔らかに。';

  @override
  String get signedInUsersOnly => 'ログインユーザー限定';

  @override
  String get tasteChartLoginDescription =>
      'お気に入りの日本酒から傾向チャートを自動生成します。ログインして自分専用の分析を確認しましょう。';

  @override
  String get loginToViewChart => 'ログインしてチャートを見る';

  @override
  String get sakeDiagnosisTitle => 'あなたにぴったりのお酒診断';

  @override
  String get tasteChartUpdated => '味覚チャートを更新しました！\nお気に入りを増やすとさらに精度が上がります。';

  @override
  String get sakeDiagnosisFailed => 'お気に入りのお酒から診断できませんでした。別のお酒を登録してみてください。';

  @override
  String get savePreferenceAndClose => '好きな傾向に保存して閉じる';

  @override
  String get badges => 'バッジ';

  @override
  String get achievementWelcomeTitle => 'ウェルカム乾杯';

  @override
  String get achievementWelcomeDescription => 'たくさん利用してバッジを集めましょう';

  @override
  String get achievementBottleTitle => 'ボトルマスター';

  @override
  String get achievementBottleDescription => '酒瓶解析で日本酒の知識を深めよう';

  @override
  String get achievementEnvyTitle => 'うらやまコレクター';

  @override
  String get achievementEnvyDescription => 'うらやまを集めて注目の的になろう';

  @override
  String get badgeComplete => 'コンプリート！バッジを獲得しました';

  @override
  String badgeRemaining(int count) {
    return 'あと$count回で次のバッジ';
  }

  @override
  String get badgeStart => 'まずは最初の挑戦から始めてみましょう';

  @override
  String get goldBadge => 'ゴールドバッジ';

  @override
  String get silverBadge => 'シルバーバッジ';

  @override
  String get bronzeBadge => 'ブロンズバッジ';

  @override
  String get badgeNotEarned => '未獲得';

  @override
  String get totalEnvyPoints => '累計うらやまポイント';

  @override
  String get collectEnvy => 'うらやまを集めよう';

  @override
  String envyEarnedCount(int count) {
    return 'これまでに $count 件のうらやまを獲得しています';
  }

  @override
  String get envyShareHint => 'タイムラインで共有すると仲間からうらやまが届きます';

  @override
  String get everyonePraises => 'みんなが賞賛！';

  @override
  String get tryCollecting => '集めてみよう';

  @override
  String get timelineIntroTitle => 'タイムラインへようこそ';

  @override
  String get timelineIntroDescription =>
      'みんなが飲んだお酒がここにずらり。\n気になる一杯は保存して、あなただけのリストに加えましょう！';

  @override
  String get timelineIntroEnvyHint => 'うらやましい日本酒は気軽に👍ボタンしてあげよう。';

  @override
  String get timelinePublishingTitle => 'タイムラインへの掲載について';

  @override
  String get timelinePublishingDescription =>
      'タイムラインで表示されるのは日本酒情報と1枚目の写真だけです。あなたの感想やメモなどは表示されません。ぜひみんなが日本酒を知る機会にご協力ください。';

  @override
  String get continueAnalysis => 'このまま解析';

  @override
  String get removeCheck => 'チェックを外す';

  @override
  String get loginToToggleAutoPost => 'ログインすると自動投稿を切り替えられます。';

  @override
  String get autoPostUpdateFailed => '自動投稿の更新に失敗しました。時間をおいて再試行してください。';

  @override
  String autoPostUpdated(String status) {
    return 'Xへの自動投稿を$statusにしました。';
  }

  @override
  String get statusOn => 'オン';

  @override
  String get statusOff => 'オフ';

  @override
  String get autoPostDialogTitle => 'Xへの自動投稿について';

  @override
  String get autoPostDialogDescription =>
      'この画像と解析結果だけがツイートされます。\n日本酒を広めるためにご協力お願いします。';

  @override
  String get continuePosting => 'このまま投稿する';

  @override
  String get disableAutoPost => '自動投稿をオフにする';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get languageSystem => '端末の設定に従う';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageEnglish => 'English';

  @override
  String get termsOfUse => '利用規約';

  @override
  String get developer => '開発会社';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get saveAction => '保存する';

  @override
  String get apply => '適用する';

  @override
  String get clearFilters => '絞り込みを解除';

  @override
  String get search => '検索';

  @override
  String get close => '閉じる';

  @override
  String get unknown => '不明';

  @override
  String get unknownName => '名称不明';

  @override
  String get updateRequiredMessage =>
      'ご利用ありがとうございます。現在のバージョンではご利用いただけないため、ストアからアプリをアップデートしてください。';

  @override
  String get openAppStore => 'App Storeを開く';

  @override
  String get openPlayStore => 'Google Playを開く';

  @override
  String get welcomeTitle => 'Sakepediaにようこそ！';

  @override
  String get welcomeDescription =>
      'メールアドレスでログインしておくと、保存酒やお気に入りを端末間で同期できます。ログイン後に届く確認メールから認証を完了してください。';

  @override
  String get welcomeFree => 'もちろん無料で利用可能';

  @override
  String get welcomeBackup => '保存酒やお気に入りを自動バックアップ';

  @override
  String get welcomeMoreStorage => '保存できるお酒が増える！';

  @override
  String get loginOrRegisterWithEmail => 'メールアドレスでログイン・登録';

  @override
  String get continueAsGuest => '今はログインせずに使う';

  @override
  String get loginLaterHint => 'あとからマイページでもログインできます。';

  @override
  String get loginBenefitsTitle => 'ログインでさらに便利に';

  @override
  String get loginBenefitsDescription =>
      '登録なしでも利用できますが、ログインすると保存数が増え、保存酒リストのバックアップや端末間同期が利用できます。';

  @override
  String get userFallbackName => 'ユーザー';

  @override
  String get signedIn => 'ログイン中';

  @override
  String helloUser(String name) {
    return 'こんにちは$nameさん！';
  }

  @override
  String get authPageTitle => 'メールアドレスでログイン・登録';

  @override
  String get signIn => 'ログイン';

  @override
  String get signUp => '新規登録';

  @override
  String get signInAction => 'ログインする';

  @override
  String get signUpAction => '登録する';

  @override
  String get signInDescription =>
      '登録済みのメールアドレスとパスワードでログインします。パスワードを忘れた場合は再設定メールを送信できます。';

  @override
  String get signUpDescription =>
      'メールアドレスとパスワードを設定してアカウントを作成できます。登録後は同じ情報でログインできます。';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get confirmPassword => 'パスワード（確認用）';

  @override
  String get forgotPassword => 'パスワードをお忘れの方はこちら';

  @override
  String get guestUseAvailable => '登録しなくてもアプリをご利用いただけます。';

  @override
  String get passwordMismatch => '確認用パスワードが一致しません。';

  @override
  String get passwordResetSent => 'パスワード再設定メールを送信しました。迷惑メールフォルダもご確認ください。';

  @override
  String get verificationEmailSent =>
      '確認メールを送信しました。迷惑メールもご確認ください。メール内のリンクから認証を完了し、再度ログインしてください。';

  @override
  String get passwordResetEmailSent => 'パスワード再設定用のメールを送信しました。';

  @override
  String get loginCompleted => 'ログインしました。';

  @override
  String get logoutCompleted => 'ログアウトしました。';

  @override
  String get accountDeleted => 'アカウントを削除しました。';

  @override
  String get nicknameUpdated => 'ニックネームを更新しました。';

  @override
  String get accountSettings => 'アカウント設定';

  @override
  String get notSet => '未設定';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get nicknameHint => '例）日本酒好き太郎';

  @override
  String get saveNickname => 'ニックネームを保存';

  @override
  String get errorEnterNickname => 'ニックネームを入力してください。';

  @override
  String get errorNicknameLength => 'ニックネームは10文字以内で入力してください。';

  @override
  String get errorNicknameUpdate => 'ニックネームの更新に失敗しました。時間をおいて再度お試しください。';

  @override
  String get updating => '更新中...';

  @override
  String get changeIcon => 'アイコンを変更';

  @override
  String get iconUpdated => 'アイコンを更新しました。';

  @override
  String get errorIconUpdate => 'アイコンの更新に失敗しました。時間をおいて再度お試しください。';

  @override
  String get selectFromPhotoLibrary => 'フォトライブラリから選択';

  @override
  String get emailChangeUnavailable => '※ 現在アプリ内でメールアドレスの変更はできません。';

  @override
  String get signingOut => 'ログアウト中...';

  @override
  String get signOut => 'ログアウト';

  @override
  String get accountDeletion => 'アカウント削除';

  @override
  String get accountDeletionConfirmation => 'アカウント削除の確認';

  @override
  String get accountDeletionWarning =>
      'アカウントを削除すると、保存酒・お気に入り・嗜好設定などのデータはすべて削除されます。削除後は元に戻せません。';

  @override
  String get accountDeletionWarningShort =>
      'アカウントを削除すると、保存酒・お気に入り・嗜好設定などのデータはすべて削除されます。';

  @override
  String get enterPasswordToConfirm => '確認のため、パスワードを入力してください。';

  @override
  String get deleteAction => '削除する';

  @override
  String get deleteAccountAction => 'アカウントを削除する';

  @override
  String get nameSearch => '名前で検索';

  @override
  String get bottleSearch => '酒瓶検索';

  @override
  String get sakeName => '日本酒名';

  @override
  String get enterSakeName => '日本酒名を入力';

  @override
  String get sakeType => '種類';

  @override
  String get enterOptionalSakeType => '種類を入力（任意）';

  @override
  String get selectBottleImage => '日本酒のラベルや瓶の画像を選択してください';

  @override
  String get tapToSelectImage => 'タップして画像を選択';

  @override
  String get takePhoto => 'カメラで撮影';

  @override
  String get shareToTimeline => 'タイムラインにも表示する';

  @override
  String get onlyFirstImageShared => '画像は1枚目だけ共有されます。';

  @override
  String get autoPostToX => 'Xに自動投稿';

  @override
  String get autoPostToXDescription => '解析完了時に結果をXにも自動投稿します。';

  @override
  String get loginToChangeSetting => 'ログインすると設定を変更できます。';

  @override
  String get loadingAutoPostSetting => '自動投稿の設定を取得中です...';

  @override
  String get updatingSetting => '設定を更新中...';

  @override
  String get analyzeAndSave => '解析して保存';

  @override
  String get analyzeOnly => '解析だけ';

  @override
  String get analyzingWithAd => '解析中...広告の表示にご協力ください...';

  @override
  String get loadingSakeInfo => '日本酒情報を取得しています...';

  @override
  String get aiAnalysisResult => 'AIの解析結果';

  @override
  String get tryBackLabelHint => '裏のラベルなら解析できるかもしれません。';

  @override
  String get saveSake => '保存';

  @override
  String get removeSavedSake => '保存を解除';

  @override
  String get savedToMyPage => 'マイページに保存しました！';

  @override
  String get favorite => 'お気に入り';

  @override
  String get removeFavorite => 'お気に入り解除';

  @override
  String get unknownType => '種類不明';

  @override
  String get loadingDetails => '詳細情報を取得中...';

  @override
  String get detailsUnavailable => '詳細情報を取得できませんでした';

  @override
  String get expand => '展開';

  @override
  String get highlyRecommended => '超おすすめ！';

  @override
  String get recommended => 'おすすめ！';

  @override
  String get goodSake => '良い日本酒';

  @override
  String get characteristics => '特徴';

  @override
  String get brewery => '蔵元';

  @override
  String get sakeMeterValue => '日本酒度';

  @override
  String get searchByType => 'タイプ別検索';

  @override
  String get sweet => '甘口';

  @override
  String get dry => '辛口';

  @override
  String get savedSake => '保存酒';

  @override
  String get savedSakeEmpty => '保存した日本酒はまだありません。';

  @override
  String get savedSakeEmptyHint => 'まだ保存したお酒はありません。\nメニュー検索からブックマークしてみましょう！';

  @override
  String get sort => '並び替え';

  @override
  String get gridView => 'グリッド表示';

  @override
  String get listView => 'リスト表示';

  @override
  String get filterByTag => 'タグで絞り込む';

  @override
  String get noAvailableTags => '利用可能なタグがまだありません。';

  @override
  String savedSakeLimit(int count) {
    return '保存酒は$count件まで保存できます。不要な保存酒を削除してください。';
  }

  @override
  String removedFromSaved(String name) {
    return '$name を保存リストから削除しました';
  }

  @override
  String get bottleList => '酒瓶リスト';

  @override
  String get sakeDetails => '日本酒詳細';

  @override
  String get price => '価格';

  @override
  String get recommendationScore => 'おすすめ度';

  @override
  String get tasteAndFeatures => 'テイスト・特徴';

  @override
  String get description => '説明';

  @override
  String get basicInformation => '基本情報';

  @override
  String get noDetailedInformation => '詳細情報が登録されていません。';

  @override
  String get processing => '処理中…';

  @override
  String savedDate(String date) {
    return '保存日 $date';
  }

  @override
  String get syncedToServer => 'サーバーに保存済み';

  @override
  String get localOnly => '未同期（この端末にのみ保存されています）';

  @override
  String get notSynced => '未同期';

  @override
  String consumedAt(String place) {
    return '飲んだ場所: $place';
  }

  @override
  String get noMatchingTags => '選択中のタグに該当するお酒がありません。';

  @override
  String get syncToServer => 'サーバーへ同期';

  @override
  String get manualNameSearchHint => '名前を手動で検索可能です';

  @override
  String get syncToChangeVisibility => 'サーバーに同期するとタイムライン公開を切り替えられます。';

  @override
  String get loginToChangeVisibility => 'ログインすると公開設定を変更できます。';

  @override
  String get visibilityChangeHint => 'タイムラインへの公開／非公開をいつでも切り替えられます。';

  @override
  String get showOnTimeline => 'タイムラインに表示する';

  @override
  String get reanalyze => '再解析';

  @override
  String get change => '変更';

  @override
  String get loginToReanalyze => 'ログインすると再解析できます';

  @override
  String get loginToReanalyzeAfterRename => 'ログインすると名前変更後に再解析できます';

  @override
  String get memo => 'メモ';

  @override
  String get memoFilterHint => '設定しておくと一覧でフィルタリングできます。';

  @override
  String get impressionLabel => '感想（200文字まで）';

  @override
  String get impressionHint => '味わいや香りの印象を記録しましょう';

  @override
  String get placeConsumed => '飲んだ場所';

  @override
  String get placeConsumedHint => 'お店やイベント名などを記録できます';

  @override
  String get saveMemories => '思い出も残そう';

  @override
  String get recordPrompt => 'このお酒の記録を残しませんか？';

  @override
  String get add => '追加';

  @override
  String get maxThreeImages => '画像は最大3枚までです';

  @override
  String get syncToAddImages => 'サーバー同期をすると画像を追加できます';

  @override
  String get memoSaved => 'メモを保存しました';

  @override
  String get savingToServer => 'サーバーに保存中…';

  @override
  String get savedToServer => 'サーバーに保存しました';

  @override
  String get errorSaveToServer => 'サーバーへの保存に失敗しました。通信環境をご確認ください。';

  @override
  String get errorEnterSakeNameDetail => '日本酒の名前を入力してください';

  @override
  String get noChanges => '変更された内容がありません';

  @override
  String get nameSaved => '名前を保存しました';

  @override
  String get reanalyzing => '再解析中…';

  @override
  String get reanalyzeCompleted => '再解析が完了しました';

  @override
  String get errorReanalyze => '再解析に失敗しました。通信環境をご確認のうえ再度お試しください。';

  @override
  String get syncingWithServer => 'サーバーと同期中…';

  @override
  String get syncedWithServer => 'サーバーと同期しました！';

  @override
  String get errorSync => '同期に失敗しました。通信環境をご確認のうえ再度お試しください。';

  @override
  String get imageAdded => '画像を追加しました';

  @override
  String get deleteImageConfirmation => '画像を削除しますか？';

  @override
  String get deleteImageDescription => 'この画像をリストから削除します。';

  @override
  String get deleteImage => '画像を削除';

  @override
  String get imageDeleted => '画像を削除しました';

  @override
  String get errorImageAdd => '画像の追加に失敗しました';

  @override
  String get errorImageDelete => '画像の削除に失敗しました';

  @override
  String get addedToFavorites => 'お気に入りに追加しました';

  @override
  String get removedFromFavoritesToast => 'お気に入りから削除しました';

  @override
  String get missingSavedIdReanalyze => '保存IDが未設定のため再解析は利用できません';

  @override
  String get syncBeforeVisibility => 'サーバーに同期するとタイムライン公開を設定できます';

  @override
  String get errorVisibilityUpdate => '公開設定の更新に失敗しました。通信環境をご確認ください。';

  @override
  String get publishedToTimeline => 'タイムラインに公開しました';

  @override
  String get hiddenFromTimeline => 'タイムラインでの表示をオフにしました';

  @override
  String get missingSavedIdServerSave => '保存IDが未設定のためサーバー保存はできません';

  @override
  String get loginForServerReanalyze => 'ログインするとサーバー再解析を利用できます';

  @override
  String get savedIdNotFound => '保存IDが見つかりませんでした';

  @override
  String get syncableSavedIdNotFound => '同期できる保存IDが見つかりませんでした。';

  @override
  String get savedInformationNotFound => '保存情報が見つかりません';

  @override
  String get favoriteSake => 'お気に入りのお酒';

  @override
  String get favoriteEmpty => 'まだお気に入りはありません。\n日本酒を検索して♡マークを押してみましょう！';

  @override
  String removedFromFavorites(String name) {
    return '$name をお気に入りから削除しました';
  }

  @override
  String get favoriteDiagnosis => 'あなたにぴったりのお酒診断';

  @override
  String get diagnosisDailyLimit => '診断は1日に3回までです。時間をおいてお試しください。';

  @override
  String get needMoreFavorites => 'もう少しお気に入りのお酒を登録してください。';

  @override
  String get tastePreferences => '好きなお酒の傾向';

  @override
  String get tastePreferencesDescription =>
      '好みのお酒の特徴を入力すると、おすすめの日本酒を探しやすくなります。';

  @override
  String get tastePreferencesHint => '例: 甘口でフルーティな香りが好きです。辛すぎるのは苦手です。';

  @override
  String get preferencesSaved => '好みを保存しました';

  @override
  String get menuPhotoDescription => 'メニューの写真をアップロードして日本酒を検索';

  @override
  String get searchSakeFromMenu => '日本酒を検索';

  @override
  String get detectedSake => '検出された日本酒';

  @override
  String get menuHistory => '解析履歴';

  @override
  String get noMenuHistory => '解析履歴はありません';

  @override
  String get pastMenuAnalysis => '過去のメニュー解析';

  @override
  String get deleteConfirmation => '削除の確認';

  @override
  String get deleteMenuHistoryConfirmation => 'この解析履歴を削除してもよろしいですか？';

  @override
  String get delete => '削除';

  @override
  String sakeCount(int count) {
    return '$count件の日本酒';
  }

  @override
  String get enterStoreName => '店舗名を入力';

  @override
  String get enterStoreNameHint => '店舗名を入力してください';

  @override
  String get preferenceSearchDescription => '産地や味わいから好きな日本酒を見つけよう！';

  @override
  String get searchByRegion => '産地で検索';

  @override
  String get continueInquiry => '続けて問い合わせる';

  @override
  String get flavorGroupOne => '味わい 1';

  @override
  String get flavorGroupTwo => '味わい 2';

  @override
  String get specificDesignation => '特定名称ほか';

  @override
  String get selectRegion => '産地を選択';

  @override
  String get region => '産地';

  @override
  String get flavor => '香り・印象';

  @override
  String get taste => '味わい';

  @override
  String get type => '種類';

  @override
  String get askAi => 'AIに質問';

  @override
  String get savedLimitTitle => '保存枠が上限に達しました';

  @override
  String savedLimitMessage(int count) {
    return '無料会員登録で保存枠が増えます。\n現在の保存上限は$count件です。\n解析前に会員登録すると無料で保存がもっとできます！';
  }

  @override
  String get favoriteLimitTitle => 'お気に入り枠が上限に達しました';

  @override
  String favoriteLimitMessage(int count) {
    return '無料会員登録でお気に入り枠が増えます。\n現在の上限は$count件です。\n会員登録するとお気に入りを無制限に登録できます！';
  }

  @override
  String get goToLoginOrRegister => 'ログイン・登録へ';

  @override
  String get adConfirmation => '広告視聴の確認';

  @override
  String get adFeatureDescription => '広告を視聴すると、特別な機能が利用できます。';

  @override
  String get searchAdDescription => '広告を視聴すると、日本酒情報を検索できます。広告の視聴にご協力ください。';

  @override
  String get bottleAdDescription => '広告を視聴すると、酒瓶を解析できます。続行しますか？';

  @override
  String get menuAdDescription => 'メニューから日本酒情報を解析するには広告の視聴が必要です。';

  @override
  String get searchCancelled => '検索をキャンセルしました。次回は広告視聴へのご協力をお願いします。';

  @override
  String get analysisCancelled => '解析をキャンセルしました。次回は広告視聴へのご協力をお願いします。';

  @override
  String get imageSaveFailed => '画像の保存に失敗しました';

  @override
  String get agree => '同意する';

  @override
  String get errorEnterEmail => 'メールアドレスを入力してください。';

  @override
  String get errorEnterPassword => 'パスワードを入力してください。';

  @override
  String get errorPasswordLength => 'パスワードは6文字以上で入力してください。';

  @override
  String get errorInvalidEmail => 'メールアドレスの形式が正しくありません。';

  @override
  String get errorInvalidCredential => 'メールアドレスまたはパスワードが正しくありません。';

  @override
  String get errorUserNotFound => '該当するユーザーが見つかりません。登録済みかご確認ください。';

  @override
  String get errorEmailInUse => 'このメールアドレスは既に使用されています。';

  @override
  String get errorWeakPassword => 'より複雑なパスワードを設定してください。';

  @override
  String get errorTooManyRequests => 'リクエストが集中しています。少し時間をおいてから再度お試しください。';

  @override
  String get errorSignInFailed => 'ログインに失敗しました。通信環境をご確認のうえ再度お試しください。';

  @override
  String get errorSignUpFailed => '登録に失敗しました。時間をおいて再度お試しください。';

  @override
  String get errorVerificationEmailFailed => '確認メールの送信に失敗しました。時間をおいて再度お試しください。';

  @override
  String get errorEmailSendFailed => 'メールの送信に失敗しました。通信環境をご確認のうえ再度お試しください。';

  @override
  String get errorSignOutFailed => 'ログアウトに失敗しました。時間をおいて再度お試しください。';

  @override
  String get errorUserDisabled => 'このメールアドレスは利用できません。別のメールアドレスでお試しください。';

  @override
  String get errorRecentLoginRequired =>
      '安全のため再ログインが必要です。ログアウト後に再度ログインしてお試しください。';

  @override
  String get errorLoginStateUnavailable => 'ログイン状態を確認できませんでした。再度ログインしてお試しください。';

  @override
  String get errorAuthenticationFailed => '認証に失敗しました。通信環境をご確認のうえ再度お試しください。';

  @override
  String get errorAccountDeletion => 'アカウント削除に失敗しました。時間をおいて再度お試しください。';

  @override
  String get errorGeneric => 'エラーが発生しました。お手数ですが再度お試しください。';

  @override
  String get errorEnterSakeName => '日本酒名を入力してください';

  @override
  String get errorSakeNotFound => '日本酒情報が見つかりませんでした';

  @override
  String get errorSakeFetch => '日本酒情報の取得に失敗しました';

  @override
  String get errorImageNotFound => '解析に使用する画像が見つかりませんでした';

  @override
  String get errorMenuExtraction => '日本酒情報の抽出に失敗しました';

  @override
  String get errorNoSakeExtracted => '日本酒情報を抽出できませんでした';

  @override
  String get errorSakeDetailFetch => '日本酒の詳細情報の取得に失敗しました';

  @override
  String get noPreferenceConfigured => '好みの設定が完了していません。好みを登録してからお試しください。';
}
