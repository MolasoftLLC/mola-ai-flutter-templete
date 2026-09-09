import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/localization/localization_extensions.dart';
import '../../common/sake/master.dart' as sake_master;
import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/place_map_repository.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import '../my_page/widgets/place_picker_sheet.dart';

const _navy = Color(0xFF143861);
const _orange = Color(0xFFFF7A1A);

class SakeMasterDetailPage extends StatefulWidget {
  const SakeMasterDetailPage({super.key, required this.venueSake});
  final VenueSake venueSake;

  @override
  State<SakeMasterDetailPage> createState() => _SakeMasterDetailPageState();
}

class _SakeMasterDetailPageState extends State<SakeMasterDetailPage> {
  Future<SakeOverview>? _future;
  bool _initialized = false;
  SavedSakeNotifier? _savedSakeNotifier;
  FavoriteNotifier? _favoriteNotifier;
  void Function()? _removeSavedSakeListener;
  void Function()? _removeFavoriteListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindNotifiers();
    if (_initialized) return;
    _initialized = true;
    _future = _fetch();
  }

  void _bindNotifiers() {
    final saved = Provider.of<SavedSakeNotifier?>(context, listen: false);
    final favorite = Provider.of<FavoriteNotifier?>(context, listen: false);
    if (!identical(_savedSakeNotifier, saved)) {
      _removeSavedSakeListener?.call();
      _savedSakeNotifier = saved;
      _removeSavedSakeListener = _savedSakeNotifier?.addListener(
        (_) => _refreshFromNotifier(),
      );
    }
    if (!identical(_favoriteNotifier, favorite)) {
      _removeFavoriteListener?.call();
      _favoriteNotifier = favorite;
      _removeFavoriteListener = _favoriteNotifier?.addListener(
        (_) => _refreshFromNotifier(),
      );
    }
  }

  void _refreshFromNotifier() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _removeSavedSakeListener?.call();
    _removeFavoriteListener?.call();
    super.dispose();
  }

  Future<SakeOverview>? _fetch() {
    final id = widget.venueSake.sakeId;
    return id == null || id <= 0
        ? null
        : context.read<SakeScanRepository>().fetchOverview(id);
  }

  Future<void> _reload() async {
    final next = _fetch();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // FutureBuilder presents the failure and retry action.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: PrimaryAppBar(
      title: '日本酒詳細',
      actions: [
        _MasterSaveButton(
          venueSake: widget.venueSake,
          notifier: _savedSakeNotifier,
        ),
        _MasterFavoriteButton(
          venueSake: widget.venueSake,
          notifier: _favoriteNotifier,
        ),
      ],
    ),
    bottomNavigationBar: _MasterRecordCta(
      sake: _asSake(widget.venueSake),
      notifier: _savedSakeNotifier,
    ),
    body: FutureBuilder<SakeOverview>(
      future: _future,
      builder: (context, snapshot) => RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(color: _orange),
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    const Expanded(child: Text('詳細情報を取得できませんでした。')),
                    TextButton(onPressed: _reload, child: const Text('再試行')),
                  ],
                ),
              ),
            _Details(
              overview: snapshot.data,
              fallback: widget.venueSake,
              savedSakeNotifier: _savedSakeNotifier,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({
    required this.overview,
    required this.fallback,
    required this.savedSakeNotifier,
  });
  final SakeOverview? overview;
  final VenueSake fallback;
  final SavedSakeNotifier? savedSakeNotifier;

  @override
  Widget build(BuildContext context) {
    final sake = overview?.sake;
    final detailSake = sake ?? _asSake(fallback);
    final personalRecord = _findSavedSake(savedSakeNotifier, detailSake);
    final master = overview?.master ?? const SakeMasterDetails();
    final profile = master.tasteProfile;
    final category =
        master.category ??
        master.specialDesignation ??
        sake?.type ??
        fallback.type;
    final sakeMeterValue =
        master.sakeMeterValue ??
        sake?.sakeMeterValue ??
        personalRecord?.sakeMeterValue;
    final specs = <String, String>{
      if (master.riceVariety != null)
        '原料米': [
          master.riceVariety!,
          if (master.riceOrigin != null) master.riceOrigin!,
        ].join(' / '),
      if (master.polishingRatio != null)
        '精米歩合': '${_number(master.polishingRatio!)}%',
      if (master.alcoholPercentage != null)
        'アルコール度数': '${_number(master.alcoholPercentage!)}%',
      if (sakeMeterValue != null)
        '日本酒度':
            '${sakeMeterValue > 0 ? '+' : ''}${_number(sakeMeterValue.toDouble())}',
      if (master.acidity != null) '酸度': _number(master.acidity!),
      if (master.aminoAcid != null) 'アミノ酸度': _number(master.aminoAcid!),
      if (master.pasteurizationType != null) '火入れ': master.pasteurizationType!,
      if (master.availabilityType != null) '流通区分': master.availabilityType!,
      if (master.releaseSeason != null) '販売時期': master.releaseSeason!,
    };
    final tasteAxes = profile == null
        ? const <_TasteAxis>[]
        : <_TasteAxis>[
            _TasteAxis('香り', profile.aroma ?? profile.fruity),
            _TasteAxis('甘み', profile.sweetness),
            _TasteAxis('酸味', profile.acidity),
            _TasteAxis('旨み', profile.umami),
            _TasteAxis('キレ', profile.kire),
          ];
    final pairings = _pairingsFor(
      profile: profile,
      category: category,
      styles: master.styles.map((style) => style.name),
    );
    final breweryName =
        overview?.brewery.name ?? sake?.brewery ?? fallback.brewery;
    final description = sake?.description;
    final recommendationScore =
        sake?.recommendationScore ?? personalRecord?.recommendationScore;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: _BottleImage(
                      url: sake?.primaryImageUrl ?? fallback.primaryImageUrl,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (master.seriesName != null)
                    Text(
                      master.seriesName!,
                      style: const TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    sake?.name ?? fallback.name,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 26,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (breweryName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      breweryName,
                      style: const TextStyle(color: Color(0xFF647184)),
                    ),
                  ],
                  if (category != null) ...[
                    const SizedBox(height: 16),
                    _Tags(values: [category], accent: true),
                  ],
                  if (master.styles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _Tags(
                      values: master.styles.map((style) => style.name).toList(),
                    ),
                  ],
                  if (recommendationScore != null) ...[
                    const SizedBox(height: 14),
                    _RecommendationBadge(score: recommendationScore),
                  ],
                ],
              ),
            ),
            if (personalRecord != null)
              _Section(
                child: _PersonalRecordSection(
                  sake: detailSake,
                  notifier: savedSakeNotifier,
                ),
              ),
            if (tasteAxes.isNotEmpty ||
                master.tasteTags.isNotEmpty ||
                master.aromaTags.isNotEmpty ||
                sake?.taste != null)
              _Section(
                title: '味わいプロフィール',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile != null) ...[
                      _Tags(
                        values: [
                          switch (profile.sourceType) {
                            'ai' || 'ai_estimated' => 'AI推定',
                            'official' => '公式情報',
                            _ => '参考情報',
                          },
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (sake?.taste != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(sake!.taste!),
                      ),
                    if (tasteAxes.isNotEmpty)
                      Center(child: _SakeTasteRadarChart(axes: tasteAxes)),
                    _Tags(
                      values: {
                        ...master.tasteTags,
                        ...master.aromaTags,
                      }.toList(),
                    ),
                  ],
                ),
              ),
            if (description != null && description.trim().isNotEmpty)
              _Section(
                title: 'このお酒について',
                child: Text(
                  description,
                  style: const TextStyle(
                    height: 1.75,
                    color: Color(0xFF404A56),
                  ),
                ),
              ),
            if (pairings.isNotEmpty)
              _Section(
                title: 'この食事に合うかも！',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '味わいプロフィールから選んだ、今日のひと皿です。',
                      style: TextStyle(color: Color(0xFF647184), height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    for (final pairing in pairings)
                      _PairingRow(pairing: pairing),
                  ],
                ),
              ),
            if (specs.isNotEmpty)
              _Section(
                title: '基本スペック',
                child: Column(
                  children: [
                    for (final item in specs.entries)
                      _DetailRow(label: item.key, value: item.value),
                  ],
                ),
              ),
            if (master.recommendedTemperatures.isNotEmpty)
              _Section(
                title: 'おすすめの温度',
                child: _Tags(
                  values: master.recommendedTemperatures,
                  accent: true,
                ),
              ),
            if (master.variants.isNotEmpty)
              _Section(
                title: '容量と参考価格',
                child: Column(
                  children: [
                    for (final variant in master.variants)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_drink_outlined,
                              color: _orange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                variant.volumeMl == null
                                    ? '容量未登録'
                                    : '${variant.volumeMl} ml',
                              ),
                            ),
                            Flexible(
                              child: Text(
                                _price(variant),
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Text(
                      '価格は登録時点の参考情報です。',
                      style: TextStyle(fontSize: 11, color: Color(0xFF647184)),
                    ),
                  ],
                ),
              ),
            if (breweryName != null || overview?.brand.name != null)
              _Section(
                title: '銘柄・蔵元',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overview?.brand.name != null)
                      Text(
                        overview!.brand.name!,
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    if (breweryName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(breweryName),
                      ),
                    if (overview?.brewery.officialUrl != null)
                      _WebLink(
                        url: overview!.brewery.officialUrl!,
                        label: '蔵元の公式サイト',
                      ),
                  ],
                ),
              ),
            if (overview?.relatedProducts.isNotEmpty ?? false)
              _Section(
                title: '同じ銘柄の日本酒',
                child: Column(
                  children: [
                    for (final product in overview!.relatedProducts.where(
                      (p) => p.sakeId > 0,
                    ))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 42,
                          height: 54,
                          child: _BottleImage(url: product.imageUrl),
                        ),
                        title: Text(product.name),
                        subtitle: product.type == null
                            ? null
                            : Text(product.type!),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => Provider<SakeScanRepository>.value(
                              value: context.read<SakeScanRepository>(),
                              child: SakeMasterDetailPage(
                                venueSake: VenueSake(
                                  sakeId: product.sakeId,
                                  name: product.name,
                                  type: product.type,
                                  primaryImageUrl: product.imageUrl,
                                  recordCount: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (master.officialUrl != null || master.sourceUrl != null)
              _WebLink(
                url: master.officialUrl ?? master.sourceUrl!,
                label: '商品情報の出典を見る',
              ),
            if (master.verifiedAt != null)
              Text(
                '${DateFormat('yyyy年M月d日').format(master.verifiedAt!)}確認',
                style: const TextStyle(color: Color(0xFF647184), fontSize: 12),
              ),
            if (master.imageSource == 'yahoo_shopping') ...[
              if (master.imageProductUrl != null)
                _WebLink(
                  url: master.imageProductUrl!,
                  label: '画像の商品をYahoo!ショッピングで見る',
                ),
              const _WebLink(
                url: 'https://developer.yahoo.co.jp/sitemap/',
                label: 'Webサービス by Yahoo! JAPAN',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MasterSaveButton extends StatelessWidget {
  const _MasterSaveButton({required this.venueSake, required this.notifier});
  final VenueSake venueSake;
  final SavedSakeNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    final savedNotifier = notifier;
    if (savedNotifier == null) return const SizedBox.shrink();
    final isSaved = savedNotifier.state.savedSakeList.any(
      (item) => item.name == venueSake.name && item.type == venueSake.type,
    );
    return IconButton(
      tooltip: isSaved ? context.l10n.removeSavedSake : context.l10n.saveSake,
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_outline,
        color: isSaved ? Colors.amberAccent : Colors.white,
      ),
      onPressed: () async {
        if (!isSaved && savedNotifier.hasReachedGuestLimit) {
          await GuestLimitDialog.showSavedSakeLimit(
            context,
            maxCount: SavedSakeNotifier.guestSavedLimit,
          );
          return;
        }
        if (!isSaved && savedNotifier.hasReachedMemberLimit) {
          SnackBarUtils.showWarningSnackBar(
            context,
            message: context.l10n.savedSakeLimit(
              SavedSakeNotifier.memberSavedLimit,
            ),
          );
          return;
        }
        try {
          await savedNotifier.toggleSavedSake(_asSake(venueSake));
          if (!isSaved && context.mounted) {
            SnackBarUtils.showInfoSnackBar(
              context,
              message: context.l10n.savedToMyPage,
            );
          }
        } on SavedSakeGuestLimitReachedException {
          if (!context.mounted) return;
          await GuestLimitDialog.showSavedSakeLimit(
            context,
            maxCount: SavedSakeNotifier.guestSavedLimit,
          );
        } on SavedSakeMemberLimitReachedException {
          if (!context.mounted) return;
          SnackBarUtils.showWarningSnackBar(
            context,
            message: context.l10n.savedSakeLimit(
              SavedSakeNotifier.memberSavedLimit,
            ),
          );
        }
      },
    );
  }
}

class _MasterFavoriteButton extends StatelessWidget {
  const _MasterFavoriteButton({
    required this.venueSake,
    required this.notifier,
  });
  final VenueSake venueSake;
  final FavoriteNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    final favoriteNotifier = notifier;
    if (favoriteNotifier == null) return const SizedBox.shrink();
    final isFavorite = favoriteNotifier.state.myFavoriteList.any(
      (item) => item.name == venueSake.name && item.type == venueSake.type,
    );
    return IconButton(
      tooltip: context.l10n.favoriteSake,
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.redAccent : Colors.white,
      ),
      onPressed: () async {
        if (!isFavorite && favoriteNotifier.hasReachedGuestLimit) {
          await GuestLimitDialog.showFavoriteLimit(
            context,
            maxCount: FavoriteNotifier.guestFavoriteLimit,
          );
          return;
        }
        try {
          await favoriteNotifier.addOrRemoveFavorite(
            FavoriteSake(name: venueSake.name, type: venueSake.type),
          );
        } on FavoriteGuestLimitReachedException {
          if (!context.mounted) return;
          await GuestLimitDialog.showFavoriteLimit(
            context,
            maxCount: FavoriteNotifier.guestFavoriteLimit,
          );
        }
      },
    );
  }
}

Sake _asSake(VenueSake venueSake) => Sake(
  sakeId: venueSake.sakeId,
  name: venueSake.name,
  brewery: venueSake.brewery,
  type: venueSake.type,
  primaryImageUrl: venueSake.primaryImageUrl,
);

class _MasterRecordCta extends StatelessWidget {
  const _MasterRecordCta({required this.sake, required this.notifier});
  final Sake sake;
  final SavedSakeNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    final savedNotifier = notifier;
    if (savedNotifier == null || _isSaved(savedNotifier, sake)) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: FilledButton.icon(
        onPressed: () => _addSakeRecord(context, savedNotifier, sake),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: _navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('このお酒を記録する'),
      ),
    );
  }
}

bool _isSaved(SavedSakeNotifier notifier, Sake sake) => notifier
    .state
    .savedSakeList
    .any((candidate) => _isSameSakeIdentity(candidate, sake));

bool _isSameSakeIdentity(Sake candidate, Sake sake) {
  if (sake.sakeId != null && candidate.sakeId == sake.sakeId) return true;
  final candidateName = _normalizedSakeName(candidate.name);
  final sakeName = _normalizedSakeName(sake.name);
  if (candidateName.isEmpty || candidateName != sakeName) return false;
  final candidateType = candidate.type?.trim();
  final sakeType = sake.type?.trim();
  return candidateType == null ||
      candidateType.isEmpty ||
      sakeType == null ||
      sakeType.isEmpty ||
      candidateType == sakeType;
}

String _normalizedSakeName(String? name) =>
    (name ?? '').replaceAll(RegExp(r'\s+'), '');

Future<void> _addSakeRecord(
  BuildContext context,
  SavedSakeNotifier notifier,
  Sake sake,
) async {
  if (notifier.hasReachedGuestLimit) {
    await GuestLimitDialog.showSavedSakeLimit(
      context,
      maxCount: SavedSakeNotifier.guestSavedLimit,
    );
    return;
  }
  if (notifier.hasReachedMemberLimit) {
    SnackBarUtils.showWarningSnackBar(
      context,
      message: context.l10n.savedSakeLimit(SavedSakeNotifier.memberSavedLimit),
    );
    return;
  }
  try {
    await notifier.toggleSavedSake(sake);
    if (!context.mounted) return;
    SnackBarUtils.showInfoSnackBar(
      context,
      message: context.l10n.savedToMyPage,
    );
  } on SavedSakeGuestLimitReachedException {
    if (!context.mounted) return;
    await GuestLimitDialog.showSavedSakeLimit(
      context,
      maxCount: SavedSakeNotifier.guestSavedLimit,
    );
  } on SavedSakeMemberLimitReachedException {
    if (!context.mounted) return;
    SnackBarUtils.showWarningSnackBar(
      context,
      message: context.l10n.savedSakeLimit(SavedSakeNotifier.memberSavedLimit),
    );
  }
}

class _PersonalRecordSection extends StatelessWidget {
  const _PersonalRecordSection({required this.sake, required this.notifier});
  final Sake sake;
  final SavedSakeNotifier? notifier;

  @override
  Widget build(BuildContext context) {
    final savedNotifier = notifier;
    if (savedNotifier == null) return const SizedBox.shrink();
    final saved = _findSavedSake(savedNotifier, sake);
    if (saved == null) return const SizedBox.shrink();
    final Sake record = saved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'あなたの記録'),
        const SizedBox(height: 16),
        _InlineRecordEditor(notifier: savedNotifier, sake: record),
      ],
    );
  }
}

