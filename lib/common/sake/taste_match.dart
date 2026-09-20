import 'dart:math' as math;

import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../domain/eintities/sake_label_scan.dart';

int calculateSharedSakeTasteMatchPercent({
  required SakeTasteProfileDetails profile,
  required TastePreferenceProfile preference,
}) => calculateSharedTasteMatchPercent(
  sakeValues: [
    profile.fruity,
    profile.sweetness,
    profile.acidity,
    profile.body ?? profile.umami,
    profile.kire,
    profile.dryness,
  ],
  preferenceValues: [
    preference.fruity,
    preference.sweetness,
    preference.acidity,
    preference.umami,
    preference.kire,
    preference.spiciness,
  ],
);

int? calculateOptionalSakeTasteMatchPercent({
  required SakeTasteProfileDetails? profile,
  required TastePreferenceProfile? preference,
}) {
  if (profile == null || preference == null) return null;
  return calculateSharedSakeTasteMatchPercent(
    profile: profile,
    preference: preference,
  );
}

int calculateSharedTasteMatchPercent({
  required List<double> sakeValues,
  required List<double> preferenceValues,
}) {
  if (sakeValues.isEmpty || sakeValues.length != preferenceValues.length) {
    return 30;
  }
  final difference =
      List<double>.generate(
        sakeValues.length,
        (index) =>
            (sakeValues[index].clamp(0, 1).toDouble() -
                    preferenceValues[index].clamp(0, 1).toDouble())
                .abs(),
      ).reduce((sum, value) => sum + value) /
      sakeValues.length;
  final similarity = 1 - difference;
  return (30 + math.pow(similarity, 3.5) * 70).round().clamp(30, 100).toInt();
}
