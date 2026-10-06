import 'sake_label_scan.dart';
import 'response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

class MenuAnalysisHistoryItem {
  final String id;
  final DateTime date;
  final String? storeName;
  final List<SavedSake> sakes;
  final String? imagePath;
  final String? base64Image; // Add base64 encoded image data
  final String analysisStatus;
  final DrinkingPlace? drinkingPlace;

  MenuAnalysisHistoryItem({
    required this.id,
    required this.date,
    this.storeName,
    required this.sakes,
    this.imagePath,
    this.base64Image, // Add this parameter
    this.analysisStatus = 'complete',
    this.drinkingPlace,
  });

  factory MenuAnalysisHistoryItem.fromJson(Map<String, dynamic> json) {
    return MenuAnalysisHistoryItem(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      storeName: json['storeName'] as String?,
      sakes: (json['sakes'] as List<dynamic>)
          .map((e) => SavedSake.fromJson(e as Map<String, dynamic>))
          .toList(),
      imagePath: json['imagePath'] as String?,
      base64Image: json['base64Image'] as String?, // Add this field
      analysisStatus: json['analysisStatus'] as String? ?? 'complete',
      drinkingPlace: json['drinkingPlace'] is Map
          ? DrinkingPlace.fromJson(
              Map<String, dynamic>.from(json['drinkingPlace']),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toUtc().toIso8601String(),
      'storeName': storeName,
      'sakes': sakes.map((e) => e.toJson()).toList(),
      'imagePath': imagePath,
      'base64Image': base64Image, // Add this field
      'analysisStatus': analysisStatus,
      'drinkingPlace': drinkingPlace?.toJson(),
    };
  }

  MenuAnalysisHistoryItem copyWith({
    String? storeName,
    bool clearStoreName = false,
    List<SavedSake>? sakes,
    String? imagePath,
    bool clearImagePath = false,
    bool clearBase64Image = false,
    String? analysisStatus,
    DrinkingPlace? drinkingPlace,
    bool clearDrinkingPlace = false,
  }) => MenuAnalysisHistoryItem(
    id: id,
    date: date,
    storeName: clearStoreName ? null : storeName ?? this.storeName,
    sakes: sakes ?? this.sakes,
    imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    base64Image: clearBase64Image ? null : base64Image,
    analysisStatus: analysisStatus ?? this.analysisStatus,
    drinkingPlace: clearDrinkingPlace
        ? null
        : drinkingPlace ?? this.drinkingPlace,
  );
}

class SavedSake {
  final String name;
  final String? type;
  final bool isRecommended;
  final int? sakeId;
  final int? matchPercent;
  final String? recommendationBasis;
  final String? extractedName;
  final Sake? details;
  final SakeTasteProfileDetails? tasteProfile;

  SavedSake({
    required this.name,
    this.type,
    this.isRecommended = false,
    this.sakeId,
    this.matchPercent,
    this.recommendationBasis,
    this.extractedName,
    this.details,
    this.tasteProfile,
  });

  factory SavedSake.fromJson(Map<String, dynamic> json) {
    return SavedSake(
      name: json['name'] as String,
      type: json['type'] as String?,
      isRecommended: json['isRecommended'] as bool? ?? false,
      sakeId: (json['sakeId'] as num?)?.toInt(),
      matchPercent: (json['matchPercent'] as num?)?.toInt(),
      recommendationBasis: json['recommendationBasis'] as String?,
      extractedName: json['extractedName'] as String?,
      details: json['details'] is Map
          ? Sake.fromJson(Map<String, dynamic>.from(json['details']))
          : null,
      tasteProfile: json['tasteProfile'] is Map
          ? SakeTasteProfileDetails.tryFromJson(
              Map<String, dynamic>.from(json['tasteProfile']),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'isRecommended': isRecommended,
      'sakeId': sakeId,
      'matchPercent': matchPercent,
      'recommendationBasis': recommendationBasis,
      'extractedName': extractedName,
      'details': details?.toJson(),
      'tasteProfile': tasteProfile == null
          ? null
          : {
              'fruity': tasteProfile!.fruity,
              'sweetness': tasteProfile!.sweetness,
              'acidity': tasteProfile!.acidity,
              'umami': tasteProfile!.umami,
              'kire': tasteProfile!.kire,
              'dryness': tasteProfile!.dryness,
              'body': tasteProfile!.body,
              'aroma': tasteProfile!.aroma,
              'sourceType': tasteProfile!.sourceType,
              'confidence': tasteProfile!.confidence,
            },
    };
  }
}

List<SavedSake> buildMenuHistorySakes({
  required List<({String name, String? type})> extracted,
  required List<({int? sakeId, String name, String? type})> resolved,
  required Map<String, String> nameMapping,
  required Map<String, int> matchPercents,
  Map<String, Sake> details = const {},
  Map<String, SakeTasteProfileDetails> tasteProfiles = const {},
}) => extracted
    .map((source) {
      final resolvedName = nameMapping[source.name];
      final match = resolved
          .where((item) => item.name == resolvedName)
          .firstOrNull;
      final percent = matchPercents[source.name];
      return SavedSake(
        extractedName: source.name,
        name: match?.name ?? resolvedName ?? source.name,
        type: match?.type ?? source.type,
        sakeId: match?.sakeId,
        matchPercent: percent,
        recommendationBasis: percent == null ? null : 'taste_profile_v1',
        isRecommended: percent != null && percent >= 70,
        details: details[source.name],
        tasteProfile: tasteProfiles[source.name],
      );
    })
    .toList(growable: false);

extension MenuHistoryFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
