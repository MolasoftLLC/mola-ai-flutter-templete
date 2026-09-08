import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/repository/place_map_repository.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../common/widgets/primary_app_bar.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _fetch();
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
    appBar: const PrimaryAppBar(title: '日本酒詳細'),
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
            _Details(overview: snapshot.data, fallback: widget.venueSake),
          ],
        ),
      ),
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({required this.overview, required this.fallback});
  final SakeOverview? overview;
  final VenueSake fallback;

  @override
  Widget build(BuildContext context) {
    final sake = overview?.sake;
    final master = overview?.master ?? const SakeMasterDetails();
    final profile = master.tasteProfile;
    final category =
        master.category ??
        master.specialDesignation ??
        sake?.type ??
        fallback.type;
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
      if (master.sakeMeterValue != null)
        '日本酒度':
            '${master.sakeMeterValue! > 0 ? '+' : ''}${_number(master.sakeMeterValue!)}',
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
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _BottleImage(
                      url: sake?.primaryImageUrl ?? fallback.primaryImageUrl,
                    ),
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
            if (pairings.isNotEmpty)
              _Section(
                title: 'ご飯に合うかも！',
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
          ],
        ),
      ),
    );
  }
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
