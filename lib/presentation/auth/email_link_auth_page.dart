import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/utils/snack_bar_utils.dart';
import '../../domain/notifier/auth/auth_notifier.dart';

enum EmailLinkAuthMode { signUp, signIn }

class EmailLinkAuthPage extends StatefulWidget {
  const EmailLinkAuthPage({
    super.key,
    this.mode = EmailLinkAuthMode.signIn,
  });

  final EmailLinkAuthMode mode;

  static Widget signUp() {
    return const EmailLinkAuthPage(mode: EmailLinkAuthMode.signUp);
  }

  static Widget signIn() {
    return const EmailLinkAuthPage(mode: EmailLinkAuthMode.signIn);
  }

  @override
  State<EmailLinkAuthPage> createState() => _EmailLinkAuthPageState();
}

class _EmailLinkAuthPageState extends State<EmailLinkAuthPage> {
  static const _authCompletedMessage = '認証が完了しました。';
  static const _pageTitle = 'メールでログイン・登録';

  late final TextEditingController _emailController;
  bool _hasNavigatedAfterSuccess = false;
  late EmailLinkAuthMode _mode;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _mode = widget.mode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isSignUp => _mode == EmailLinkAuthMode.signUp;

  String get _descriptionText {
    if (_isSignUp) {
      return 'メールアドレスにログイン用リンクを送信します。メールのリンクをタップするだけで登録が完了します。';
    }
    return '登録済みのメールにログインリンクを送信します。同じ手順でいつでも再ログインできます。';
  }

  String _primaryButtonLabel({required bool emailLinkSent}) {
    if (emailLinkSent) {
      return _isSignUp ? '認証状況を確認して登録を完了' : '認証状況を確認してログイン';
    }
    return _isSignUp ? '登録リンクを送信' : 'ログインリンクを送信';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<AuthNotifier>();
    final email = context.select((AuthState state) => state.email);
    final isLoading = context.select((AuthState state) => state.isLoading);
    final infoMessage = context.select((AuthState state) => state.infoMessage);
    final errorMessage =
        context.select((AuthState state) => state.errorMessage);
    final emailLinkSent =
        context.select((AuthState state) => state.emailLinkSent);
    final user = context.select((AuthState state) => state.user);

    if (email.isNotEmpty && _emailController.text.isEmpty) {
      _emailController.text = email;
      _emailController.selection =
          TextSelection.collapsed(offset: _emailController.text.length);
    }

    final isBusy = isLoading;
    final showMailActions = user == null;
    final primaryLabel =
        _primaryButtonLabel(emailLinkSent: emailLinkSent && showMailActions);

    if (!_hasNavigatedAfterSuccess &&
        infoMessage == _authCompletedMessage &&
        Navigator.of(context).canPop()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasNavigatedAfterSuccess) {
          return;
        }
        _hasNavigatedAfterSuccess = true;
        notifier.clearMessages();
        Navigator.of(context).pop(true);
      });
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1D3567), Color(0xFF0A1428)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D3567),
          title: const Text(
            _pageTitle,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModeSwitcher(
                      currentMode: _mode,
                      onChanged: (newMode) {
                        if (_mode == newMode) {
                          return;
                        }
                        setState(() {
                          _mode = newMode;
                        });
                        context.read<AuthNotifier>().clearMessages();
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _descriptionText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (user != null)
                      _MessageBanner(
                        message: '${user.email ?? '登録済みアカウント'}でログイン中です。',
                        isError: false,
                      ),
                    if (errorMessage != null)
                      _MessageBanner(
                        message: errorMessage,
                        isError: true,
                      ),
                    if (infoMessage != null)
                      _MessageBanner(
                        message: infoMessage,
                        isError: false,
                      ),
                    TextField(
                      controller: _emailController,
                      autocorrect: false,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isBusy,
                      onChanged: notifier.updateEmail,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        labelText: 'メールアドレス',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'example@mail.com',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFFFD54F)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    if (showMailActions)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isBusy
                              ? null
                              : () async {
                                  FocusScope.of(context).unfocus();
                                  if (emailLinkSent) {
                                    await notifier.refreshUserStatus();
                                  } else {
                                    await notifier.sendEmailLink(
                                      _emailController.text,
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    final authState = context.read<AuthState>();
                                    if (authState.errorMessage == null &&
                                        authState.emailLinkSent) {
                                      SnackBarUtils.showInfoSnackBar(
                                        context,
                                        message: '送信しました！迷惑メールもご確認ください！',
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD54F),
                            foregroundColor: const Color(0xFF1D3567),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isBusy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Color(0xFF1D3567),
                                    ),
                                  ),
                                )
                              : Text(
                                  primaryLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    if (emailLinkSent && showMailActions)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () async {
                                    await notifier.resendEmailLink();
                                    if (!mounted) {
                                      return;
                                    }
                                    final authState = context.read<AuthState>();
                                    if (authState.errorMessage == null &&
                                        authState.emailLinkSent) {
                                      SnackBarUtils.showInfoSnackBar(
                                        context,
                                        message: '送信しました！迷惑メールもご確認ください！',
                                      );
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFFD54F)),
                              foregroundColor: const Color(0xFFFFD54F),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('メールを再送'),
                          ),
                        ),
                      ),
                    if (user != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () {
                                      notifier.signOut();
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white70),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('ログアウト'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1D3567),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'マイページへ戻る',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: const [
                          Text(
                            '登録しなくてもアプリをご利用いただけます。',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                Container(
                  color: Colors.black.withOpacity(0.2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.currentMode,
    required this.onChanged,
  });

  final EmailLinkAuthMode currentMode;
  final ValueChanged<EmailLinkAuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = currentMode == EmailLinkAuthMode.signIn ? 0 : 1;
    final isSelected = <bool>[selectedIndex == 0, selectedIndex == 1];

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: ToggleButtons(
          isSelected: isSelected,
          borderColor: Colors.transparent,
          selectedBorderColor: Colors.transparent,
          fillColor: const Color(0xFFFFD54F),
          selectedColor: const Color(0xFF1D3567),
          color: Colors.white70,
          borderRadius: BorderRadius.circular(12),
          constraints: const BoxConstraints(minHeight: 36, minWidth: 120),
          onPressed: (index) {
            if (index == selectedIndex) {
              return;
            }
            onChanged(
              index == 0 ? EmailLinkAuthMode.signIn : EmailLinkAuthMode.signUp,
            );
          },
          children: const [
            Text(
              'ログイン',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '新規登録',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? Colors.redAccent.withOpacity(0.15)
            : const Color(0xFFFFD54F).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.redAccent : const Color(0xFFFFD54F),
          width: 1,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? Colors.redAccent.shade100 : Colors.white,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}
