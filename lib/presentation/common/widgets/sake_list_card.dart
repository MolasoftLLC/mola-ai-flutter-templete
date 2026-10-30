import '../../../common/sake/taste_match.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../common/utils/sake_image_utils.dart';
import '../../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../../domain/eintities/sake_label_scan.dart';
import 'sake_taste_match_preview.dart';

const _navy = Color(0xFF143861);
const _orange = Color(0xFFFF7A1A);
const _muted = Color(0xFF647184);

class SakeListCard extends StatelessWidget {
  const SakeListCard({
    super.key,
    required this.sake,
    required this.profileFuture,
    required this.preference,
    required this.onOpen,
    this.footer,
  });
  final Sake sake;
  final Future<SakeTasteProfileDetails?>? profileFuture;
  final TastePreferenceProfile? preference;
  final VoidCallback onOpen;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Material(
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
        if (footer != null) footer!,
      ],
    ),
  );
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
            : calculateSharedSakeTasteMatchPercent(
                profile: profile,
                preference: preference!,
              );
        return SakeTasteMatchPreview(
          percent: match,
          profile: profile,
          preference: preference,
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

class _RecordImage extends StatelessWidget {
  const _RecordImage({required this.sake});

  final Sake sake;

  @override
  Widget build(BuildContext context) {
    final path = _preferredImagePath(sake);
    if (path == null || isSakePlaceholderImagePath(path)) return _placeholder();
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
    child: Image.asset(
      'assets/images/sake_placeholder.png',
      fit: BoxFit.contain,
    ),
  );
}

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
