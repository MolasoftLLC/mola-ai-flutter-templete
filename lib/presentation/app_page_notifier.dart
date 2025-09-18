import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../common/logger.dart';
import '../domain/notifier/my_page/my_page_notifier.dart';
import '../domain/repository/mola_api_repository.dart';
import 'common/help/help_guide_dialog.dart';

part 'app_page_notifier.freezed.dart';

@freezed
abstract class AppPageState with _$AppPageState {
  const factory AppPageState({
    @Default(0) int currentIndex,
    @Default(false) bool needUpDate,
    @Default(false) bool hasShownPreferencesDialog,
  }) = _AppPageState;
}

class AppPageNotifier extends StateNotifier<AppPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  AppPageNotifier({
    required this.context,
  }) : super(const AppPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  MolaApiRepository get molaApiRepository => read<MolaApiRepository>();
  MyPageNotifier get myPageNotifier => read<MyPageNotifier>();

  static const String _mainSearchHelpKey = 'help_shown_main_search';
  static const String _menuSearchHelpKey = 'help_shown_menu_search';
  static const String _myPageHelpKey = 'help_shown_my_page';

  final Set<HelpGuideType> _displayedHelpTypes = {};
  final Set<HelpGuideType> _pendingHelpTypes = {};

  GlobalKey first = GlobalKey();
  GlobalKey keyBottomNavigation1 = GlobalKey();
  GlobalKey keyBottomNavigation2 = GlobalKey();
  GlobalKey keyBottomNavigation3 = GlobalKey();
  GlobalKey keyBottomNavigation4 = GlobalKey();
  GlobalKey keyBottomNavigation5 = GlobalKey();
  GlobalKey keyBottomNavigation6 = GlobalKey();

  @override
  Future<void> initState() async {
    super.initState();
    final needUpDate = await isUpdateRequired();
    state = state.copyWith(needUpDate: needUpDate);

    unawaited(_maybeShowHelpGuide(state.currentIndex));

    // アプリ起動時に好みの設定をチェック
    _checkAndShowPreferencesDialog();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<Map<String, dynamic>?> getLatestVersion() async {
    final latestVersion = await molaApiRepository.getLatestVersion();
    return latestVersion;
  }

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<bool> isUpdateRequired() async {
    final latestVersion = await getLatestVersion();
    final currentVersion = await getCurrentVersion();
    logger.shout(currentVersion);
    logger.shout(latestVersion);
    return Version.parse(latestVersion!['version']!) >
        Version.parse(currentVersion);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {}
  }

  void onTabTapped(int index) {
    if (state.currentIndex != index) {
      state = state.copyWith(currentIndex: index);
    }
    unawaited(_maybeShowHelpGuide(index));
  }

  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  HelpGuideType? _mapIndexToHelpType(int index) {
    switch (index) {
      case 0:
        return HelpGuideType.mainSearch;
      case 1:
        return HelpGuideType.menuSearch;
      case 3:
        return HelpGuideType.myPage;
      default:
        return null;
    }
  }

  String? _helpKeyForType(HelpGuideType type) {
    switch (type) {
      case HelpGuideType.mainSearch:
        return _mainSearchHelpKey;
      case HelpGuideType.menuSearch:
        return _menuSearchHelpKey;
      case HelpGuideType.myPage:
        return _myPageHelpKey;
    }
  }

  Future<void> _maybeShowHelpGuide(int index) async {
    if (state.needUpDate) {
      return;
    }

    final type = _mapIndexToHelpType(index);
    if (type == null) {
      return;
    }

    if (_displayedHelpTypes.contains(type)) {
      return;
    }

    if (_pendingHelpTypes.contains(type)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _helpKeyForType(type);
    if (key == null) {
      return;
    }

    final hasShown = prefs.getBool(key) ?? false;
    if (hasShown) {
      _displayedHelpTypes.add(type);
      return;
    }

    _pendingHelpTypes.add(type);

    try {
      await Future.delayed(const Duration(milliseconds: 350));

      if (!context.mounted) {
        return;
      }

      if (_mapIndexToHelpType(state.currentIndex) != type) {
        return;
      }

      await HelpGuideDialog.showForType(context, type: type);
      await prefs.setBool(key, true);
      _displayedHelpTypes.add(type);
    } finally {
      _pendingHelpTypes.remove(type);
    }
  }

  // 好みの設定が未設定の場合、ダイアログを表示
  Future<void> _checkAndShowPreferencesDialog() async {
    // 既にダイアログを表示済みの場合は表示しない
    if (state.hasShownPreferencesDialog) return;

    final prefs = await SharedPreferences.getInstance();
    final savedPreferences = prefs.getString('sake_preferences');

    if (savedPreferences == null || savedPreferences.isEmpty) {
      // ダイアログ表示フラグを立てる
      state = state.copyWith(hasShownPreferencesDialog: true);

      // 少し遅延させてダイアログを表示（画面遷移後に表示するため）
      Future.delayed(const Duration(milliseconds: 500), () {
        _showSakePreferencesDialog();
      });
    }
  }

  // 好みの日本酒を選択するダイアログ
  void _showSakePreferencesDialog() {
    // 選択された好みを保持するリスト
    final List<String> selectedPreferences = [];

    // 選択肢のリスト
    final List<String> options = [
      '甘口',
      '辛口',
      'スッキリ',
      'フルーティ',
      'にごり',
      '微発泡',
      '酸味'
    ];

    showDialog(
      context: context,
      barrierDismissible: false, // ダイアログ外タップで閉じない
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text(
              'どんな日本酒が好き？',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3567),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '好みの特徴を選んでください（複数選択可）',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final isSelected = selectedPreferences.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1D3567).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF1D3567),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF1D3567)
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              selectedPreferences.add(option);
                            } else {
                              selectedPreferences.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // 選択された好みを文字列に変換
                  final preferences = selectedPreferences.join('、');

                  // 好みを保存
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('sake_preferences', preferences);

                  // MyPageNotifierのpreferencesを更新
                  myPageNotifier.setPreferences(preferences);

                  // ダイアログを閉じる
                  Navigator.of(dialogContext).pop();

                  // トーストメッセージを表示
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('MyPageからいつでも変更できるよ！'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1D3567),
                ),
                child: const Text('完了'),
              ),
            ],
          );
        });
      },
    );
  }
}
