import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/common/access_url.dart';
import 'package:mola_gemini_flutter_template/presentation/favorite_search/favorite_search_page.dart';
import 'package:mola_gemini_flutter_template/presentation/main_search/main_search_page.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_search_page.dart';
import 'package:provider/provider.dart';

import 'app_page_notifier.dart';
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
    final currentIndex =
        context.select((AppPageState state) => state.currentIndex);
    final needUpDate = context.select((AppPageState state) => state.needUpDate);

    if (needUpDate) {
      return RequireUpdate(notifier);
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          MainSearchPage.wrapped(),
          MenuSearchPage.wrapped(),
          FavoriteSearchPage.wrapped(),
          MyPage.wrapped(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: notifier.onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1D3567),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '検索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'メニュー解析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '産地検索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'マイページ',
          ),
        ],
      ),
    );
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
