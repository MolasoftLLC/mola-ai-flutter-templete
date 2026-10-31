import 'package:mola_gemini_flutter_template/common/analytics/app_analytics.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/common/access_url.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/new_home_page.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_search_page.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/sake_map_page.dart';
import 'package:mola_gemini_flutter_template/presentation/timeline/timeline_page.dart';
import 'package:provider/provider.dart';

import '../common/localization/localization_extensions.dart';
import '../common/utils/snack_bar_utils.dart';
import '../domain/eintities/app_content.dart';
import '../domain/notifier/auth/auth_notifier.dart';
import 'app_page_notifier.dart';
import 'my_page/my_page.dart';
import 'new_home/widgets/sake_bottom_navigation.dart';
import 'new_home/widgets/capture_radial_menu.dart';
import 'new_home/sake_stamp_book_page.dart';

class AppPage extends StatelessWidget {
  const AppPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<AppPageNotifier, AppPageState>(
          create: (context) => AppPageNotifier(context: context),
        ),
      ],
      child: const AppPage._(),
    );
  }

  static const double snackBarBottomObstacleHeight = 0;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AppPageNotifier>();
    final currentIndex = context.select(
      (AppPageState state) => state.currentIndex,
    );
    final historyOwner = context.select((AuthState state) => state.user?.uid);
    final isStartupGateLoading = context.select(
      (AppPageState state) => state.isStartupGateLoading,
    );
    final needUpDate = context.select((AppPageState state) => state.needUpDate);
    final release = context.select(
      (AppPageState state) => state.releaseSetting,
    );

    if (isStartupGateLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (release?.maintenanceEnabled == true) {
      return maintenancePage(context, notifier, release!);
    }

    if (needUpDate) {
      return requireUpdate(context, notifier, release);
    }

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          notifier.onTabTapped(0);
        }
      },
      child: Scaffold(
        body: SnackBarAvoidanceScope(
          // All navigation items stay within the bottom bar.
          bottomObstacleHeight: snackBarBottomObstacleHeight,
          child: IndexedStack(
            index: currentIndex,
            children: [
              AnalyticsScreen(
                name: 'home',
                active: currentIndex == 0,
                child: NewHomePage.wrapped(),
              ),
              KeyedSubtree(
                key: ValueKey('menu-tab-${historyOwner ?? 'guest'}'),
                child: AnalyticsScreen(
                  name: 'menu',
                  active: currentIndex == 1,
                  child: MenuSearchPage.wrapped(),
                ),
              ),
              KeyedSubtree(
                key: ValueKey('map-tab-${historyOwner ?? 'guest'}'),
                child: AnalyticsScreen(
                  name: 'map',
                  active: currentIndex == 2,
                  child: SakeMapPage.wrapped(
                    myMapRequests: notifier.myMapRequests,
                    communityMapRequests: notifier.communityMapRequests,
                  ),
                ),
              ),
              // Preserve timeline links and its intro while the rightmost tab is My Page.
              AnalyticsScreen(
                name: 'timeline',
                active: currentIndex == 3,
                child: TimelinePage.wrapped(),
              ),
              AnalyticsScreen(
                name: 'my_page',
                active: currentIndex == 4,
                child: MyPage.wrapped(isTab: true, isActive: currentIndex == 4),
              ),
              // Retired Explore index retained for stable existing tab IDs.
              const SizedBox.shrink(),
              _DeferredTab(
                key: ValueKey('stamp-tab-${historyOwner ?? 'guest'}'),
                active: currentIndex == 6,
                builder: () => const SakeStampBookPage(isTab: true),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SakeBottomNavigation(
          currentPageIndex: currentIndex,
          onPageSelected: (index) {
            final target = const {
              0: 'home',
              1: 'menu',
              2: 'map',
              3: 'timeline',
              4: 'my_page',
            }[index];
            if (target != null) AppAnalytics.instance.event('app', target);
            if (index == 6) {
              AppAnalytics.instance.event('home', 'sake_stamp_book');
            }
            if (index == 0 && currentIndex == 0) {
              final controller = notifier.homeFeatureGuide.homeScrollController;
              if (controller.hasClients) {
                controller.animateTo(
                  controller.position.minScrollExtent,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                );
              }
            }
            if (index == 2) {
              notifier.openCommunityMap();
            } else {
              notifier.onTabTapped(index);
            }
          },
          onScanTap: () => _openCapture(context, notifier),
          scanKey: notifier.homeFeatureGuide.bottomScanKey,
          menuAnalysisKey: notifier.homeFeatureGuide.menuAnalysisKey,
          mapKey: notifier.homeFeatureGuide.mapKey,
          myPageKey: notifier.homeFeatureGuide.myPageKey,
        ),
      ),
    );
  }
}

Future<void> _openCapture(
  BuildContext context,
  AppPageNotifier notifier,
) async {
  final action = await showCaptureRadialMenu(
    context,
    anchorKey: notifier.homeFeatureGuide.bottomScanKey,
  );
  if (action == null || !context.mounted) return;
  if (action == CaptureAction.menu) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(
          name: 'menu',
          child: MenuSearchPage.wrapped(startWithCamera: true),
        ),
      ),
    );
  } else {
    await openNewHomeScanner(
      context,
      startWithGallery: action == CaptureAction.gallery,
    );
  }
}

