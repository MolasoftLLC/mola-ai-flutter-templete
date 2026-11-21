class TastePreferenceProfile {
  const TastePreferenceProfile({
    required this.fruity,
    required this.sweetness,
    required this.acidity,
    required this.umami,
    required this.kire,
    required this.spiciness,
  });

  final double fruity;
  final double sweetness;
  final double acidity;
  final double umami;
  final double kire;
  final double spiciness;

  /// Empty API responses represent an unset preference, never six zeroes.
  static TastePreferenceProfile? tryFromJson(Map<String, dynamic> json) {
    const keys = [
      'fruity',
      'sweetness',
      'acidity',
      'umami',
      'kire',
      'spiciness',
    ];
    if (!keys.every(
      (key) =>
          json[key] is num &&
          (json[key] as num).isFinite &&
          (json[key] as num) >= 0 &&
          (json[key] as num) <= 1,
    ))
      return null;
    return TastePreferenceProfile.fromJson(json);
  }

  /// A starting estimate from explicit choices; unselected axes stay neutral.
  static TastePreferenceProfile? fromSelections(Iterable<String> selections) {
    const effects = <String, Map<String, double>>{
      '甘口': {'sweetness': .8, 'spiciness': .2},
      '辛口': {'sweetness': .2, 'spiciness': .8, 'kire': .7},
      'スッキリ': {'kire': .8, 'umami': .3},
      'フルーティ': {'fruity': .8},
      'にごり': {'umami': .7, 'sweetness': .65},
      '微発泡': {'acidity': .65, 'kire': .7},
      '酸味': {'acidity': .8},
    };
    final chosen = selections.toSet();
    if (chosen.isEmpty || chosen.any((key) => !effects.containsKey(key)))
      return null;
    double axis(String key) {
      final values = chosen
          .map((choice) => effects[choice]![key])
          .whereType<double>()
          .toList();
      return values.isEmpty
          ? .5
          : values.reduce((a, b) => a + b) / values.length;
    }

    return TastePreferenceProfile(
      fruity: axis('fruity'),
      sweetness: axis('sweetness'),
      acidity: axis('acidity'),
      umami: axis('umami'),
      kire: axis('kire'),
      spiciness: axis('spiciness'),
    );
  }

  factory TastePreferenceProfile.fromJson(Map<String, dynamic> json) {
    double castValue(String key) {
      final value = json[key];
      if (value is num) {
        return value.toDouble().clamp(0.0, 1.0);
      }
      return 0.0;
    }

    return TastePreferenceProfile(
      fruity: castValue('fruity'),
      sweetness: castValue('sweetness'),
      acidity: castValue('acidity'),
      umami: castValue('umami'),
      kire: castValue('kire'),
      spiciness: castValue('spiciness'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fruity': fruity,
    'sweetness': sweetness,
    'acidity': acidity,
    'umami': umami,
    'kire': kire,
    'spiciness': spiciness,
  };

  static TastePreferenceProfile sample() => const TastePreferenceProfile(
    fruity: 0.28,
    sweetness: 0.92,
    acidity: 0.10,
    umami: 0.72,
    kire: 0.30,
    spiciness: 0.15,
  );
}
