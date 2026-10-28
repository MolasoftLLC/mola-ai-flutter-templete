import '../../common/sake/taste_match.dart';
import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';

enum ComparisonMood {
  any('おまかせ'),
  fruity('華やか・フルーティ'),
  crisp('すっきり・辛口'),
  rich('旨みをじっくり'),
  sweet('やさしい甘み'),
  fresh('爽やかな酸味');

  const ComparisonMood(this.label);
  final String label;
  TastePreferenceProfile? get preference => switch (this) {
    any => null,
    fruity => const TastePreferenceProfile(
      fruity: .9,
      sweetness: .6,
      acidity: .5,
      umami: .4,
      kire: .6,
      spiciness: .3,
    ),
    crisp => const TastePreferenceProfile(
      fruity: .3,
      sweetness: .2,
      acidity: .4,
      umami: .3,
      kire: .9,
      spiciness: .9,
    ),
    rich => const TastePreferenceProfile(
      fruity: .4,
      sweetness: .5,
      acidity: .5,
      umami: .9,
      kire: .4,
      spiciness: .5,
    ),
    sweet => const TastePreferenceProfile(
      fruity: .7,
      sweetness: .9,
      acidity: .4,
      umami: .5,
      kire: .4,
      spiciness: .1,
    ),
    fresh => const TastePreferenceProfile(
      fruity: .6,
      sweetness: .5,
      acidity: .9,
      umami: .3,
      kire: .7,
      spiciness: .3,
    ),
  };
}

class ComparisonItem {
  const ComparisonItem({
    required this.id,
    required this.sake,
    required this.text,
    this.profile,
    this.estimated = false,
    this.sample = false,
  });
  final String id;
  final Sake sake;
  final String text;
  final SakeTasteProfileDetails? profile;
  final bool estimated;
  final bool sample;

  bool get mentionsLimited =>
      RegExp('限定|季節|希少|数量|特約店').hasMatch('$text ${sake.name}');
  String get identity => (sake.sakeId ?? 0) > 0
      ? 'sake:${sake.sakeId}'
      : '${sake.name}:${sake.type}:${sake.brewery}'
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();
  int? match(TastePreferenceProfile? preference) =>
      calculateOptionalSakeTasteMatchPercent(
        profile: profile,
        preference: preference,
      );
  double rank(
    TastePreferenceProfile? preference,
    ComparisonMood mood,
    bool limited,
  ) {
    final personal = match(preference);
    final today = match(mood.preference);
    final score = personal != null && today != null
        ? personal * .65 + today * .35
        : (personal ?? today)?.toDouble();
    return (score ?? -100) + (limited && mentionsLimited ? 5 : 0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': sake.name,
    'type': sake.type,
    'brewery': sake.brewery,
    'sakeId': sake.sakeId,
    'text': text,
    'estimated': estimated,
    'sample': sample,
    if (profile != null)
      'profile': {
        'fruity': profile!.fruity,
        'sweetness': profile!.sweetness,
        'acidity': profile!.acidity,
        'umami': profile!.umami,
        'body': profile!.body,
        'kire': profile!.kire,
        'dryness': profile!.dryness,
        'sourceType': profile!.sourceType,
      },
  };
  factory ComparisonItem.fromJson(Map<String, dynamic> json) => ComparisonItem(
    id: json['id'] as String,
    sake: Sake(
      name: json['name'] as String?,
      type: json['type'] as String?,
      brewery: json['brewery'] as String?,
      sakeId: json['sakeId'] as int?,
    ),
    text: json['text'] as String? ?? '',
    estimated: json['estimated'] == true,
    sample: json['sample'] == true,
    profile: json['profile'] is Map
        ? SakeTasteProfileDetails.tryFromJson(
            Map<String, dynamic>.from(json['profile'] as Map),
          )
        : null,
  );
}

// Deliberately fictional fixtures, isolated from saved sake and master data.
List<ComparisonItem> comparisonSamples() => [
  const ComparisonItem(
    id: 'demo-a',
    sake: Sake(name: 'サンプルA 華やか純米吟醸', type: '純米吟醸'),
    text: 'デモ用の商品説明：華やかな香り、やさしい甘み。季節限定。',
    sample: true,
    profile: SakeTasteProfileDetails(
      fruity: .9,
      sweetness: .7,
      acidity: .5,
      umami: .4,
      kire: .6,
      dryness: .2,
    ),
  ),
  const ComparisonItem(
    id: 'demo-b',
    sake: Sake(name: 'サンプルB すっきり純米', type: '純米'),
    text: 'デモ用の商品説明：軽やかですっきりした辛口。食中酒に。',
    sample: true,
    profile: SakeTasteProfileDetails(
      fruity: .3,
      sweetness: .2,
      acidity: .4,
      umami: .4,
      kire: .9,
      dryness: .9,
    ),
  ),
  const ComparisonItem(
    id: 'demo-c',
    sake: Sake(name: 'サンプルC 旨みの山廃', type: '山廃純米'),
    text: 'デモ用の商品説明：ふくらむ旨みとしっかりしたコク。',
    sample: true,
    profile: SakeTasteProfileDetails(
      fruity: .3,
      sweetness: .5,
      acidity: .6,
      umami: .9,
      kire: .4,
      dryness: .5,
    ),
  ),
];
