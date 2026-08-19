import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../common/logger.dart';

// 半透明のローディング
class AILoading extends StatefulWidget {
  const AILoading({
    required this.loadingText,
    super.key,
  });

  final String loadingText;

  @override
  State<AILoading> createState() => _AILoadingState();
}

class _AILoadingState extends State<AILoading> {
  static const _factsAssetPath = 'assets/data/sake_facts.json';
  static const _slideInterval = Duration(seconds: 7);
  static const _factTransitionDuration = Duration(milliseconds: 450);
  static const List<String> _tailPhrases = [
    '覚えておくと注文のときにちょっと通っぽく語れるんだ。',
    '知っているとペアリングの幅がぐっと広がるんだよね。',
    '友だちに披露すると話のタネとして盛り上がるよ。',
    '蔵見学や試飲会で自信を持って語れる小ネタなんだ。',
    '頭の片隅に入れておくと日本酒選びがもっと楽しくなるんだ。',
  ];

  final Random _random = Random();

  List<_SakeFact> _facts = <_SakeFact>[];
  int _currentIndex = 0;
  Timer? _slideTimer;
  bool _isLoadingFacts = false;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadFacts();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFacts() async {
    setState(() {
      _isLoadingFacts = true;
      _loadErrorMessage = null;
    });
    try {
      final rawJson = await rootBundle.loadString(_factsAssetPath);
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      final facts = decoded
          .map((e) => _SakeFact.fromJson(e as Map<String, dynamic>))
          .where((fact) => fact.body.isNotEmpty || fact.title.isNotEmpty)
          .toList();
      if (facts.isEmpty) {
        setState(() {
          _facts = const <_SakeFact>[];
          _isLoadingFacts = false;
          _loadErrorMessage = '豆知識の読み込みに失敗しました';
        });
        return;
      }
      facts.shuffle(_random);
      if (!mounted) {
        return;
      }
      setState(() {
        _facts = facts;
        _currentIndex = 0;
        _isLoadingFacts = false;
        _loadErrorMessage = null;
      });
      _startSlideTimer();
    } catch (error, stackTrace) {
      logger.warning('豆知識アセットの読み込みに失敗しました: $error');
      logger.info(stackTrace.toString());
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingFacts = false;
        _loadErrorMessage = '豆知識の読み込みに失敗しました';
      });
    }
  }

  void _startSlideTimer() {
    _slideTimer?.cancel();
    if (_facts.length <= 1) {
      return;
    }
    _slideTimer = Timer.periodic(_slideInterval, (_) => _showNextFact());
  }

  void _showNextFact() {
    if (!mounted || _facts.isEmpty) {
      return;
    }
    setState(() {
      _currentIndex = (_currentIndex + 1) % _facts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: const Color(0xFF1D3567),
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/ai_loading.json',
                width: 300,
                height: 300,
                fit: BoxFit.fitWidth,
                repeat: true,
              ),
              Text(
                widget.loadingText,
                style: textTheme.bodyLarge?.copyWith(color: Colors.white) ??
                    const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildKnowledgeCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKnowledgeCard() {
    if (_isLoadingFacts) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      );
    }
    if (_loadErrorMessage != null) {
      return SizedBox(
        width: 300,
        child: Text(
          _loadErrorMessage!,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_facts.isEmpty) {
      return const SizedBox.shrink();
    }
    final fact = _facts[_currentIndex];

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SAKE豆知識',
            style: TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: _factTransitionDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey('${fact.title}_${fact.body}_$_currentIndex'),
              children: [
                Text(
                  _buildQuestionText(fact.title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _buildAnswerText(
                    fact.body,
                    tail: _tailPhrases[_currentIndex % _tailPhrases.length],
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SakeFact {
  const _SakeFact({required this.title, required this.body});

  factory _SakeFact.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String?;
    final rawBody = json['body'] as String?;
    return _SakeFact(
      title: rawTitle?.trim() ?? '',
      body: rawBody?.trim() ?? '',
    );
  }

  final String title;
  final String body;
}

String _buildQuestionText(String rawTitle) {
  final trimmed = rawTitle.trim();
  if (trimmed.isEmpty) {
    return 'この豆知識って何？';
  }
  if (trimmed.endsWith('？') || trimmed.endsWith('?')) {
    return trimmed;
  }
  return '$trimmedって何？';
}

String _buildAnswerText(String rawBody, {required String tail}) {
  final base = rawBody.trim().replaceAll(RegExp(r'。+$'), '');
  if (base.isEmpty) {
    return '日本酒の世界は奥深いんだよ。$tail';
  }
  return '${_wrapWithFriendlyEnding(base)} $tail';
}

String _wrapWithFriendlyEnding(String text) {
  if (text.isEmpty) {
    return '日本酒の世界は奥深いんだよ。';
  }
  final String lastChar = text.substring(text.length - 1);
  switch (lastChar) {
    case 'だ':
    case 'よ':
    case 'ね':
      return '$textよ。';
    case 'る':
    case 'す':
    case 'つ':
    case 'く':
    case 'む':
    case 'ぶ':
    case 'ぬ':
    case 'ぐ':
    case 'ず':
    case 'め':
    case 'れ':
      return '$textんだよ。';
    case 'い':
    case 'き':
    case 'ち':
    case 'り':
    case 'み':
    case 'ぎ':
    case 'び':
    case 'ぴ':
    case 'え':
      return '$textんだよ。';
    case 'に':
      return '$textになるんだよ。';
    case 'を':
      return '$textを意味するんだよ。';
    case 'が':
      return '$textが魅力なんだよ。';
    case 'は':
      return '$textなんだよ。';
    default:
      return '$textなんだよ。';
  }
}