Sake? _findSavedSake(SavedSakeNotifier? notifier, Sake sake) {
  if (notifier == null) return null;
  for (final candidate in notifier.state.savedSakeList) {
    if (_isSameSakeIdentity(candidate, sake)) return candidate;
  }
  return null;
}

class _RecommendationBadge extends StatelessWidget {
  const _RecommendationBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final isRecommended = score >= 6;
    final label = score >= 8
        ? 'かなりおすすめ'
        : isRecommended
        ? 'おすすめのお酒'
        : 'おすすめ度 $score / 10';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isRecommended
            ? const Color(0xFFFFF3E7)
            : const Color(0xFFF3F6F9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecommended ? Icons.recommend_rounded : Icons.star_outline,
            color: isRecommended ? _orange : const Color(0xFF647184),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isRecommended ? _navy : const Color(0xFF536174),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 3, height: 18, color: _orange),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    ],
  );
}

class _RecordLine extends StatelessWidget {
  const _RecordLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: _orange),
      const SizedBox(width: 7),
      Expanded(
        child: Text(text, style: const TextStyle(color: Color(0xFF404A56))),
      ),
    ],
  );
}

class _RecordImages extends StatelessWidget {
  const _RecordImages({required this.paths});
  final List<String> paths;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 82,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: paths.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final path = paths[index];
        final image = path.startsWith('http://') || path.startsWith('https://')
            ? Image.network(path, fit: BoxFit.cover)
            : Image.file(File(path), fit: BoxFit.cover);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 82, child: image),
        );
      },
    ),
  );
}

