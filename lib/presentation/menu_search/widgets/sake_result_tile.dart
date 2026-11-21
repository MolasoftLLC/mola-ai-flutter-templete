import 'menu_action_button.dart';
import 'package:mola_gemini_flutter_template/common/analytics/app_analytics.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_sake_resolution.dart';

import '../../../common/utils/snack_bar_utils.dart';
import '../../../common/utils/sake_image_utils.dart';
import '../../../common/localization/localization_extensions.dart';
import 'package:provider/provider.dart';
import '../../../domain/eintities/sake_label_scan.dart';
import '../../../domain/notifier/my_page/my_page_notifier.dart';
import '../../../common/sake/taste_match.dart';
import '../../../common/sake/menu_taste_summary.dart';
import '../../common/widgets/sake_taste_match_preview.dart';
import '../../common/widgets/sake_card_rail.dart';
import 'menu_alternative_candidates.dart';
import 'menu_photo_style.dart';

/// 検出された日本酒1件分の表示タイルを構築するWidget
class SakeResultTile extends StatefulWidget {
  const SakeResultTile({
    super.key,
    required this.sake,
    required this.detailedSake,
    required this.hasDetails,
    required this.isItemLoading,
    required this.hasFailed,
    required this.isFavorited,
    required this.isSaved,
    required this.isLoading,
    required this.matchPercent,
    this.tasteProfile,
    this.dark = false,
    this.allowAlternativeSelection = false,
    this.onDiscover,
    this.onScanLabel,
    this.onSearchByName,
    required this.isUnverified,
    required this.candidates,
    required this.onCandidateSelected,
    required this.onOpenDetails,
    required this.onToggleFavorite,
    required this.onSave,
    required this.buildInfoRow,
    required this.buildTypesRow,
  });

  final bool dark;
  final bool allowAlternativeSelection;
  final VoidCallback? onDiscover;
  final VoidCallback? onScanLabel;
  final VoidCallback? onSearchByName;
  final Sake sake;
  final Sake? detailedSake;
  final bool hasDetails;
  final bool isItemLoading;
  final bool hasFailed;
  final bool isFavorited;
  final bool isSaved;
  final bool isLoading;
  final int? matchPercent;
  final SakeTasteProfileDetails? tasteProfile;
  final bool isUnverified;
  final List<MenuSakeCandidate> candidates;
  final ValueChanged<MenuSakeCandidate> onCandidateSelected;
  final VoidCallback? onOpenDetails;
  final Future<void> Function() onToggleFavorite;

  /// 保存ボタンタップ時に呼び出されるコールバック。成功した場合は`true`を返す。
  final Future<bool> Function() onSave;
  final Widget Function(String key, String value, IconData icon) buildInfoRow;
  final Widget Function(List<String> types) buildTypesRow;

  @override
  State<SakeResultTile> createState() => _SakeResultTileState();
}

class _SakeResultTileState extends State<SakeResultTile> {
  Color get _ink => widget.dark ? Colors.white : const Color(0xFF1D3567);
  Color get _muted => widget.dark ? Colors.white70 : Colors.grey;
  Color get _error => widget.dark ? Colors.redAccent : Colors.red.shade700;

  late final ExpansionTileController _expansionController;
  final _storageBucket = PageStorageBucket();
  final _tagsScrollController = ScrollController(keepScrollOffset: false);

  @override
  void initState() {
    super.initState();
    _expansionController = ExpansionTileController();
  }

