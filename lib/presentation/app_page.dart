import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/common/access_url.dart';
import 'package:mola_gemini_flutter_template/presentation/favorite_search/favorite_search_page.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/new_home_page.dart';
import 'package:mola_gemini_flutter_template/presentation/my_page/my_page.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/sake_map_page.dart';
import 'package:mola_gemini_flutter_template/presentation/timeline/timeline_page.dart';
import 'package:provider/provider.dart';

import '../common/localization/localization_extensions.dart';
import '../common/utils/snack_bar_utils.dart';
import '../domain/eintities/app_content.dart';
import 'app_page_notifier.dart';

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

  static const double snackBarBottomObstacleHeight = 43;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AppPageNotifier>();
    final currentIndex = context.select(
      (AppPageState state) => state.currentIndex,
    );
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

    return Scaffold(
      body: SnackBarAvoidanceScope(
        // Scaffoldがナビ本体とSafe Areaを避けるため、本文側へ張り出す
        // 中央撮影ボタンの高さだけを追加で退避する。
        bottomObstacleHeight: snackBarBottomObstacleHeight,
        child: IndexedStack(
          index: currentIndex,
          children: [
            NewHomePage.wrapped(),
            SakeMapPage.wrapped(),
            FavoriteSearchPage.wrapped(),
            TimelinePage.wrapped(),
            MyPage.wrapped(),
          ],
        ),
      ),
      bottomNavigationBar: _NewHomeBottomNavigation(
        currentPageIndex: currentIndex,
        onPageSelected: notifier.onTabTapped,
        onScanTap: () => openNewHomeScanner(context),
        scanKey: notifier.homeFeatureGuide.bottomScanKey,
        mapKey: notifier.homeFeatureGuide.mapKey,
      ),
    );
  }
}

class _NewHomeBottomNavigation extends StatelessWidget {
  const _NewHomeBottomNavigation({
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onScanTap,
    required this.scanKey,
    required this.mapKey,
  });

  static const _backgroundColor = Color(0xFF143861);

  final int currentPageIndex;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onScanTap;
  final GlobalKey scanKey;
  final GlobalKey mapKey;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 78 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: _backgroundColor,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Row(
                  children: [
                    _NavigationItem(
                      icon: Icons.home_outlined,
                      label: context.l10n.navigationHome,
                      selected: currentPageIndex == 0,
                      onTap: () => onPageSelected(0),
                    ),
                    _NavigationItem(
                      focusKey: mapKey,
                      icon: Icons.map_outlined,
                      label: context.l10n.navigationMap,
                      selected: currentPageIndex == 1,
                      onTap: () => onPageSelected(1),
                    ),
                    const Expanded(child: SizedBox()),
                    _NavigationItem(
                      icon: Icons.timeline,
                      label: context.l10n.navigationTimeline,
                      selected: currentPageIndex == 3,
                      onTap: () => onPageSelected(3),
                    ),
                    _NavigationItem(
                      icon: Icons.person_outline,
                      label: context.l10n.navigationMyPage,
                      selected: currentPageIndex == 4,
                      onTap: () => onPageSelected(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -43,
            child: Column(
              children: [
                Material(
                  key: scanKey,
                  color: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(
                    side: BorderSide(color: Color(0xFFFF914D), width: 5),
                  ),
                  child: InkWell(
                    onTap: onScanTap,
                    customBorder: const CircleBorder(),
                    child: const SizedBox.square(
                      dimension: 87,
                      child: Icon(
                        Icons.camera_alt,
                        color: Color(0xFFFF7A1A),
                        size: 52,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.navigationScan,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    this.focusKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final GlobalKey? focusKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _selectedColor = Color(0xFFFFD166);

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _selectedColor
        : Colors.white.withValues(alpha: 0.78);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          key: focusKey,
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 31),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
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
