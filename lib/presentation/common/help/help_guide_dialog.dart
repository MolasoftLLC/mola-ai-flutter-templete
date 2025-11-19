import 'package:flutter/material.dart';

import '../../../common/assets.dart';

const Color _accentColor = Color(0xFFFFD54F);

enum HelpGuideType { mainSearch, menuSearch, myPage }

class HelpGuideContent {
  const HelpGuideContent({
    required this.summary,
    required this.image,
    required this.description,
  });

  final String summary;
  final AssetImage image;
  final String description;
}

class HelpGuideDialog extends StatefulWidget {
  const HelpGuideDialog({
    super.key,
    required this.title,
    required this.pages,
  });

  final String title;
  final List<HelpGuideContent> pages;

  static Future<void> showForType(
    BuildContext context, {
    required HelpGuideType type,
  }) {
    final pages = _HelpGuideRegistry.pages(type);
    final title = _HelpGuideRegistry.dialogTitle(type);
    if (pages.isEmpty) {
      return Future.value();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => HelpGuideDialog(
        title: title,
        pages: pages,
      ),
    );
  }

  @override
  State<HelpGuideDialog> createState() => _HelpGuideDialogState();
}

class _HelpGuideDialogState extends State<HelpGuideDialog> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == widget.pages.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D3567),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = widget.pages[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              page.summary,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D3567),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 220,
                              width: double.infinity,
                              color: Colors.white,
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image(image: page.image),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                page.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1D3567),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.pages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _accentColor
                            : _accentColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _currentPage == 0
                          ? null
                          : () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            },
                      child: const Text('戻る'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      child: const Text('閉じる'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D3567),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (isLastPage) {
                          Navigator.of(context).maybePop();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(isLastPage ? '完了' : '次へ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpGuideRegistry {
  static String dialogTitle(HelpGuideType type) {
    switch (type) {
      case HelpGuideType.mainSearch:
        return '日本酒検索の使い方';
      case HelpGuideType.menuSearch:
        return 'メニュー検索の使い方';
      case HelpGuideType.myPage:
        return 'マイページの使い方';
    }
  }

  static List<HelpGuideContent> pages(HelpGuideType type) {
    switch (type) {
      case HelpGuideType.mainSearch:
        return const [
          HelpGuideContent(
            summary: '酒瓶検索の流れ',
            image: Assets.mainHelpBottle,
            description:
                '酒瓶検索タブではカメラボタンから写真を撮影・選択できます。AIがラベルを解析し、日本酒情報を自動で取得します。解析した日本酒は保存ボタンでマイページに追加できます。',
          ),
          HelpGuideContent(
            summary: '解析が終わったら',
            image: Assets.mainHelpName,
            description:
                '銘柄名を入力して「解析だけ」を押すと蔵元や味わいなどの詳細が表示されます。お気に入りや保存を活用して、自分だけのリストを作りましょう。',
          ),
        ];
      case HelpGuideType.menuSearch:
        return const [
          HelpGuideContent(
            summary: 'メニューを撮影・アップロード',
            image: Assets.menuHelpCapture,
            description:
                'メニュー検索タブでは飲食店のメニュー写真をアップロードすると、写っている日本酒を自動でリスト化します。解析が終わるまで画面はそのままお待ちください。',
          ),
          HelpGuideContent(
            summary: '解析結果をチェック',
            image: Assets.menuHelpDetails,
            description:
                '解析で取得した日本酒をタップすると蔵元や味わい、オススメ度が表示されます。ハートでお気に入り登録、しおりでマイページに保存して飲み比べメモに活用しましょう。',
          ),
        ];
      case HelpGuideType.myPage:
        return const [
          HelpGuideContent(
            summary: '保存した日本酒を一覧で確認',
            image: Assets.myPageHelp,
            description:
                'マイページには保存した日本酒やお気に入りがまとまります。タイルをタップすると詳細やメモ、写真を編集できます。',
          ),
          HelpGuideContent(
            summary: 'お気に入りから好みを解析',
            image: Assets.myPageHelpSaved,
            description:
                '保存リストではなく「お気に入り」の日本酒を元にAIが解析！あなたの好みを判定してくれます。自分で変更も可能。',
          ),
        ];
    }
  }
}
