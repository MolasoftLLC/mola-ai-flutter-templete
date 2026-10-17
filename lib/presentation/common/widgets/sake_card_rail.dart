import '../../../common/sake/taste_match.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/analytics/app_analytics.dart';
import '../../../common/localization/localization_extensions.dart';
import '../../../common/utils/sake_image_utils.dart';
import '../../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../../domain/eintities/sake_label_scan.dart';
import '../../../domain/notifier/my_page/my_page_notifier.dart';

const _brandColor = Color(0xFF143861);
const _bodyTextColor = Color(0xFF404040);
const _sakeCardRailHeight = 275.0;

class SakeCardRail extends StatelessWidget {
  const SakeCardRail({
    super.key,
    required this.sakes,
    required this.profilesFuture,
    required this.subtitleBuilder,
    required this.actionBuilder,
    required this.onTap,
    this.footerBuilder,
    this.compact = false,
    required this.analyticsTarget,
    this.analyticsScreen = 'home',
  });

  final List<Sake> sakes;
  final bool compact;
  final String analyticsTarget;
  final String analyticsScreen;
  final Future<Map<int, SakeTasteProfileDetails>> profilesFuture;
  final String? Function(Sake sake) subtitleBuilder;
  final String? Function(Sake sake)? footerBuilder;
  final Widget Function(Sake sake) actionBuilder;
  final ValueChanged<Sake> onTap;

  @override
  Widget build(BuildContext context) {
    return AnalyticsExposure(
      target: analyticsTarget,
      child: SizedBox(
        height: compact
            ? 134 + MediaQuery.textScalerOf(context).scale(13) * 4.2
            : _sakeCardRailHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: sakes.length,
          separatorBuilder: (_, __) => SizedBox(width: compact ? 16 : 30),
          itemBuilder: (context, index) {
            final sake = sakes[index];
            return _SakeCard(
              compact: compact,
              sake: sake,
              profileFuture: sake.sakeId == null
                  ? null
                  : profilesFuture.then((profiles) => profiles[sake.sakeId!]),
              subtitle: subtitleBuilder(sake),
              footer: footerBuilder?.call(sake),
              action: actionBuilder(sake),
              onTap: () {
                AppAnalytics.instance.event(
                  analyticsScreen,
                  analyticsTarget,
                  source: analyticsScreen,
                );
                onTap(sake);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SakeCard extends StatelessWidget {
  const _SakeCard({
    required this.sake,
    required this.profileFuture,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.footer,
    this.compact = false,
  });

  final Sake sake;
  final bool compact;
  final Future<SakeTasteProfileDetails?>? profileFuture;
  final String? subtitle;
  final String? footer;
  final Widget action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 96 : 137,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: compact ? 96 : 137,
                  height: compact ? 126 : 203,
                  child: _SakeImage(sake: sake),
                ),
                if (profileFuture != null)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _SakeMatchBadge(profileFuture: profileFuture!),
                  ),
                Positioned(right: 2, bottom: 4, child: action),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _displayName(context, sake),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _bodyTextColor,
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _bodyTextColor, fontSize: 12),
              ),
            if (footer != null)
              Text(
                footer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _bodyTextColor, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class _SakeImage extends StatelessWidget {
  const _SakeImage({required this.sake});

  final Sake sake;

  @override
  Widget build(BuildContext context) {
    final imagePath = preferredSakeCardImagePath(sake);
    if (imagePath == null || imagePath.trim().isEmpty) {
      return _placeholder();
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: const Color(0xFFF2F2F2),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: _brandColor,
                  strokeWidth: 2,
                ),
              ),
      );
    }
    final file = File(imagePath);
    if (!file.existsSync()) return _placeholder();
    return Image.file(
      file,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      cacheWidth: 360,
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF2F2F2),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/sake_placeholder.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SakeMatchBadge extends StatelessWidget {
  const _SakeMatchBadge({required this.profileFuture});

  final Future<SakeTasteProfileDetails?> profileFuture;

  @override
  Widget build(BuildContext context) {
    final preference = Provider.of<MyPageState?>(context)?.tasteProfile;
    if (preference == null) return const SizedBox.shrink();
    return FutureBuilder<SakeTasteProfileDetails?>(
      future: profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) return const SizedBox.shrink();
        final percent = calculateSharedSakeTasteMatchPercent(
          profile: profile,
          preference: preference,
        );
        return _MatchPercentBadge(percent: percent);
      },
    );
  }
}

class _MatchPercentBadge extends StatelessWidget {
  const _MatchPercentBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
      ),
      borderRadius: BorderRadius.circular(99),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5)],
    ),
    child: Text(
      '$percent%',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        height: 1,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// 一覧カードはユーザー写真、マスターのサムネイル、詳細画像の順で表示する。
String? preferredSakeCardImagePath(Sake sake) {
  return preferredSakeImagePath(
    personalImagePaths: sake.imagePaths,
    thumbnailImageUrl: sake.thumbnailImageUrl,
    primaryImageUrl: sake.primaryImageUrl,
  );
}

String _displayName(BuildContext context, Sake sake) {
  final name = sake.name?.trim();
  return name == null || name.isEmpty ? context.l10n.unknownName : name;
}
