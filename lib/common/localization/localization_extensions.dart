import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

extension LocalizationBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizeLegacyMessage(AppLocalizations l10n, String message) {
  final normalized = message.trim();
  return switch (normalized) {
    'メールアドレスを入力してください。' => l10n.errorEnterEmail,
    'パスワードを入力してください。' => l10n.errorEnterPassword,
    'パスワードは6文字以上で入力してください。' => l10n.errorPasswordLength,
    'メールアドレスの形式が正しくありません。' => l10n.errorInvalidEmail,
    'メールアドレスまたはパスワードが正しくありません。' => l10n.errorInvalidCredential,
    '該当するユーザーが見つかりません。登録済みかご確認ください。' => l10n.errorUserNotFound,
    'パスワードが正しくありません。' => l10n.errorInvalidCredential,
    'このメールアドレスは既に使用されています。' => l10n.errorEmailInUse,
    'より複雑なパスワードを設定してください。' => l10n.errorWeakPassword,
    'リクエストが集中しています。少し時間をおいてから再度お試しください。' => l10n.errorTooManyRequests,
    'ログインに失敗しました。通信環境をご確認のうえ再度お試しください。' => l10n.errorSignInFailed,
    '登録に失敗しました。時間をおいて再度お試しください。' => l10n.errorSignUpFailed,
    '確認メールの送信に失敗しました。時間をおいて再度お試しください。' => l10n.errorVerificationEmailFailed,
    'メールの送信に失敗しました。通信環境をご確認のうえ再度お試しください。' => l10n.errorEmailSendFailed,
    'ログアウトに失敗しました。時間をおいて再度お試しください。' => l10n.errorSignOutFailed,
    'このメールアドレスは利用できません。別のメールアドレスでお試しください。' => l10n.errorUserDisabled,
    '安全のため再ログインが必要です。ログアウト後に再度ログインしてお試しください。' => l10n.errorRecentLoginRequired,
    'ログイン状態を確認できませんでした。再度ログインしてお試しください。' => l10n.errorLoginStateUnavailable,
    '認証に失敗しました。通信環境をご確認のうえ再度お試しください。' => l10n.errorAuthenticationFailed,
    'サーバー上のアカウント削除に失敗しました。時間をおいて再度お試しください。' => l10n.errorAccountDeletion,
    'アカウント削除に失敗しました。時間をおいて再度お試しください。' => l10n.errorAccountDeletion,
    '確認メールを送信しました。迷惑メールもご確認ください。メール内のリンクから認証を完了し、再度ログインしてください。' =>
      l10n.verificationEmailSent,
    'パスワード再設定用のメールを送信しました。' => l10n.passwordResetEmailSent,
    '日本酒名を入力してください' => l10n.errorEnterSakeName,
    '日本酒情報が見つかりませんでした' => l10n.errorSakeNotFound,
    '日本酒情報の取得に失敗しました' => l10n.errorSakeFetch,
    '解析に使用する画像が見つかりませんでした' => l10n.errorImageNotFound,
    '日本酒情報の抽出に失敗しました' => l10n.errorMenuExtraction,
    '日本酒情報を抽出できませんでした' => l10n.errorNoSakeExtracted,
    '日本酒の詳細情報の取得に失敗しました' => l10n.errorSakeDetailFetch,
    '好みの設定が完了していません。好みを登録してからお試しください。' => l10n.noPreferenceConfigured,
    'ログインしました。' => l10n.loginCompleted,
    'ログアウトしました。' => l10n.logoutCompleted,
    'アカウントを削除しました。' => l10n.accountDeleted,
    'ニックネームを更新しました。' => l10n.nicknameUpdated,
    '自分の投稿を表示するにはログインしてください。' => l10n.ownPostsLoginRequired,
    '認証の有効期限が切れました。再度ログインしてください。' => l10n.sessionExpired,
    'タイムラインを表示するにはログインしてください。' => l10n.timelineLoginRequired,
    'データの取得に失敗しました。通信環境をご確認ください。' => l10n.dataFetchFailed,
    'ランキングを取得できませんでした。時間をおいて再度お試しください。' => l10n.rankingFetchFailed,
    '未分析の酒瓶' => l10n.unanalyzedBottle,
    '画像の選択に失敗しました' => l10n.errorSelectImage,
    '酒瓶画像の保存に失敗しました' => l10n.errorSaveBottleImage,
    '酒瓶画像の読み込みに失敗しました' => l10n.errorLoadBottleImages,
    '酒瓶画像の削除に失敗しました' => l10n.errorDeleteBottleImage,
    '不明な日本酒' => l10n.unknownSake,
    '解析中' => l10n.processing,
    _ => _localizeLegacyPrefix(l10n, normalized),
  };
}

String _localizeLegacyPrefix(AppLocalizations l10n, String message) {
  if (message.startsWith('日本酒情報の抽出に失敗しました:')) {
    return l10n.errorMenuExtraction;
  }
  if (message.startsWith('エラーが発生しました')) {
    return l10n.errorGeneric;
  }
  if (message.startsWith('画像の選択に失敗しました')) {
    return l10n.errorSelectImage;
  }
  if (message.startsWith('酒瓶画像の保存に失敗しました')) {
    return l10n.errorSaveBottleImage;
  }
  if (message.startsWith('酒瓶画像の読み込みに失敗しました')) {
    return l10n.errorLoadBottleImages;
  }
  if (message.startsWith('酒瓶画像の削除に失敗しました')) {
    return l10n.errorDeleteBottleImage;
  }
  return message;
}
