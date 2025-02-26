import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/common/access_url.dart';
import 'package:mola_gemini_flutter_template/presentation/main_search/main_search_page.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_search_page.dart';
import 'package:provider/provider.dart';

import '../common/assets.dart';
import 'app_page_notifier.dart';
import 'favorite_search/favorite_search_page.dart';
import 'my_page/my_page.dart';

class AppPage extends StatelessWidget {
  const AppPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<AppPageNotifier, AppPageState>(
          create: (context) => AppPageNotifier(
            context: context,
          ),
        ),
      ],
      child: const AppPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AppPageNotifier>();
    final selectedNavIndex =
        context.select((AppPageState state) => state.selectedNavIndex);
    final needUpDate = context.select((AppPageState state) => state.needUpDate);

    final pages = [
      MainSearchPage.wrapped(),
      FavoriteSearchPage.wrapped(),
      MenuSearchPage.wrapped(),
      MyPage.wrapped(),
    ];

    return needUpDate
        ? RequireUpdate(notifier)
        : Scaffold(
            body: pages[selectedNavIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: selectedNavIndex,
              onTap: notifier.onNavTapped,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image(
                      image: Assets.sakeLogoColor,
                      fit: BoxFit.contain,
                    ),
                  ),
                  label: '銘柄検索',
                ),
                BottomNavigationBarItem(
                    icon: SizedBox(
                      width: 30,
                      height: 30,
                      child: Image(
                        image: Assets.menuNav,
                        fit: BoxFit.contain,
                      ),
                    ),
                    label: '好み検索'),
                BottomNavigationBarItem(
                    icon: SizedBox(
                      width: 30,
                      height: 30,
                      child: Image(
                        image: Assets.imageNav,
                        fit: BoxFit.contain,
                      ),
                    ),
                    label: '画像検索'),
                // BottomNavigationBarItem(
                //     icon: SizedBox(
                //       width: 30,
                //       height: 30,
                //       child: Image(
                //         image: Assets.accountNav,
                //         fit: BoxFit.contain,
                //       ),
                //     ),
                //     label: 'お気に入り'),
                BottomNavigationBarItem(
                    icon: SizedBox(
                      width: 30,
                      height: 30,
                      child: Image(
                        image: Assets.accountNav,
                        fit: BoxFit.contain,
                      ),
                    ),
                    label: 'お気に入り'),
              ],
              type: BottomNavigationBarType.fixed,
              fixedColor: Color(0xFF1D3567),
            ));
  }
}

Widget RequireUpdate(AppPageNotifier notifier) {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ご利用頂きありがとうございます！アップデートが必要のVersionをお使いですので、ご不便をおかけしますが以下よりアプリのアップデートをお願いいたします。',
            ),
            Platform.isIOS
                ? TextButton(
                    onPressed: () async {
                      await notifier.launchURL(APP_STORE_URL);
                    },
                    child: Text('AppleStoreへ'))
                : TextButton(
                    onPressed: () async {
                      await notifier.launchURL(PLAY_STORE_URL);
                    },
                    child: Text('GoogleStoreへ'))
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
