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
