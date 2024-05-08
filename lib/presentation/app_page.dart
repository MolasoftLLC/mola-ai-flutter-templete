import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/main_search/main_search_page.dart';
import 'package:provider/provider.dart';

import '../common/assets.dart';
import '../common/logger.dart';
import 'app_page_notifier.dart';
import 'image_search/image_search_page.dart';
import 'menu_search/menu_search_page.dart';
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
    logger.shout(selectedNavIndex);
    final pages = [
      MainSearchPage.wrapped(),
      ImageSearchPage.wrapped(),
      MenuSearchPage.wrapped(),
      MyPage.wrapped(),
    ];
    return Scaffold(
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
                    image: Assets.imageNav,
                    fit: BoxFit.contain,
                  ),
                ),
                label: '画像検索'),
            BottomNavigationBarItem(
                icon: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image(
                    image: Assets.menuNav,
                    fit: BoxFit.contain,
                  ),
                ),
                label: 'メニュー検索'),
            BottomNavigationBarItem(
                icon: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image(
                    image: Assets.accountNav,
                    fit: BoxFit.contain,
                  ),
                ),
                label: 'その他'),
          ],
          type: BottomNavigationBarType.fixed,
          fixedColor: Color(0xFF1D3567),
        ));
  }
}
