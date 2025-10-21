import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../repository/auth_repository.dart';
import '../../repository/sake_user_repository.dart';
import '../favorite/favorite_notifier.dart';
import '../my_page/my_page_notifier.dart';
import '../saved_sake/saved_sake_notifier.dart';

part 'auth_notifier.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    User? user,
    @Default('') String email,
    @Default(false) bool isLoading,
    @Default(false) bool verificationEmailSent,
    String? infoMessage,
    String? errorMessage,
  }) = _AuthState;
}

class AuthNotifier extends StateNotifier<AuthState> with LocatorMixin {
  AuthNotifier() : super(const AuthState()) {
    Future.microtask(_initialize);
  }

  static const _verificationSentMessage =
      '確認メールを送信しました。迷惑メールもご確認ください。メール内のリンクから認証を完了し、再度ログインしてください。';
  static const _signInCompletedMessage = 'ログインしました。';

  late final StreamSubscription<User?> _authSubscription;

  AuthRepository get _repository => read<AuthRepository>();
  SakeUserRepository get _userRepository => read<SakeUserRepository>();

  Future<void> _initialize() async {
    final cachedEmail = await _repository.getCachedEmail();
    if (cachedEmail != null) {
      state = state.copyWith(email: cachedEmail);
    }

    _authSubscription = _repository.authStateChanges().listen((user) {
      final previousUser = state.user;
      final isVerified = user?.emailVerified ?? false;
      final nextUser = isVerified ? user : null;
      state = state.copyWith(
        user: nextUser,
        infoMessage: previousUser != null && user == null
            ? 'ログアウトしました。'
            : state.infoMessage,
      );
      if (user != null) {
        if (isVerified) {
          unawaited(_handleUserSignedIn(user));
        } else {
          dev.log(
            'User signed in but email is not verified yet.',
            name: 'AuthNotifier',
          );
        }
      } else if (previousUser != null) {
        unawaited(_handleUserSignedOut());
      }
    });
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  Future<void> signIn(String email, String password) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(errorMessage: 'メールアドレスを入力してください。');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'パスワードを入力してください。');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      infoMessage: null,
      verificationEmailSent: false,
    );

    try {
      final credential = await _repository.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      var user = credential.user;
      await user?.reload();
      user = _repository.currentUser;

      if (user != null && !user.emailVerified) {
        await _handleUnverifiedUser(user, trimmedEmail);
        return;
      }

      state = state.copyWith(
        isLoading: false,
        email: trimmedEmail,
        verificationEmailSent: false,
        infoMessage: _signInCompletedMessage,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateFirebaseError(e),
        verificationEmailSent: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ログインに失敗しました。通信環境をご確認のうえ再度お試しください。',
        verificationEmailSent: false,
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(errorMessage: 'メールアドレスを入力してください。');
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(errorMessage: 'パスワードは6文字以上で入力してください。');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      infoMessage: null,
      verificationEmailSent: false,
    );

    try {
      final credential = await _repository.signUpWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final createdUser = credential.user;
      if (createdUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '登録に失敗しました。時間をおいて再度お試しください。',
        );
        return;
      }

      try {
        await _sendVerificationEmail(createdUser);
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '確認メールの送信に失敗しました。時間をおいて再度お試しください。',
        );
        await _repository.signOut();
        return;
      }

      await _repository.signOut();

      state = state.copyWith(
        isLoading: false,
        email: trimmedEmail,
        verificationEmailSent: true,
        infoMessage: _verificationSentMessage,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateFirebaseError(e),
        verificationEmailSent: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '登録に失敗しました。時間をおいて再度お試しください。',
        verificationEmailSent: false,
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(errorMessage: 'メールアドレスを入力してください。');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      infoMessage: null,
    );

    try {
      await _repository.sendPasswordResetEmail(trimmedEmail);
      state = state.copyWith(
        isLoading: false,
        verificationEmailSent: false,
        infoMessage: 'パスワード再設定用のメールを送信しました。',
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateFirebaseError(e),
        verificationEmailSent: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'メールの送信に失敗しました。通信環境をご確認のうえ再度お試しください。',
        verificationEmailSent: false,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'ログアウトに失敗しました。時間をおいて再度お試しください。',
      );
    }
    state = state.copyWith(verificationEmailSent: false);
  }

  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      infoMessage: null,
      verificationEmailSent: false,
    );
  }

  Future<void> _sendVerificationEmail(User user) async {
    await user.sendEmailVerification();
  }

  Future<void> _handleUnverifiedUser(User user, String email) async {
    try {
      await _sendVerificationEmail(user);
      await _repository.signOut();
      state = state.copyWith(
        isLoading: false,
        email: email,
        verificationEmailSent: true,
        infoMessage: _verificationSentMessage,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      dev.log('Failed to send verification email: ${e.code}',
          name: 'AuthNotifier');
      dev.log(stackTrace.toString(), name: 'AuthNotifier');

      await _repository.signOut();

      if (e.code == 'too-many-requests') {
        state = state.copyWith(
          isLoading: false,
          email: email,
          verificationEmailSent: true,
          infoMessage:
              'メールBoxを開いてURLをタップし認証を完了してください！迷惑メールもご確認ください。',
        );
        return;
      }

      dev.log(stackTrace.toString(), name: 'AuthNotifier');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '確認メールの送信に失敗しました。時間をおいて再度お試しください。',
        verificationEmailSent: false,
      );
    } catch (error, stackTrace) {
      dev.log('Failed to send verification email: $error',
          name: 'AuthNotifier');
      dev.log(stackTrace.toString(), name: 'AuthNotifier');
      await _repository.signOut();
      state = state.copyWith(
        isLoading: false,
        errorMessage: '確認メールの送信に失敗しました。時間をおいて再度お試しください。',
        verificationEmailSent: false,
      );
  }
  }

  Future<void> _handleUserSignedIn(User user) async {
    state = state.copyWith(verificationEmailSent: false);
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
    state = state.copyWith(verificationEmailSent: false);
  }

  String _translateFirebaseError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'missing-email':
        return 'メールアドレスを入力してください。';
      case 'user-not-found':
        return '該当するユーザーが見つかりません。登録済みかご確認ください。';
      case 'wrong-password':
        return 'パスワードが正しくありません。';
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません。';
      case 'invalid-login-credentials':
        return 'メールアドレスまたはパスワードが正しくありません。';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています。';
      case 'weak-password':
        return 'より複雑なパスワードを設定してください。';
      case 'too-many-requests':
        return 'リクエストが集中しています。少し時間をおいてから再度お試しください。';
      case 'user-disabled':
        return 'このメールアドレスは利用できません。別のメールアドレスでお試しください。';
      default:
        return 'エラーが発生しました (${exception.code}). お手数ですが再度お試しください。';
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
