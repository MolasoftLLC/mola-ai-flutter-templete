import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../common/logger.dart';
import '../common/localization/localization_extensions.dart';
import '../domain/notifier/my_page/my_page_notifier.dart';
import '../domain/eintities/app_content.dart';
import '../domain/repository/mola_api_repository.dart';
import 'common/dialogs/sake_preferences_dialog.dart';
import 'common/help/help_guide_dialog.dart';

part 'app_page_notifier.freezed.dart';

bool isVersionBelowMinimum({
  required String currentVersion,
  required String minimumVersion,
}) => Version.parse(minimumVersion) > Version.parse(currentVersion);

@freezed
abstract class AppPageState with _$AppPageState {
  const factory AppPageState({
    @Default(0) int currentIndex,
    @Default(false) bool needUpDate,
    @Default(false) bool hasShownPreferencesDialog,
    @Default(false) bool hasReadTimelineIntro,
    AppReleaseSetting? releaseSetting,
    @Default(<AppPromotion>[]) List<AppPromotion> startupPromotions,
    @Default(<AppPromotion>[]) List<AppPromotion> homeBanners,
  }) = _AppPageState;
}

class AppPageNotifier extends StateNotifier<AppPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  AppPageNotifier({required this.context}) : super(const AppPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  MolaApiRepository get molaApiRepository => read<MolaApiRepository>();
  MyPageNotifier get myPageNotifier => read<MyPageNotifier>();

  static const String _mainSearchHelpKey = 'help_shown_main_search';
  static const String _menuSearchHelpKey = 'help_shown_menu_search';
  static const String _myPageHelpKey = 'help_shown_my_page';
  static const String _timelineIntroKey = 'timeline_intro_shown';

  final Set<HelpGuideType> _displayedHelpTypes = {};
  final Set<HelpGuideType> _pendingHelpTypes = {};
  bool _hasAttemptedTimelineIntro = false;
  bool _isTimelineIntroDialogOpen = false;
  bool _isStartupPromotionOpen = false;

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
    AppContent? content;
    try {
      content = await molaApiRepository.fetchAppContent(
        platform: Platform.isAndroid ? 'android' : 'ios',
      );
    } catch (error, stackTrace) {
      logger.warning('アプリコンテンツの取得に失敗しました: $error');
      logger.info(stackTrace.toString());
    }
    AppReleaseSetting? release = content?.release;
    if (release == null) {
      try {
        release = await _fetchLegacyRelease();
      } catch (error, stackTrace) {
        logger.warning('旧アップデート情報の取得にも失敗しました: $error');
        logger.info(stackTrace.toString());
      }
    }
    final needUpDate = await isUpdateRequired(release);
    state = state.copyWith(
      needUpDate: needUpDate,
      releaseSetting: release,
      startupPromotions: content?.startupPromotions ?? const [],
      homeBanners: content?.homeBanners ?? const [],
    );

    if (needUpDate) return;

    await _maybeShowStartupPromotion();

    unawaited(_maybeShowHelpGuide(state.currentIndex));
    unawaited(_restoreTimelineIntroStatus());

    // アプリ起動時に好みの設定をチェック
    unawaited(_checkAndShowPreferencesDialog());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<Map<String, dynamic>?> getLatestVersion() async {
    final latestVersion = await molaApiRepository.getLatestVersion(
      platform: Platform.isAndroid ? 'android' : 'ios',
    );
    return latestVersion;
  }

  Future<AppReleaseSetting?> _fetchLegacyRelease() async {
    final value = await getLatestVersion();
    return value == null ? null : AppReleaseSetting.fromJson(value);
  }

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<bool> isUpdateRequired([AppReleaseSetting? release]) async {
    final currentVersion = await getCurrentVersion();
    logger.shout(currentVersion);
    logger.shout(release);

    if (release == null) {
      logger.info('最新バージョン情報が取得できなかったためアップデート判定をスキップします');
      return false;
    }

    final latestVersionValue = release.minimumVersion;
    if (latestVersionValue.isEmpty) {
      logger.warning('最低バージョンが空です');
      return false;
    }

    try {
      return isVersionBelowMinimum(
        currentVersion: currentVersion,
        minimumVersion: latestVersionValue,
      );
    } catch (error, stackTrace) {
      logger.warning('バージョン番号の解析に失敗したためアップデート判定をスキップします: $error');
      logger.info(stackTrace.toString());
      return false;
    }
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
    if (index == 3) {
      unawaited(_maybeShowTimelineIntro());
    }
  }

  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> openPromotion(AppPromotion promotion) async {
    final target = promotion.linkTarget;
    if (target == null) return;
    if (promotion.linkType == 'internal') {
      final index = switch (target) {
        'home' => 0,
        'map' => 1,
        'recommendations' => 2,
        'timeline' => 3,
        _ => null,
      };
      if (index != null) onTabTapped(index);
      return;
    }
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode: promotion.linkType == 'webview'
          ? LaunchMode.inAppBrowserView
          : LaunchMode.externalApplication,
    );
  }

  Future<void> _maybeShowStartupPromotion() async {
    if (_isStartupPromotionOpen || state.startupPromotions.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    AppPromotion? promotion;
    for (final candidate in state.startupPromotions) {
      if (!(prefs.getBool('startup_promotion_read_${candidate.id}') ?? false)) {
        promotion = candidate;
        break;
      }
    }
    if (promotion == null || !context.mounted) return;
    _isStartupPromotionOpen = true;
    final selected = promotion;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'お知らせ',
      pageBuilder: (dialogContext, _, __) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: '閉じる',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          selected.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFF2F2F2),
                            child: Icon(Icons.campaign_outlined, size: 72),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        selected.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (selected.body != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          selected.body!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
                      ],
                      if (selected.linkTarget != null) ...[
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await openPromotion(selected);
                          },
                          child: const Text('詳しく見る'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await prefs.setBool('startup_promotion_read_${selected.id}', true);
    _isStartupPromotionOpen = false;
  }

  HelpGuideType? _mapIndexToHelpType(int index) {
    switch (index) {
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

  Future<void> _maybeShowTimelineIntro() async {
    if (_hasAttemptedTimelineIntro || state.needUpDate) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasShownIntro = prefs.getBool(_timelineIntroKey) ?? false;
    if (hasShownIntro) {
      _hasAttemptedTimelineIntro = true;
      if (!state.hasReadTimelineIntro) {
        state = state.copyWith(hasReadTimelineIntro: true);
      }
      return;
    }

    if (_isTimelineIntroDialogOpen) {
      return;
    }

    _isTimelineIntroDialogOpen = true;

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!context.mounted || state.currentIndex != 3) {
        _isTimelineIntroDialogOpen = false;
        return;
      }

      _hasAttemptedTimelineIntro = true;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1D3567),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.timeline, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  context.l10n.timelineIntroTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.timelineIntroDescription,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.timelineIntroEnvyHint,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.close),
              ),
            ],
          );
        },
      );

      await prefs.setBool(_timelineIntroKey, true);
      state = state.copyWith(hasReadTimelineIntro: true);
    } finally {
      _isTimelineIntroDialogOpen = false;
    }
  }

  Future<void> _restoreTimelineIntroStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownIntro = prefs.getBool(_timelineIntroKey) ?? false;
    if (hasShownIntro && !state.hasReadTimelineIntro) {
      state = state.copyWith(hasReadTimelineIntro: true);
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
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!context.mounted) {
          return;
        }
        final bool ensured = await ensureSakePreferences(
          context: context,
          myPageNotifier: myPageNotifier,
        );
        if (!ensured) {
          state = state.copyWith(hasShownPreferencesDialog: false);
        }
      });
    }
  }
}