class _InlineRecordEditor extends StatefulWidget {
  const _InlineRecordEditor({required this.notifier, required this.sake});
  final SavedSakeNotifier notifier;
  final Sake sake;

  @override
  State<_InlineRecordEditor> createState() => _InlineRecordEditorState();
}

class _InlineRecordEditorState extends State<_InlineRecordEditor> {
  late final TextEditingController _impressionController;
  late final TextEditingController _placeController;
  late Set<String> _tags;
  DrinkingPlace? _selectedPlace;
  bool _isSaving = false;
  bool _isVisibilityUpdating = false;
  bool _isAddingImage = false;

  @override
  void initState() {
    super.initState();
    _impressionController = TextEditingController(
      text: widget.sake.impression ?? '',
    );
    _placeController = TextEditingController(
      text: widget.sake.drinkingPlace?.displayName ?? widget.sake.place ?? '',
    );
    _selectedPlace = widget.sake.drinkingPlace;
    _tags = {...(widget.sake.userTags ?? const <String>[])};
  }

  @override
  void dispose() {
    _impressionController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final place = _placeController.text.trim();
    final updated = widget.sake.copyWith(
      impression: _impressionController.text.trim(),
      place: place.isEmpty ? null : place,
      drinkingPlace: _selectedPlace,
      userTags: _tags.toList(growable: false),
    );
    await widget.notifier.updateSavedSake(updated);
    final savedId = updated.savedId;
    if (savedId != null &&
        savedId.isNotEmpty &&
        updated.syncStatus == SavedSakeSyncStatus.serverSynced) {
      await widget.notifier.syncSavedSakeToServer(savedId);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    SnackBarUtils.showInfoSnackBar(context, message: '記録を保存しました。');
  }

  Future<void> _selectPlace() async {
    FocusScope.of(context).unfocus();
    final place = await PlacePickerSheet.show(
      context,
      initialPlace: _placeController.text.trim(),
    );
    if (!mounted || place == null || place.displayName.trim().isEmpty) return;
    setState(() {
      _selectedPlace = place;
      _placeController.text = place.displayName.trim();
    });
  }

  Future<void> _updateTimelineVisibility(bool isPublic) async {
    final savedId = widget.sake.savedId;
    if (savedId == null ||
        savedId.isEmpty ||
        widget.sake.syncStatus != SavedSakeSyncStatus.serverSynced) {
      SnackBarUtils.showWarningSnackBar(
        context,
        message: '記録の同期後にタイムライン表示を設定できます。',
      );
      return;
    }
    setState(() => _isVisibilityUpdating = true);
    final success = await widget.notifier.updateTimelineVisibility(
      savedId: savedId,
      isPublic: isPublic,
    );
    if (!mounted) return;
    setState(() => _isVisibilityUpdating = false);
    if (!success) {
      SnackBarUtils.showWarningSnackBar(
        context,
        message: 'タイムライン表示を更新できませんでした。ログイン状態を確認してください。',
      );
    }
  }

  Future<void> _showImageSourceSheet() async {
    if ((widget.sake.imagePaths ?? const <String>[]).length >= 3) {
      SnackBarUtils.showWarningSnackBar(context, message: '写真は3枚まで追加できます。');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: _navy),
              title: const Text('カメラで撮る'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _navy),
              title: const Text('写真ライブラリから選ぶ'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    await _pickMemoryImage(source);
  }

  Future<void> _pickMemoryImage(ImageSource source) async {
    final savedId = widget.sake.savedId;
    if (savedId == null ||
        savedId.isEmpty ||
        widget.sake.syncStatus != SavedSakeSyncStatus.serverSynced) {
      SnackBarUtils.showWarningSnackBar(context, message: '写真は記録の同期後に追加できます。');
      return;
    }
    setState(() => _isAddingImage = true);
    try {
      final picked = await CustomImagePicker.pickImage(source: source);
      if (!mounted || picked == null) return;
      final cropped = await ImageCropperService.cropAndRotateImage(picked.path);
      final path = await ImageCropperService.saveImagePermanently(
        cropped ?? picked,
        'saved_sake',
      );
      if (!mounted || path == null) return;
      final updated = await widget.notifier.addImageToSavedSake(
        savedId: savedId,
        localPath: path,
      );
      if (!mounted) return;
      if (updated == null) {
        SnackBarUtils.showWarningSnackBar(context, message: '写真を追加できませんでした。');
      }
    } finally {
      if (mounted) setState(() => _isAddingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '今日の一杯、どうだった？',
        style: TextStyle(
          color: _navy,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _impressionController,
        maxLength: 200,
        maxLines: 4,
        textAlign: TextAlign.start,
        style: const TextStyle(color: _navy, height: 1.5),
        decoration: InputDecoration(
          hintText: '香りや味、食事との相性を残す',
          hintStyle: const TextStyle(color: Color(0xFF8B96A6)),
          filled: true,
          fillColor: const Color(0xFFF7F8FA),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        '飲んだ場所',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Material(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _selectPlace,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.near_me_outlined, color: _orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _placeController.text.trim().isEmpty
                        ? '現在地・店舗名から選ぶ'
                        : _placeController.text.trim(),
                    style: TextStyle(
                      color: _placeController.text.trim().isEmpty
                          ? const Color(0xFF647184)
                          : _navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF647184)),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'タイムラインに表示',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          const Expanded(
            child: Text(
              'みんなのタイムラインにこの記録を表示します。',
              style: TextStyle(
                color: Color(0xFF647184),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          Switch.adaptive(
            value: widget.sake.isPublic,
            onChanged: _isVisibilityUpdating ? null : _updateTimelineVisibility,
            activeColor: _orange,
          ),
        ],
      ),
      if (widget.sake.syncStatus != SavedSakeSyncStatus.serverSynced)
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            '同期が完了すると公開設定を変更できます。',
            style: TextStyle(color: Color(0xFF8B96A6), fontSize: 12),
          ),
        ),
      const SizedBox(height: 8),
      const Text(
        'タグ',
        style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sake_master.Sake.userMemoTags
            .map(
              (tag) => FilterChip(
                label: Text(tag),
                selected: _tags.contains(tag),
                onSelected: (selected) => setState(() {
                  selected ? _tags.add(tag) : _tags.remove(tag);
                }),
              ),
            )
            .toList(growable: false),
      ),
      if ((widget.sake.imagePaths ?? const <String>[]).isNotEmpty) ...[
        const SizedBox(height: 20),
        const Text(
          '写真',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _RecordImages(paths: widget.sake.imagePaths!),
      ],
      const SizedBox(height: 20),
      const Text(
        '思い出をのこそう',
        style: TextStyle(
          color: _navy,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'その日の景色や料理も、一緒に残せます。',
        style: TextStyle(color: Color(0xFF647184), fontSize: 13),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _isAddingImage ? null : _showImageSourceSheet,
        style: OutlinedButton.styleFrom(
          foregroundColor: _navy,
          side: const BorderSide(color: Color(0xFFFFC58F)),
          minimumSize: const Size.fromHeight(46),
        ),
        icon: _isAddingImage
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_a_photo_outlined),
        label: Text(_isAddingImage ? '追加中…' : '写真を追加'),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _isSaving ? null : _save,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: _orange,
        ),
        child: Text(_isSaving ? '保存中…' : '記録を保存'),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.title});
  final Widget child;
  final String? title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Container(width: 3, height: 18, color: _orange),
              const SizedBox(width: 10),
              Text(
                title!,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        child,
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Divider(height: 1, color: Color(0xFFE5EAF0)),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF647184)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: Color(0xFFE5EAF0)),
    ],
  );
}

class _Tags extends StatelessWidget {
  const _Tags({required this.values, this.accent = false});
  final List<String> values;
  final bool accent;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: values
        .where((v) => v.trim().isNotEmpty)
        .map(
          (value) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: accent ? const Color(0xFFFFEEE1) : const Color(0xFFF0F3F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: accent ? _orange : _navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _BottleImage extends StatelessWidget {
  const _BottleImage({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Image.asset(
      'assets/images/sake_placeholder.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.wine_bar_outlined, color: _navy),
    );
    return url == null || url!.trim().isEmpty
        ? placeholder()
        : Image.network(
            url!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => placeholder(),
          );
  }
}

class _WebLink extends StatelessWidget {
  const _WebLink({required this.url, required this.label});
  final String url;
  final String label;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(label),
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri == null || !['https', 'http'].contains(uri.scheme)) return;
        try {
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (opened || !context.mounted) return;
        } catch (_) {
          if (!context.mounted) return;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした。')));
        }
      },
    ),
  );
}

class _TasteAxis {
  const _TasteAxis(this.label, this.value);

  final String label;
  final double value;
}

class _SakeTasteRadarChart extends StatelessWidget {
  const _SakeTasteRadarChart({required this.axes});

  final List<_TasteAxis> axes;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, progress, _) => LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 248.0);
        final radius = size * .31;
        return SizedBox(
          key: const Key('sake-taste-radar-chart'),
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _SakeTasteRadarPainter(
                  axes: axes,
                  radius: radius,
                  progress: progress,
                ),
              ),
              for (var index = 0; index < axes.length; index++)
                _RadarLabel(
                  axis: axes[index],
                  index: index,
                  total: axes.length,
                  size: size,
                  radius: radius,
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _RadarLabel extends StatelessWidget {
  const _RadarLabel({
    required this.axis,
    required this.index,
    required this.total,
    required this.size,
    required this.radius,
  });

  final _TasteAxis axis;
  final int index;
  final int total;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi / 2 + (2 * math.pi * index) / total;
    final labelRadius = radius + 34;
    const labelWidth = 62.0;
    final left = (size / 2 + math.cos(angle) * labelRadius - labelWidth / 2)
        .clamp(0.0, size - labelWidth);
    final top = (size / 2 + math.sin(angle) * labelRadius - 14).clamp(
      0.0,
      size - 28,
    );
    return Positioned(
      left: left,
      top: top,
      width: labelWidth,
      child: Text(
        axis.label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _navy,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SakeTasteRadarPainter extends CustomPainter {
  const _SakeTasteRadarPainter({
    required this.axes,
    required this.radius,
    required this.progress,
  });

  final List<_TasteAxis> axes;
  final double radius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = 2 * math.pi / axes.length;
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE5EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFE8EDF4)
      ..strokeWidth = 1;

    for (var level = 1; level <= 4; level++) {
      canvas.drawPath(
        _polygonPath(
          center: center,
          count: axes.length,
          radius: radius * level / 4,
        ),
        gridPaint,
      );
    }
    for (var index = 0; index < axes.length; index++) {
      canvas.drawLine(
        center,
        _point(center, radius, index, angleStep),
        axisPaint,
      );
    }

    final path = Path();
    for (var index = 0; index < axes.length; index++) {
      final value = axes[index].value.clamp(0.0, 1.0) * progress;
      final point = _point(center, radius * value, index, angleStep);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final bounds = Rect.fromCircle(center: center, radius: radius);
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD96A).withValues(alpha: .72),
          const Color(0xFFFF8B5A).withValues(alpha: .38),
          const Color(0xFFBE6DE0).withValues(alpha: .24),
        ],
      ).createShader(bounds);
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA13C), Color(0xFFE95C9A), Color(0xFF8D6CDB)],
      ).createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  Path _polygonPath({
    required Offset center,
    required int count,
    required double radius,
  }) {
    final path = Path();
    final angleStep = 2 * math.pi / count;
    for (var index = 0; index < count; index++) {
      final point = _point(center, radius, index, angleStep);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Offset _point(Offset center, double radius, int index, double angleStep) {
    final angle = -math.pi / 2 + angleStep * index;
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _SakeTasteRadarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.axes != axes;
}

class _Pairing {
  const _Pairing({
    required this.icon,
    required this.title,
    required this.reason,
  });

  final IconData icon;
  final String title;
  final String reason;
}

class _PairingRow extends StatelessWidget {
  const _PairingRow({required this.pairing});

  final _Pairing pairing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(pairing.icon, color: _orange, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pairing.title,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                pairing.reason,
                style: const TextStyle(color: Color(0xFF647184), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

List<_Pairing> _pairingsFor({
  required SakeTasteProfileDetails? profile,
  required String? category,
  required Iterable<String> styles,
}) {
  if (profile == null) return const <_Pairing>[];

  final styleText = styles.join(' ');
  final pairings = <_Pairing>[];
  void add(_Pairing pairing) {
    if (pairings.every((item) => item.title != pairing.title)) {
      pairings.add(pairing);
    }
  }

  if (profile.kire >= .62 || profile.dryness >= .62) {
    add(
      const _Pairing(
        icon: Icons.set_meal_outlined,
        title: 'お刺身・白身魚の塩焼き',
        reason: 'すっきりしたキレが、魚の繊細な旨みを引き立てます。',
      ),
    );
    add(
      const _Pairing(
        icon: Icons.outdoor_grill_outlined,
        title: '焼き鳥（塩）',
        reason: '香ばしさを受け止めながら、後味を軽やかに整えます。',
      ),
    );
  }
  if (profile.umami >= .62 || (profile.body ?? 0) >= .62) {
    add(
      const _Pairing(
        icon: Icons.restaurant_outlined,
        title: 'ぶり大根・煮付け',
        reason: 'ふくらみのある旨みが、だしの効いた味付けによく合います。',
      ),
    );
    add(
      const _Pairing(
        icon: Icons.rice_bowl_outlined,
        title: 'きのこの炊き込みご飯',
        reason: '米由来のコクを、きのこの香りと一緒に楽しめます。',
      ),
    );
  }
  if (profile.fruity >= .62 || (profile.aroma ?? 0) >= .62) {
    add(
      const _Pairing(
        icon: Icons.spa_outlined,
        title: '生ハムとクリームチーズ',
        reason: '華やかな香りに、ほどよい塩味とミルキーなコクが寄り添います。',
      ),
    );
  }
  if (profile.sweetness >= .62) {
    add(
      const _Pairing(
        icon: Icons.lunch_dining_outlined,
        title: '鶏の照り焼き',
        reason: '甘辛いタレと重なり、やわらかな余韻を楽しめます。',
      ),
    );
  }
  if (profile.acidity >= .62 || styleText.contains('生')) {
    add(
      const _Pairing(
        icon: Icons.local_fire_department_outlined,
        title: '天ぷら',
        reason: '爽やかな酸味が、揚げ物の香ばしさを軽快にまとめます。',
      ),
    );
  }
  if (pairings.isEmpty) {
    add(
      _Pairing(
        icon: Icons.rice_bowl_outlined,
        title: category == null ? '和食の定食' : '$categoryのやさしい和食',
        reason: '主張しすぎない味わいなので、季節の小鉢やご飯と気軽にどうぞ。',
      ),
    );
  }
  return pairings.take(3).toList(growable: false);
}

String _number(double value) => value == value.truncateToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String _price(SakeProductVariant variant) {
  if (variant.suggestedPrice == null) return '価格未登録';
  final currency = variant.currency ?? 'JPY';
  final amount = NumberFormat.currency(
    locale: 'ja_JP',
    name: currency,
    symbol: currency == 'JPY' ? '¥' : currency,
  ).format(variant.suggestedPrice);
  return '$amount${variant.taxIncluded == true
      ? '（税込）'
      : variant.taxIncluded == false
      ? '（税別）'
      : ''}';
}
