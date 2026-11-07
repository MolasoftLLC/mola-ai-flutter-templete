/// Flavor preferences stay separate from the six numerical taste axes.
enum SakeFlavorCharacteristic {
  agedAroma('熟成・古酒系の香り', '熟成・古酒系の香りが苦手'),
  heavyTexture('とろり・重厚な口当たり', '重い口当たりが苦手'),
  longFinish('長い余韻', '長い余韻が苦手');

  const SakeFlavorCharacteristic(this.label, this.preference);
  final String label;
  final String preference;
}

class SakeFlavorEvidence {
  SakeFlavorEvidence._(Map<SakeFlavorCharacteristic, String> evidence)
    : evidence = Map.unmodifiable(evidence);

  /// Values retain the exact tag or sentence; absence means unknown, not absent.
  final Map<SakeFlavorCharacteristic, String> evidence;

  factory SakeFlavorEvidence.fromProduct({
    Iterable<String> tags = const [],
    String? description,
  }) {
    final evidence = <SakeFlavorCharacteristic, String>{};
    final patterns = <SakeFlavorCharacteristic, RegExp>{
      SakeFlavorCharacteristic.agedAroma: RegExp(
        r'熟成香|老香|古酒のような香り|(?:紹興酒|ナッツ|カラメル|メープル)(?:のような|を思わせる|の)?香',
      ),
      SakeFlavorCharacteristic.heavyTexture: RegExp(
        r'とろり|とろっと|重厚な口当たり|濃厚な口当たり',
      ),
      SakeFlavorCharacteristic.longFinish: RegExp(r'長い余韻|余韻が長|余韻の長'),
    };
    for (final text in [...tags, ...?description?.split(RegExp(r'[。！？\n]'))]) {
      final phrase = text.trim();
      // Conservatively skip negation/comparison instead of inventing a positive.
      if (phrase.isEmpty ||
          RegExp(
            r'ない|なく|なし|無し|ません|抑え|控え|少な|感じさせず|異な|違い|ではなく|苦手|避け',
          ).hasMatch(phrase)) {
        continue;
      }
      for (final entry in patterns.entries) {
        if (entry.value.hasMatch(phrase)) {
          evidence.putIfAbsent(entry.key, () => phrase);
        }
      }
    }
    return SakeFlavorEvidence._(evidence);
  }

  List<SakeFlavorCharacteristic> conflicts(String? preferences) {
    final selected = (preferences ?? '')
        .split('、')
        .map((s) => s.trim())
        .toSet();
    return SakeFlavorCharacteristic.values
        .where(
          (feature) =>
              selected.contains(feature.preference) &&
              evidence.containsKey(feature),
        )
        .toList(growable: false);
  }

  String? caution(String? preferences) {
    final matches = conflicts(preferences);
    return matches.isEmpty
        ? null
        : '${matches.map((f) => f.label).join('・')}の記載があります。苦手な風味に該当する可能性があります。';
  }
}

bool hasFlavorAvoidance(String? preferences) => (preferences ?? '')
    .split('、')
    .any(
      (value) => SakeFlavorCharacteristic.values.any(
        (f) => f.preference == value.trim(),
      ),
    );

/// Stable partition: keep unknown products visible without claiming they are safe.
List<T> prioritizeFlavorPreferences<T>(
  List<T> items, {
  required String? preferences,
  required SakeFlavorEvidence Function(T) evidenceFor,
}) {
  if (!hasFlavorAvoidance(preferences)) return List.of(items);
  final other = <T>[];
  final caution = <T>[];
  for (final item in items) {
    (evidenceFor(item).conflicts(preferences).isEmpty ? other : caution).add(
      item,
    );
  }
  return [...other, ...caution];
}
