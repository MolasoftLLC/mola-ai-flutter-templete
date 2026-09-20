import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common/utils/sake_image_utils.dart';
import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../my_page/saved_sake_detail_page.dart';
import '../sake_map/sake_master_detail_page.dart';

const _navy = Color(0xFF143861);
const _orange = Color(0xFFFF7A1A);
const _muted = Color(0xFF647184);

class RecentSakeListPage extends StatefulWidget {
  const RecentSakeListPage({super.key});

  @override
  State<RecentSakeListPage> createState() => _RecentSakeListPageState();
}

class _RecentSakeListPageState extends State<RecentSakeListPage> {
  static const _pageSize = 20;

  final _scrollController = ScrollController();
  final Map<String, Future<Map<int, SakeTasteProfileDetails>>> _profileCache =
      {};
  final Set<String> _expandedRecordKeys = {};
  var _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageIfNeeded);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadNextPageIfNeeded() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 400) {
      return;
    }
    final total = context.read<SavedSakeState>().savedSakeList.length;
    if (_visibleCount >= total) return;
    setState(() {
      _visibleCount = math.min(_visibleCount + _pageSize, total);
    });
  }

  Future<Map<int, SakeTasteProfileDetails>> _profilesFor(List<Sake> sakes) {
    final ids =
        sakes
            .map((sake) => sake.sakeId ?? 0)
            .where((id) => id > 0)
            .toSet()
            .toList()
          ..sort();
    if (ids.isEmpty) return Future.value(<int, SakeTasteProfileDetails>{});
    return _profileCache.putIfAbsent(
      ids.join(','),
      () => context.read<SakeScanRepository>().fetchTasteProfiles(ids),
    );
  }

  Future<void> _refresh() async {
    _profileCache.clear();
    if (mounted) setState(() => _visibleCount = _pageSize);
    await context.read<SavedSakeNotifier>().refreshFromServer();
  }

  Future<void> _openDetail(Sake sake) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedSakeDetailPage.forSake(sake),
      ),
    );
    if (!mounted) return;
    await context.read<SavedSakeNotifier>().refreshFromServer();
  }

  @override
  Widget build(BuildContext context) {
    final allSakes = context.select(
      (SavedSakeState state) => state.savedSakeList,
    );
    final visibleSakes = allSakes.take(_visibleCount).toList(growable: false);
    final preference = Provider.of<MyPageState?>(context)?.tasteProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          '最近調べたお酒',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        color: _navy,
        onRefresh: _refresh,
        child: allSakes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      '調べたお酒はまだありません',
                      style: TextStyle(color: _muted),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
                itemCount: visibleSakes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sake = visibleSakes[index];
                  final recordKey =
                      sake.savedId ?? 'sake:${sake.sakeId ?? index}';
                  final profilesFuture = _profilesFor(visibleSakes);
                  return _RecentSakeCard(
                    sake: sake,
                    profileFuture: sake.sakeId == null
                        ? null
                        : profilesFuture.then(
                            (profiles) => profiles[sake.sakeId!],
                          ),
                    preference: preference,
                    isExpanded: _expandedRecordKeys.contains(recordKey),
                    onOpen: () => _openDetail(sake),
                    onToggleRecord: () => setState(() {
                      if (!_expandedRecordKeys.add(recordKey)) {
                        _expandedRecordKeys.remove(recordKey);
                      }
                    }),
                  );
                },
              ),
      ),
    );
  }
}

class _RecentSakeCard extends StatelessWidget {
  const _RecentSakeCard({
    required this.sake,
    required this.profileFuture,
    required this.preference,
    required this.isExpanded,
    required this.onOpen,
    required this.onToggleRecord,
  });

