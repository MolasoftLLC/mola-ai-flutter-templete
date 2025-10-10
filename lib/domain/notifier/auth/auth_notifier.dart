import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:uni_links/uni_links.dart';

import '../../../config/firebase_auth_config.dart';
import '../../repository/auth_repository.dart';
import '../favorite/favorite_notifier.dart';
import '../my_page/my_page_notifier.dart';
import '../saved_sake/saved_sake_notifier.dart';
import '../../repository/sake_user_repository.dart';

part 'auth_notifier.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    User? user,
    @Default('') String email,
    @Default(false) bool isLoading,
    @Default(false) bool emailLinkSent,
    String? infoMessage,
    String? errorMessage,
  }) = _AuthState;
}

class AuthNotifier extends StateNotifier<AuthState> with LocatorMixin {
  AuthNotifier() : super(const AuthState()) {
    Future.microtask(_initialize);
  }

  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<Uri?>? _linkSubscription;

  AuthRepository get _repository => read<AuthRepository>();
  SakeUserRepository get _userRepository => read<SakeUserRepository>();

  Future<void> _initialize() async {
    final cachedEmail = await _repository.getCachedEmail();
    if (cachedEmail != null) {
      state = state.copyWith(email: cachedEmail);
    }

    _authSubscription = _repository.authStateChanges().listen((user) {
      final previousUser = state.user;
      state = state.copyWith(
        user: user,
        emailLinkSent: user != null ? false : state.emailLinkSent,
        infoMessage: previousUser != null && user == null
            ? 'ログアウトしました。'
            : state.infoMessage,
      );
      if (user != null) {
        unawaited(_handleUserSignedIn(user));
      } else if (previousUser != null) {
        unawaited(_handleUserSignedOut());
      }
    });

    await _handleInitialUri();
    _listenForIncomingUris();
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      dev.log('initialUri: $uri', name: 'AuthNotifier');
      await _handleUri(uri);
    } on Exception catch (error) {
      dev.log('Failed to get initial URI: $error', name: 'AuthNotifier');
      // 端末によって例外が投げられることがあるため握りつぶす
    }
  }

  void _listenForIncomingUris() {
    _linkSubscription = uriLinkStream.listen(
      (uri) async {
        dev.log('uriLinkStream: $uri', name: 'AuthNotifier');
        await _handleUri(uri);
      },
      onError: (error) {
        dev.log('uriLinkStream error: $error', name: 'AuthNotifier');
        state = state.copyWith(
          errorMessage: 'リンクの取得に失敗しました。再度お試しください。',
        );
      },
    );
  }

  static const _allowedHosts = {
    'sakepedia-5c50b.web.app',
    'sakepedia-5c50b.firebaseapp.com',
  };

  Future<void> _handleUri(Uri? uri) async {
    if (uri == null) {
      dev.log('Ignored URI: null', name: 'AuthNotifier');
      return;
    }

    String? emailLink;

    if (uri.scheme == 'https' && _allowedHosts.contains(uri.host)) {
      emailLink = uri.toString();
      if (uri.path.startsWith('/__/auth/links')) {
        final nestedLink = uri.queryParameters['link'];
        if (nestedLink != null && nestedLink.isNotEmpty) {
          emailLink = Uri.decodeComponent(nestedLink);
          dev.log('Normalized nested action link: $emailLink',
              name: 'AuthNotifier');
        }
      }
    } else if (uri.scheme == 'sakepediaauth') {
      final nestedLink = uri.queryParameters['link'];
      if (nestedLink == null || nestedLink.isEmpty) {
        dev.log('Custom scheme without link param: $uri', name: 'AuthNotifier');
        return;
      }
      emailLink = Uri.decodeComponent(nestedLink);
      dev.log('Normalized from custom scheme: $emailLink',
          name: 'AuthNotifier');
    } else {
      dev.log('Ignored URI (unsupported scheme/host): $uri',
          name: 'AuthNotifier');
      return;
    }

    if (emailLink == null) {
      dev.log('No email link extracted from $uri', name: 'AuthNotifier');
      return;
    }

    final isValidLink = _repository.isSignInWithEmailLink(emailLink);
    dev.log(
      'isSignInWithEmailLink=$isValidLink for $emailLink',
      name: 'AuthNotifier',
    );
    if (!isValidLink) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      infoMessage: null,
    );

    try {
      final cachedEmail = state.email.trim().isNotEmpty
          ? state.email.trim()
          : await _repository.getCachedEmail();

      if (cachedEmail == null || cachedEmail.isEmpty) {
        dev.log('Cached email not found when handling link',
            name: 'AuthNotifier');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'メールアドレスを再入力してからリンクを開いてください。',
        );
        return;
      }

      dev.log('Signing in with email link for $cachedEmail',
          name: 'AuthNotifier');
      await _repository.signInWithEmailLink(
        email: cachedEmail,
        emailLink: emailLink,
      );

      final user = _repository.currentUser;
      state = state.copyWith(
        isLoading: false,
        user: user,
        emailLinkSent: false,
        infoMessage: '認証が完了しました。',
      );
      if (user != null) {
        // authStateChanges リスナー側で同期処理を実施
      }
    } on FirebaseAuthException catch (e) {
      dev.log('FirebaseAuthException during link handling: ${e.code}',
          name: 'AuthNotifier');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateFirebaseError(e),
      );
    } catch (error) {
      dev.log('Unexpected error during link handling: $error',
          name: 'AuthNotifier');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'メールリンクの処理に失敗しました。時間をおいて再度お試しください。',
      );
    }
  }

  Future<void> sendEmailLink(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(
        errorMessage: 'メールアドレスを入力してください。',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      infoMessage: null,
    );

    try {
      final settings = FirebaseAuthConfig.emailLinkActionCodeSettings();
      await _repository.sendEmailLink(
        email: trimmedEmail,
        settings: settings,
      );
      state = state.copyWith(
        isLoading: false,
        email: trimmedEmail,
        emailLinkSent: true,
        infoMessage: '認証メールを送信しました。受信箱をご確認ください。迷惑メールBoxの確認もお願いします。',
      );
    } on StateError catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateFirebaseError(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'メール送信に失敗しました。通信環境をご確認のうえ再度お試しください。',
      );
    }
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'ログアウトに失敗しました。時間をおいて再度お試しください。',
      );
    }
  }

  Future<void> resendEmailLink() async {
    await sendEmailLink(state.email);
  }

  Future<void> refreshUserStatus() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      infoMessage: null,
    );

    try {
      await _repository.reloadCurrentUser();
      final user = _repository.currentUser;
      state = state.copyWith(
        isLoading: false,
        user: user,
        emailLinkSent: user != null ? false : state.emailLinkSent,
        infoMessage: user != null
            ? '認証が完了しました。'
            : 'まだ認証が完了していないようです。メールのリンクをもう一度ご確認ください。',
      );
      if (user != null) {
        unawaited(_handleUserSignedIn(user));
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateFirebaseError(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '認証状態の確認に失敗しました。通信環境をご確認のうえ再度お試しください。',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      infoMessage: null,
    );
  }

  Future<void> _handleUserSignedIn(User user) async {
    try {
      await _userRepository.registerUser(user);
      await read<SavedSakeNotifier>().onUserSignedIn(user.uid);
      await read<FavoriteNotifier>().onUserSignedIn(user.uid);
      await read<MyPageNotifier>().onUserSignedIn(user.uid);
    } catch (error, stackTrace) {
      dev.log('Failed to handle user sign-in sync: $error',
          name: 'AuthNotifier');
      dev.log(stackTrace.toString(), name: 'AuthNotifier');
    }
  }

  Future<void> _handleUserSignedOut() async {
    try {
      await read<SavedSakeNotifier>().onUserSignedOut();
      await read<FavoriteNotifier>().onUserSignedOut();
      await read<MyPageNotifier>().onUserSignedOut();
    } catch (error, stackTrace) {
      dev.log('Failed to handle user sign-out cleanup: $error',
          name: 'AuthNotifier');
      dev.log(stackTrace.toString(), name: 'AuthNotifier');
    }
  }

  String _translateFirebaseError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'missing-email':
        return 'メールアドレスを入力してください。';
      case 'too-many-requests':
        return 'リクエストが集中しています。少し時間をおいてから再度お試しください。';
      case 'user-disabled':
        return 'このメールアドレスは利用できません。別のメールアドレスでお試しください。';
      case 'invalid-action-code':
        return 'このメールリンクは無効か期限切れです。再度メールを送信してください。';
      default:
        return 'エラーが発生しました (${exception.code}). お手数ですが再度お試しください。';
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }
}
