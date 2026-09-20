const sakeNoImageUrl = 'https://molasoft-ai-central.com/assets/noimage.png';

bool isSakePlaceholderImagePath(String? value) {
  final path = value?.trim();
  if (path == null || path.isEmpty) return false;
  final uri = Uri.tryParse(path);
  if (uri == null) return false;
  return uri.path.toLowerCase().endsWith('/assets/noimage.png');
}

String? preferredSakeImagePath({
  Iterable<String>? personalImagePaths,
  String? thumbnailImageUrl,
  String? primaryImageUrl,
}) {
  final candidates = <String>[
    ...?personalImagePaths,
    if (thumbnailImageUrl != null) thumbnailImageUrl,
    if (primaryImageUrl != null) primaryImageUrl,
  ].map((path) => path.trim()).where((path) => path.isNotEmpty).toList();

  for (final path in candidates) {
    if (!isSakePlaceholderImagePath(path)) return path;
  }
  return candidates.isEmpty ? null : candidates.first;
}
