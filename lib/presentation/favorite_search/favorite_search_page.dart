import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:provider/provider.dart';

import '../../common/prefecture.dart';
import '../../common/sake/master.dart';
import 'favorite_search_page_notifier.dart';

class FavoriteSearchPage extends StatelessWidget {
  const FavoriteSearchPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<FavoriteSearchPageNotifier,
            FavoriteSearchPageState>(
          create: (context) => FavoriteSearchPageNotifier(
            context: context,
          ),
        ),
      ],
      child: const FavoriteSearchPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<FavoriteSearchPageNotifier>();
    final isLoading =
        context.select((FavoriteSearchPageState state) => state.isLoading);
    final geminiResponse =
        context.select((FavoriteSearchPageState state) => state.geminiResponse);
    final selectedFlavors = context
            .select((FavoriteSearchPageState state) => state.selectedFlavors) ??
        [];
    final selectedTastes = context
            .select((FavoriteSearchPageState state) => state.selectedTastes) ??
        [];
    final selectedDesigns = context
            .select((FavoriteSearchPageState state) => state.selectedDesigns) ??
        [];
    final selectedPrefecture = context
        .select((FavoriteSearchPageState state) => state.selectedPrefecture);
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFF1D3567),
        child: SingleChildScrollView(
          child: isLoading
              ? const AILoading(loadingText: 'AIに問い合わせています')
              : Column(
                  children: [
                    SizedBox(
                      height: 100,
                    ),
                    Text(
                      'お好み検索',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 4,),
                    Text(
                      '産地や味わいから好きな日本酒を見つけよう！',
                      style: TextStyle(color: Colors.white,fontSize: 12,),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    if (geminiResponse != null)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          style: TextStyle(color: Colors.white),
                          geminiResponse,
                        ),
                      ),
                    if (geminiResponse != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40, top: 40),
                        child: Text(
                          '続けて問い合わせる',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 24),
                          child: Text(
                            '産地',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0), // 角丸の半径を指定
                      ),
                      child: Center(
                        child: DropdownButton(
                          hint: Text('産地を選択'),
                          underline: SizedBox(),
                          value: selectedPrefecture,
                          items: prefectures
                              .map((prefecture) => DropdownMenuItem(
                                    value: prefecture,
                                    child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                        child: Text(prefecture)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            notifier.setPrefecture(value);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 0),
                          child: Text(
                            '味わい 1',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: Sake.flavors.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final flavor = Sake.flavors[index];
                            return InkWell(
                              onTap: () {
                                notifier.toggleSelectedFlavor(flavor);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedFlavors.contains(flavor)
                                      ? Colors.blue
                                      : Colors.white60,
                                  borderRadius:
                                      BorderRadius.circular(10.0), // 角丸の半径を指定
                                ),
                                child: Center(
                                  child: Text(
                                    flavor,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 0),
                          child: Text(
                            '味わい 2',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: Sake.tastes.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final taste = Sake.tastes[index];
                            return InkWell(
                              onTap: () {
                                notifier.toggleSelectedTaste(taste);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedTastes.contains(taste)
                                      ? Colors.blue
                                      : Colors.white60,
                                  borderRadius:
                                      BorderRadius.circular(10.0), // 角丸の半径を指定
                                ),
                                child: Center(
                                  child: Text(
                                    taste,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 0),
                          child: Text(
                            '特定名称ほか',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: Sake.designs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final design = Sake.designs[index];
                            return InkWell(
                              onTap: () {
                                notifier.toggleSelectedDesigns(design);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedDesigns.contains(design)
                                      ? Colors.blue
                                      : Colors.white60,
                                  borderRadius:
                                      BorderRadius.circular(10.0), // 角丸の半径を指定
                                ),
                                child: Center(
                                  child: Text(
                                    design,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    SizedBox(
                      width: 220,
                      child: FilledButton(
                        onPressed: () async {
                          await notifier.promptWithFavorite();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: Text('AIに質問'),
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);
