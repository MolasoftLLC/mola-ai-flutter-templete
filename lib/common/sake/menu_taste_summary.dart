import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../domain/eintities/sake_label_scan.dart';

/// Keep menu recommendations usable for users with legacy text preferences.
TastePreferenceProfile? menuTastePreference({
  TastePreferenceProfile? profile,
  String? preferences,
}) {
  if (profile != null) return profile;
  final text = preferences ?? '';
  if (!RegExp('甘|辛|酸|旨|コク|フルーティ|果実|華やか|キレ|すっきり|軽快|濃厚').hasMatch(text)) {
    return null;
  }
  double axis(String positive, String negative) {
    if (RegExp(negative).hasMatch(text)) return 0.2;
    return RegExp(positive).hasMatch(text) ? 0.8 : 0.5;
  }

  return TastePreferenceProfile(
    fruity: axis('フルーティ|果実|華やか', '香り.*(?:控えめ|苦手)|穏やかな香り'),
    sweetness: axis('甘口|甘み|甘い', '辛口|甘.*(?:苦手|控えめ)'),
    acidity: axis('酸味|酸っぱい', '酸.*(?:苦手|控えめ|少ない)'),
    umami: axis('旨|コク|濃厚', '軽快|軽い|淡麗'),
    kire: axis('キレ|すっきり|辛口', '余韻.*長|濃厚'),
    spiciness: axis('辛口|ドライ', '甘口|辛.*苦手'),
  );
}

List<String> menuTasteTags(SakeTasteProfileDetails profile) {
  final tags = <String>[];
  if (profile.fruity >= 0.6) tags.add('フルーティ');
  if (profile.sweetness >= 0.6) tags.add('甘口');
  if (profile.dryness >= 0.6) tags.add('辛口');
  if (profile.acidity >= 0.6) tags.add('酸味');
  if (profile.umami >= 0.6) tags.add('旨味・コク');
  if (profile.umami <= 0.4) tags.add('軽快');
  if (profile.kire >= 0.6) tags.add('キレ');
  if (tags.isEmpty) tags.add('バランス');
  return tags;
}

String menuRecommendationReason(
  SakeTasteProfileDetails profile,
  TastePreferenceProfile preference,
) {
  final axes = [
    ('果実のような香り', profile.fruity, preference.fruity),
    ('甘さ', profile.sweetness, preference.sweetness),
    ('酸味', profile.acidity, preference.acidity),
    ('旨味とコク', profile.umami, preference.umami),
    ('後味のキレ', profile.kire, preference.kire),
    ('辛口の味わい', profile.dryness, preference.spiciness),
  ]..sort((a, b) => (a.$2 - a.$3).abs().compareTo((b.$2 - b.$3).abs()));
  final matches = axes
      .where((axis) => (axis.$2 - axis.$3).abs() <= 0.25)
      .take(2);
  if (matches.isEmpty) return 'いつもの好みとは違う味わいを楽しめるお酒です。';
  final labels = matches
      .map((axis) => axis.$3 <= 0.4 ? '控えめな${axis.$1}' : axis.$1)
      .join('と');
  return '$labelsが、あなたの好みに合います。';
}
