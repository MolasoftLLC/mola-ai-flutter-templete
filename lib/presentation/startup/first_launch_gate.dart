import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/constants/storage_keys.dart';
import '../../domain/notifier/auth/auth_notifier.dart';
import '../app_page.dart';
import '../auth/email_link_auth_page.dart';

class FirstLaunchGate extends StatefulWidget {
  const FirstLaunchGate({super.key});

  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  bool _isChecking = true;
  bool _showOnboarding = false;
  bool _isNavigatingToAuth = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(StorageKeys.onboardingCompleted) ?? false;
    if (!mounted) {
      return;
    }
    setState(() {
      _isChecking = false;
      _showOnboarding = !completed;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingCompleted, true);
    if (!mounted) {
      return;
    }
    setState(() {
      _showOnboarding = false;
    });
  }

  Future<void> _handleLoginPressed() async {
    if (_isNavigatingToAuth) {
      return;
    }
    setState(() {
      _isNavigatingToAuth = true;
    });

    context.read<AuthNotifier>().clearMessages();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EmailLinkAuthPage.signUp(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isNavigatingToAuth = false;
    });

    if (result == true) {
      await _completeOnboarding();
    }
  }

  Future<void> _handleSkipPressed() async {
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_showOnboarding) {
      return AppPage.wrapped();
    }

    return _OnboardingPrompt(
      isProcessing: _isNavigatingToAuth,
      onLogin: _handleLoginPressed,
      onSkip: _handleSkipPressed,
    );
  }
}

class _OnboardingPrompt extends StatelessWidget {
  const _OnboardingPrompt({
    required this.isProcessing,
    required this.onLogin,
    required this.onSkip,
  });

  final bool isProcessing;
  final Future<void> Function() onLogin;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/sake_logo.png',
                    height: 96,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sakepediaにようこそ！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'メール認証をしておくと、保存酒やお気に入りを端末間で同期できます。',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                _FeatureRow(
                  icon: Icons.cloud_sync,
                  text: '保存酒やお気に入りを自動バックアップ',
                ),
                const SizedBox(height: 16),
                _FeatureRow(
                  icon: Icons.photo_library,
                  text: '保存できるお酒が増える！',
                ),
                const SizedBox(height: 16),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: const Color(0xFF1D3567),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Color(0xFF1D3567),
                              ),
                            ),
                          )
                        : const Text(
                            'メールアドレスでログイン・登録',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: onSkip,
                    child: const Text(
                      '今はログインせずに使う',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'あとからマイページでもログインできます。',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFFD54F)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
