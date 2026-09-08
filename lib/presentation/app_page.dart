import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/common/access_url.dart';
import 'package:mola_gemini_flutter_template/presentation/favorite_search/favorite_search_page.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/new_home_page.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/sake_map_page.dart';
import 'package:mola_gemini_flutter_template/presentation/timeline/timeline_page.dart';
import 'package:provider/provider.dart';

import '../common/localization/localization_extensions.dart';
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

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AppPageNotifier>();
    final currentIndex = context.select(
      (AppPageState state) => state.currentIndex,
    );
    final needUpDate = context.select((AppPageState state) => state.needUpDate);

    if (needUpDate) {
      return requireUpdate(context, notifier);
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          NewHomePage.wrapped(),
          SakeMapPage.wrapped(),
          FavoriteSearchPage.wrapped(),
          TimelinePage.wrapped(),
        ],
      ),
      bottomNavigationBar: _NewHomeBottomNavigation(
        currentPageIndex: currentIndex,
        onPageSelected: notifier.onTabTapped,
        onScanTap: () => openNewHomeScanner(context),
      ),
    );
  }
}

class _NewHomeBottomNavigation extends StatelessWidget {
  const _NewHomeBottomNavigation({
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onScanTap,
  });

  static const _backgroundColor = Color(0xFF143861);

  final int currentPageIndex;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onScanTap;

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
                      icon: Icons.search,
                      label: context.l10n.navigationSearch,
                      selected: currentPageIndex == 0,
                      onTap: () => onPageSelected(0),
                    ),
                    _NavigationItem(
                      icon: Icons.map_outlined,
                      label: context.l10n.navigationMap,
                      selected: currentPageIndex == 1,
                      onTap: () => onPageSelected(1),
                    ),
                    const Expanded(child: SizedBox()),
                    _NavigationItem(
                      icon: Icons.lightbulb_outline,
                      label: context.l10n.navigationRecommendation,
                      selected: currentPageIndex == 2,
                      onTap: () => onPageSelected(2),
                    ),
                    _NavigationItem(
                      icon: Icons.timeline,
                      label: context.l10n.navigationTimeline,
                      selected: currentPageIndex == 3,
                      onTap: () => onPageSelected(3),
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
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: selected ? 1 : 0.78);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
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

Widget requireUpdate(BuildContext context, AppPageNotifier notifier) {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.l10n.updateRequiredMessage),
            Platform.isIOS
                ? TextButton(
                    onPressed: () async {
                      await notifier.launchURL(APP_STORE_URL);
                    },
                    child: Text(context.l10n.openAppStore),
                  )
                : TextButton(
                    onPressed: () async {
                      await notifier.launchURL(PLAY_STORE_URL);
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
