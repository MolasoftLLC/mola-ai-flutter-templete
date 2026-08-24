import 'package:flutter/material.dart';

import '../../../common/assets.dart';
import '../../../common/localization/localization_extensions.dart';

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
    final pages = _HelpGuideRegistry.pages(context, type);
    final title = _HelpGuideRegistry.dialogTitle(context, type);
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
                      child: Text(context.l10n.back),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      child: Text(context.l10n.close),
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
                      child: Text(
                        isLastPage ? context.l10n.done : context.l10n.next,
                      ),
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
  static String dialogTitle(BuildContext context, HelpGuideType type) {
    switch (type) {
      case HelpGuideType.mainSearch:
        return context.l10n.mainSearchHelpTitle;
      case HelpGuideType.menuSearch:
        return context.l10n.menuSearchHelpTitle;
      case HelpGuideType.myPage:
        return context.l10n.myPageHelpTitle;
    }
  }

  static List<HelpGuideContent> pages(
    BuildContext context,
    HelpGuideType type,
  ) {
    switch (type) {
      case HelpGuideType.mainSearch:
        return [
          HelpGuideContent(
            summary: context.l10n.helpBottleFlowTitle,
            image: Assets.mainHelpBottle,
            description: context.l10n.helpBottleFlowDescription,
          ),
          HelpGuideContent(
            summary: context.l10n.helpAfterAnalysisTitle,
            image: Assets.mainHelpName,
            description: context.l10n.helpAfterAnalysisDescription,
          ),
        ];
      case HelpGuideType.menuSearch:
        return [
          HelpGuideContent(
            summary: context.l10n.helpMenuCaptureTitle,
            image: Assets.menuHelpCapture,
            description: context.l10n.helpMenuCaptureDescription,
          ),
          HelpGuideContent(
            summary: context.l10n.helpMenuResultTitle,
            image: Assets.menuHelpDetails,
            description: context.l10n.helpMenuResultDescription,
          ),
        ];
      case HelpGuideType.myPage:
        return [
          HelpGuideContent(
            summary: context.l10n.helpSavedListTitle,
            image: Assets.myPageHelp,
            description: context.l10n.helpSavedListDescription,
          ),
          HelpGuideContent(
            summary: context.l10n.helpPreferenceAnalysisTitle,
            image: Assets.myPageHelpSaved,
            description: context.l10n.helpPreferenceAnalysisDescription,
          ),
        ];
    }
  }
}
