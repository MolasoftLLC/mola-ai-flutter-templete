import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/utils/snack_bar_utils.dart';
import '../../domain/notifier/auth/auth_notifier.dart';

enum EmailAuthMode { signIn, signUp }

class EmailLinkAuthPage extends StatefulWidget {
  const EmailLinkAuthPage({
    super.key,
    this.mode = EmailAuthMode.signIn,
  });

  final EmailAuthMode mode;

  static Widget signUp() {
    return const EmailLinkAuthPage(mode: EmailAuthMode.signUp);
  }

  static Widget signIn() {
    return const EmailLinkAuthPage(mode: EmailAuthMode.signIn);
  }

  @override
  State<EmailLinkAuthPage> createState() => _EmailLinkAuthPageState();
}

class _EmailLinkAuthPageState extends State<EmailLinkAuthPage> {
  static const _pageTitle = 'メールアドレスでログイン・登録';

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _hasNavigatedAfterSuccess = false;
  late EmailAuthMode _mode;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;

  bool get _isSignUp => _mode == EmailAuthMode.signUp;

  String get _descriptionText {
    if (_isSignUp) {
      return 'メールアドレスとパスワードを設定してアカウントを作成できます。登録後は同じ情報でログインできます。';
    }
    return '登録済みのメールアドレスとパスワードでログインします。パスワードを忘れた場合は再設定メールを送信できます。';
  }

  String get _primaryButtonLabel => _isSignUp ? '登録する' : 'ログインする';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _mode = widget.mode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode(EmailAuthMode newMode) {
    if (_mode == newMode) {
      return;
    }
    setState(() {
      _mode = newMode;
      _localError = null;
      _confirmPasswordController.clear();
    });
    context.read<AuthNotifier>().clearMessages();
  }

  Future<void> _submit(AuthNotifier notifier) async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    notifier.updateEmail(email);

    if (_isSignUp) {
      final confirm = _confirmPasswordController.text;
      if (password != confirm) {
        setState(() {
          _localError = '確認用パスワードが一致しません。';
        });
        return;
      }
      setState(() => _localError = null);
      await notifier.signUp(email, password);
      if (!mounted) {
        return;
      }
      final authState = context.read<AuthState>();
      if (authState.errorMessage == null) {
        setState(() {
          _mode = EmailAuthMode.signIn;
          _confirmPasswordController.clear();
        });
      }
      return;
    }

    setState(() => _localError = null);
    await notifier.signIn(email, password);
  }

  Future<void> _sendPasswordReset(AuthNotifier notifier) async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    notifier.updateEmail(email);
    setState(() => _localError = null);
    await notifier.sendPasswordReset(email);
    if (!mounted) {
      return;
    }
    final authState = context.read<AuthState>();
    if (authState.errorMessage == null && authState.infoMessage != null) {
      SnackBarUtils.showInfoSnackBar(
        context,
        message: 'パスワード再設定メールを送信しました。迷惑メールフォルダもご確認ください。',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<AuthNotifier>();
    final email = context.select((AuthState state) => state.email);
    final isLoading = context.select((AuthState state) => state.isLoading);
    final infoMessage = context.select((AuthState state) => state.infoMessage);
    final errorMessage =
        context.select((AuthState state) => state.errorMessage);
    final user = context.select((AuthState state) => state.user);

    if (email.isNotEmpty && _emailController.text.isEmpty) {
      _emailController.text = email;
      _emailController.selection =
          TextSelection.collapsed(offset: _emailController.text.length);
    }

    if (!_hasNavigatedAfterSuccess &&
        user != null &&
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
                      onChanged: _toggleMode,
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
                    if (_localError != null)
                      _MessageBanner(
                        message: _localError!,
                        isError: true,
                      ),
                    TextField(
                      controller: _emailController,
                      autocorrect: false,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        labelText: 'パスワード',
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
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
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          labelText: 'パスワード（確認用）',
                          labelStyle: const TextStyle(color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
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
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _submit(notifier),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          foregroundColor: const Color(0xFF1D3567),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
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
                                _primaryButtonLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => _sendPasswordReset(notifier),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('パスワードをお忘れの方はこちら'),
                        ),
                      ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        '登録しなくてもアプリをご利用いただけます。',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
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

  final EmailAuthMode currentMode;
  final ValueChanged<EmailAuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = currentMode == EmailAuthMode.signIn ? 0 : 1;
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
              index == 0 ? EmailAuthMode.signIn : EmailAuthMode.signUp,
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
      margin: const EdgeInsets.only(top: 4, bottom: 16),
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