  @override
  void dispose() {
    _tagsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.tasteProfile;
    final imagePath = preferredSakeImagePath(
      thumbnailImageUrl: widget.detailedSake?.thumbnailImageUrl,
      primaryImageUrl: widget.detailedSake?.primaryImageUrl,
    );
    final imageUri = imagePath == null || isSakePlaceholderImagePath(imagePath)
        ? null
        : Uri.tryParse(
            imagePath.startsWith('/')
                ? Uri.parse(sakeNoImageUrl).resolve(imagePath).toString()
                : imagePath,
          );
    final hasPhoto =
        imageUri != null &&
        (imageUri.scheme == 'https' || imageUri.scheme == 'http');
    final myPage = Provider.of<MyPageState?>(context);
    final preference = menuTastePreference(
      profile: myPage?.tasteProfile,
      preferences: myPage?.preferences,
    );
    final matchPercent = profile == null
        ? widget.matchPercent
        : calculateOptionalSakeTasteMatchPercent(
                profile: profile,
                preference: preference,
              ) ??
              widget.matchPercent;

    final actions = widget.hasDetails
        ? Row(
            children: [
              if (widget.onOpenDetails != null || widget.onDiscover != null)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: MenuPhotoStyle.yellow,
                      foregroundColor: MenuPhotoStyle.ink,
                      minimumSize: const Size(0, 48),
                      textStyle: TextStyle(
                        fontFamily: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('詳細を見る'),
                    onPressed:
                        widget.onOpenDetails == null &&
                            widget.onDiscover == null
                        ? null
                        : () {
                            AppAnalytics.instance.event('menu', 'detail');
                            (widget.onOpenDetails ?? widget.onDiscover)!.call();
                          },
                  ),
                ),
              const SizedBox(width: 8),
              IconButton.outlined(
                style: MenuActionButton.style(widget.dark).copyWith(
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                tooltip: widget.isSaved
                    ? context.l10n.removeSavedSake
                    : context.l10n.saveSake,
                icon: Icon(
                  widget.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: widget.isSaved ? _ink : _muted,
                  size: 22,
                ),
                onPressed: () async {
                  final wasSaved = widget.isSaved;
                  final success = await widget.onSave();
                  if (success && !wasSaved) {
                    SnackBarUtils.showInfoSnackBar(
                      context,
                      message: context.l10n.savedToMyPage,
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                style: MenuActionButton.style(widget.dark).copyWith(
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                tooltip: widget.isFavorited
                    ? context.l10n.removeFavorite
                    : context.l10n.favorite,
                icon: Icon(
                  widget.isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorited ? Colors.redAccent : _muted,
                  size: 22,
                ),
                onPressed: () {
                  unawaited(widget.onToggleFavorite());
                },
              ),
            ],
          )
        : widget.candidates.isNotEmpty
        ? const SizedBox.shrink()
        : !widget.hasFailed
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
          )
        : widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
          )
        : Icon(Icons.error_outline, color: _error);

    return PageStorage(
      bucket: _storageBucket,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 0),
        child: Stack(
          children: [
            Card(
              color: widget.dark ? const Color(0xFF112B4B) : null,
              margin: widget.dark ? EdgeInsets.zero : null,
              elevation: widget.dark ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                // Keep each sake's expansion state separate from the menu's
                // expansion state and descendant scroll offsets in PageStorage.
                key: PageStorageKey<Object>((
                  'menu-sake-details',
                  widget.key,
                  widget.sake.sakeId,
                  widget.sake.name,
                  widget.sake.type,
                )),
                initiallyExpanded: false,
                controller: _expansionController,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (hasPhoto) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUri.toString(),
                              width: 44,
                              height: 56,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            widget.hasDetails
                                ? (widget.detailedSake!.name ??
                                      context.l10n.unknown)
                                : (widget.sake.name ?? context.l10n.unknown),
                            style: TextStyle(
                              color: widget.dark ? Colors.white : null,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (profile != null) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        controller: _tagsScrollController,
                        key: const PageStorageKey<String>(
                          'menu-sake-taste-tags-scroll',
                        ),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final tag in menuTasteTags(profile))
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(
                                      color: Color(0xFF17395F),
                                    ),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: const Color(0xFFEAF0F7),
                                  side: BorderSide.none,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (matchPercent != null || profile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: widget.dark
                              ? const EdgeInsets.all(12)
                              : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: widget.dark ? const Color(0xFFEAF0F7) : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SakeTasteMatchPreview(
                            percent: matchPercent,
                            profile: profile,
                            preference: preference,
                            radarSize: 128,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        widget.sake.type ?? context.l10n.unknownType,
                        style: TextStyle(fontSize: 14, color: _muted),
                      ),
                    ),
                    if (widget.candidates.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  '候補から変更できます',
                                  style: TextStyle(
                                    color: Color(0xFF143861),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SakeCardRail(
                                compact: true,
                                nameMaxLines: 3,
                                analyticsTarget: 'menu_candidate',
                                analyticsScreen: 'menu',
                                sakes: widget.candidates
                                    .map((c) => c.sake)
                                    .toList(),
                                profilesFuture: Future.value(
                                  <int, SakeTasteProfileDetails>{},
                                ),
                                subtitleBuilder: (sake) => sake.type,
                                actionBuilder: (sake) => Semantics(
                                  selected:
                                      sake.sakeId ==
                                      widget.detailedSake?.sakeId,
                                  label:
                                      sake.sakeId == widget.detailedSake?.sakeId
                                      ? '選択中'
                                      : 'この商品に変更',
                                  child: Icon(
                                    sake.sakeId == widget.detailedSake?.sakeId
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        sake.sakeId ==
                                            widget.detailedSake?.sakeId
                                        ? const Color(0xFF143861)
                                        : const Color(0xFF8796A6),
                                  ),
                                ),
                                onTap: (sake) => widget.onCandidateSelected(
                                  widget.candidates.firstWhere(
                                    (c) => identical(c.sake, sake),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.allowAlternativeSelection &&
                        widget.candidates.isEmpty &&
                        widget.hasDetails &&
                        (widget.detailedSake?.sakeId ?? 0) > 0)
                      MenuAlternativeCandidates(
                        key: ValueKey(
                          'alternatives-${widget.detailedSake!.sakeId}',
                        ),
                        sakeId: widget.detailedSake!.sakeId!,
                        dark: widget.dark,
                        onSelected: widget.onCandidateSelected,
                      ),
                    if (widget.onSearchByName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 8),
                        child: MenuActionButton(
                          dark: widget.dark,
                          onPressed: widget.onSearchByName!,
                          icon: Icons.search,
                          label: '名前で探して選ぶ',
                        ),
                      ),
                    if (!widget.isItemLoading &&
                        (widget.detailedSake?.sakeId ?? 0) <= 0 &&
                        widget.candidates.isEmpty &&
                        widget.onScanLabel != null &&
                        widget.detailedSake == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.onDiscover != null
                                  ? 'AIが追加候補を見つけました'
                                  : 'この情報だけでは商品を特定できませんでした',
                              style: TextStyle(color: _ink),
                            ),
                            if (widget.onDiscover != null)
                              FilledButton.icon(
                                onPressed: widget.onDiscover,
                                icon: const Icon(Icons.add),
                                label: const Text('新発見のお酒を確認'),
                              ),
                            OutlinedButton.icon(
                              onPressed: widget.onScanLabel,
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('ラベルを撮影して確認'),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: actions,
                      ),
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
                showTrailingIcon: false,
                children: [
                  if (widget.hasDetails)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.detailedSake!.description
                                  ?.trim()
                                  .isNotEmpty ==
                              true) ...[
                            Text(
                              'このお酒について',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.detailedSake!.description!.trim(),
                              style: TextStyle(
                                height: 1.75,
                                color: widget.dark
                                    ? Colors.white
                                    : const Color(0xFF404A56),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (widget.detailedSake!.brewery != null)
                            widget.buildInfoRow(
                              context.l10n.brewery,
                              widget.detailedSake!.brewery!,
                              Icons.home_work,
                            ),
                          if (widget.detailedSake!.sakeMeterValue != null)
                            widget.buildInfoRow(
                              context.l10n.sakeMeterValue,
                              '${widget.detailedSake!.sakeMeterValue}',
                              Icons.science,
                            ),
                          if (widget.detailedSake!.types != null &&
                              widget.detailedSake!.types!.isNotEmpty)
                            widget.buildTypesRow(widget.detailedSake!.types!),
                          const SizedBox(height: 4),
                        ],
                      ),
                    )
                  else if (widget.candidates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            widget.isItemLoading
                                ? Icons.hourglass_top
                                : Icons.error_outline,
                            color: widget.isItemLoading ? _ink : _error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isItemLoading
                                  ? context.l10n.loadingDetails
                                  : context.l10n.detailsUnavailable,
                              style: TextStyle(
                                color: widget.isItemLoading ? _ink : _error,
                                fontStyle: widget.isItemLoading
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                fontWeight: widget.isItemLoading
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (widget.hasDetails)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: widget.dark
                        ? const Color(0xFFE6EDF5)
                        : const Color(0xFF143861),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: context.l10n.expand,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: Icon(
                        Icons.expand_more,
                        color: widget.dark
                            ? const Color(0xFF143861)
                            : Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        if (_expansionController.isExpanded) {
                          _expansionController.collapse();
                        } else {
                          _expansionController.expand();
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