/// Avoid opening the stamp cover or loading its catalog before the first visit.
class _DeferredTab extends StatefulWidget {
  const _DeferredTab({super.key, required this.active, required this.builder});
  final bool active;
  final Widget Function() builder;
  @override
  State<_DeferredTab> createState() => _DeferredTabState();
}

class _DeferredTabState extends State<_DeferredTab> {
  Widget? _child;
  @override
  Widget build(BuildContext context) {
    if (widget.active) _child ??= widget.builder();
    return TickerMode(
      enabled: widget.active,
      child: _child ?? const SizedBox.shrink(),
    );
  }
}

Widget maintenancePage(
  BuildContext context,
  AppPageNotifier notifier,
  AppReleaseSetting release,
) {
  return Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.build_circle_outlined,
                size: 56,
                color: Color(0xFF17344E),
              ),
              const SizedBox(height: 20),
              const Text(
                '現在メンテナンス中です',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                release.maintenanceMessage ??
                    'ご不便をおかけしています。しばらくしてからもう一度お試しください。',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
              if (release.maintenanceUrl != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => notifier.launchURL(release.maintenanceUrl!),
                  child: const Text('詳しく見る'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Widget requireUpdate(
  BuildContext context,
  AppPageNotifier notifier,
  AppReleaseSetting? release,
) {
  final storeUrl =
      release?.storeUrl ?? (Platform.isIOS ? APP_STORE_URL : PLAY_STORE_URL);
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.updateRequiredMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (release?.message != null) ...[
              const SizedBox(height: 16),
              Text(release!.message!, textAlign: TextAlign.center),
              if (release.messageUrl != null)
                TextButton(
                  onPressed: () => notifier.launchURL(release.messageUrl!),
                  child: const Text('詳しく見る'),
                ),
            ],
            const SizedBox(height: 12),
            Platform.isIOS
                ? TextButton(
                    onPressed: () async {
                      await notifier.launchURL(storeUrl);
                    },
                    child: Text(context.l10n.openAppStore),
                  )
                : TextButton(
                    onPressed: () async {
                      await notifier.launchURL(storeUrl);
                    },
                    child: Text(context.l10n.openPlayStore),
                  ),
          ],
        ),
      ),
    ),
  );
}

//ATT対応時に利用する
// Future<void> showCustomTrackingDialog(BuildContext context) async =>
//     await showDialog<void>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Dear User'),
//         content: const Text(
//           'We care about your privacy and data security. We keep this app free by showing ads. '
//           'Can we continue to use your data to tailor ads for you?\n\nYou can change your choice anytime in the app settings. '
//           'Our partners will collect data and use a unique identifier on your device to show you ads.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Continue'),
//           ),
//         ],
//       ),
//     );
