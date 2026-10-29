import 'package:flutter/material.dart';
import '../../../common/utils/sake_image_utils.dart';

/// A shared visual fallback for brands, missing product photos and load failures.
class SakeCatalogThumbnail extends StatelessWidget {
  const SakeCatalogThumbnail({
    super.key,
    this.thumbnailImageUrl,
    this.primaryImageUrl,
    this.size = 72,
  });
  final String? thumbnailImageUrl;
  final String? primaryImageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final urls = [thumbnailImageUrl, primaryImageUrl]
        .whereType<String>()
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty && !isSakePlaceholderImagePath(path))
        .map(
          (path) => Uri.tryParse(
            path.startsWith('/')
                ? Uri.parse(sakeNoImageUrl).resolve(path).toString()
                : path,
          ),
        )
        .whereType<Uri>()
        .where((uri) => uri.scheme == 'https' || uri.scheme == 'http')
        .map((uri) => uri.toString())
        .toSet()
        .toList();
    Widget fallback() => Image.asset(
      'assets/images/sake_catalog_illustration.png',
      key: const ValueKey('sake-catalog-illustration'),
      fit: BoxFit.contain,
      cacheWidth: 256,
      excludeFromSemantics: true,
    );
    Widget photo(int index) => index >= urls.length
        ? fallback()
        : Image.network(
            urls[index],
            fit: BoxFit.contain,
            cacheWidth: 256,
            excludeFromSemantics: true,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : fallback(),
            errorBuilder: (_, __, ___) => photo(index + 1),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(color: const Color(0xFFF4F7F6), child: photo(0)),
      ),
    );
  }
}