  final Sake sake;
  final Future<SakeTasteProfileDetails?>? profileFuture;
  final TastePreferenceProfile? preference;
  final bool isExpanded;
  final VoidCallback onOpen;
  final VoidCallback onToggleRecord;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 96,
                      height: 152,
                      child: _RecordImage(sake: sake),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name(sake),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 17,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (sake.brewery?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 3),
                          Text(
                            sake.brewery!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _ProfilePreview(
                          profileFuture: profileFuture,
                          preference: preference,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Icon(Icons.chevron_right, color: Color(0xFF9AA4B2)),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF3)),
          InkWell(
            onTap: onToggleRecord,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, size: 19, color: _muted),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      '記録した内容',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: isExpanded
                ? _RecordedContent(sake: sake)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({
    required this.profileFuture,
    required this.preference,
  });

  final Future<SakeTasteProfileDetails?>? profileFuture;
  final TastePreferenceProfile? preference;

  @override
  Widget build(BuildContext context) {
    final future = profileFuture;
    if (future == null) return const _ProfileUnavailable();
    return FutureBuilder<SakeTasteProfileDetails?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 92,
            child: Center(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _orange,
                ),
              ),
            ),
          );
        }
        final profile = snapshot.data;
        if (profile == null) return const _ProfileUnavailable();
        final match = preference == null
            ? null
            : calculateSakeTastePreferenceMatchPercent(
                profile: profile,
                preference: preference!,
              );
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'あなたの好みマッチ度',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
                    ).createShader(bounds),
                    child: Text(
                      match == null ? '--' : '$match%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _CompactTasteRadar(profile: profile, preference: preference),
          ],
        );
      },
    );
  }
}

class _ProfileUnavailable extends StatelessWidget {
  const _ProfileUnavailable();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 92,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '味わいプロフィールを取得中',
        style: TextStyle(color: _muted, fontSize: 12),
      ),
    ),
  );
}

class _RecordedContent extends StatelessWidget {
  const _RecordedContent({required this.sake});

  final Sake sake;

  @override
  Widget build(BuildContext context) {
    final place = (sake.drinkingPlace?.displayName ?? sake.place)?.trim();
    final impression = sake.impression?.trim();
    final tags = sake.userTags ?? const <String>[];
    final ratings = sake.personalTasteRatings ?? const <String, int>{};
    final hasContent =
        place?.isNotEmpty == true ||
        impression?.isNotEmpty == true ||
        tags.isNotEmpty ||
        ratings.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
      color: const Color(0xFFFAFBFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasContent)
            const Text(
              '場所や感想はまだ記録されていません。',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          if (place?.isNotEmpty == true)
            _RecordLine(icon: Icons.place_outlined, text: place!),
          if (impression?.isNotEmpty == true)
            _RecordLine(icon: Icons.chat_bubble_outline, text: impression!),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: _orange, fontSize: 11),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (ratings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _ratingSummary(ratings),
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.5),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                sake.isPublic ? Icons.public : Icons.lock_outline,
                size: 15,
                color: _muted,
              ),
              const SizedBox(width: 5),
              Text(
                sake.isPublic ? 'タイムラインに公開' : '自分だけに表示',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              const Spacer(),
              if (_savedDate(context, sake) case final date?)
                Text(date, style: const TextStyle(color: _muted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordLine extends StatelessWidget {
  const _RecordLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _muted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF404A56), height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class _RecordImage extends StatelessWidget {
  const _RecordImage({required this.sake});

  final Sake sake;

  @override
  Widget build(BuildContext context) {
    final path = _preferredImagePath(sake);
    if (path == null) return _placeholder();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    final file = File(path);
    return file.existsSync()
        ? Image.file(file, fit: BoxFit.cover, cacheWidth: 300)
        : _placeholder();
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF1F3F5),
    alignment: Alignment.center,
    child: Image.asset('assets/images/sake_placeholder.png'),
  );
}

class _CompactTasteRadar extends StatelessWidget {
  const _CompactTasteRadar({required this.profile, required this.preference});

  final SakeTasteProfileDetails profile;
  final TastePreferenceProfile? preference;

  @override
  Widget build(BuildContext context) {
    final values = _profileValues(profile);
    final preferenceValues = preference == null
        ? null
        : _preferenceValues(preference!);
    const size = 92.0;
    const radius = 28.0;
    const labels = ['香り', '甘み', '酸味', 'コク', 'キレ', '辛さ'];
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size.square(size),
            painter: _CompactRadarPainter(
              values: values,
              preferenceValues: preferenceValues,
              radius: radius,
            ),
          ),
          for (var index = 0; index < labels.length; index++)
            _CompactRadarLabel(
              label: labels[index],
              index: index,
              size: size,
              radius: radius,
            ),
        ],
      ),
    );
  }
}

class _CompactRadarLabel extends StatelessWidget {
  const _CompactRadarLabel({
    required this.label,
    required this.index,
    required this.size,
    required this.radius,
  });

  final String label;
  final int index;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi / 2 + math.pi * 2 * index / 6;
    final labelRadius = radius + 11;
    const width = 28.0;
    final left = (size / 2 + math.cos(angle) * labelRadius - width / 2).clamp(
      0.0,
      size - width,
    );
    final top = (size / 2 + math.sin(angle) * labelRadius - 5).clamp(
      0.0,
      size - 10,
    );
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _navy,
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompactRadarPainter extends CustomPainter {
  const _CompactRadarPainter({
    required this.values,
    required this.radius,
    this.preferenceValues,
  });

  final List<double> values;
  final List<double>? preferenceValues;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final grid = Paint()
      ..color = const Color(0xFFDCE5EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var level = 1; level <= 4; level++) {
      canvas.drawPath(_path(center, radius * level / 4, null), grid);
    }
    final user = preferenceValues;
    if (user != null) {
      final path = _path(center, radius, user);
      canvas
        ..drawPath(
          path,
          Paint()..color = const Color(0xFF65C7FF).withValues(alpha: .25),
        )
        ..drawPath(
          path,
          Paint()
            ..color = const Color(0xFF2E8BFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }
    final sakePath = _path(center, radius, values);
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas
      ..drawPath(
        sakePath,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xB8FFD96A), Color(0x55E95C9A)],
          ).createShader(bounds),
      )
      ..drawPath(
        sakePath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFA13C), Color(0xFFE95C9A), Color(0xFF8D6CDB)],
          ).createShader(bounds)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
  }

  Path _path(Offset center, double radius, List<double>? source) {
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + math.pi * 2 * index / 6;
      final scaledRadius = radius * (source?[index].clamp(0, 1) ?? 1);
      final point = Offset(
        center.dx + math.cos(angle) * scaledRadius,
        center.dy + math.sin(angle) * scaledRadius,
      );
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _CompactRadarPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.preferenceValues != preferenceValues ||
      oldDelegate.radius != radius;
}

List<double> _profileValues(SakeTasteProfileDetails profile) => [
  profile.fruity,
  profile.sweetness,
  profile.acidity,
  profile.body ?? profile.umami,
  profile.kire,
  profile.dryness,
];

List<double> _preferenceValues(TastePreferenceProfile preference) => [
  preference.fruity,
  preference.sweetness,
  preference.acidity,
  preference.umami,
  preference.kire,
  preference.spiciness,
];

String _name(Sake sake) {
  final name = sake.name?.trim();
  return name?.isNotEmpty == true ? name! : '名称不明の日本酒';
}

String? _preferredImagePath(Sake sake) {
  return preferredSakeImagePath(
    personalImagePaths: sake.imagePaths,
    thumbnailImageUrl: sake.thumbnailImageUrl,
    primaryImageUrl: sake.primaryImageUrl,
  );
}

String _ratingSummary(Map<String, int> ratings) {
  const labels = {
    'fruity': 'フルーティ',
    'sweetness': '甘み',
    'acidity': '酸味',
    'umami': 'コク',
    'kire': 'キレ',
    'spiciness': '辛さ',
  };
  return ratings.entries
      .where((entry) => labels.containsKey(entry.key))
      .map((entry) => '${labels[entry.key]} ${entry.value}/5')
      .join('  ');
}

String? _savedDate(BuildContext context, Sake sake) {
  final savedId = sake.savedId;
  if (savedId == null) return null;
  final parts = savedId.split('_');
  if (parts.length < 3) return null;
  final millis = int.tryParse(parts[1]);
  if (millis == null) return null;
  return DateFormat.yMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}
