class MenuAnalysisHistoryItem {
  final String id;
  final DateTime date;
  final String? storeName;
  final List<SavedSake> sakes;
  final String? imagePath;
  final String? base64Image; // Add base64 encoded image data
  final String analysisStatus;

  MenuAnalysisHistoryItem({
    required this.id,
    required this.date,
    this.storeName,
    required this.sakes,
    this.imagePath,
    this.base64Image, // Add this parameter
    this.analysisStatus = 'complete',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'storeName': storeName,
      'sakes': sakes.map((e) => e.toJson()).toList(),
      'imagePath': imagePath,
      'base64Image': base64Image, // Add this field
      'analysisStatus': analysisStatus,
    };
  }

  MenuAnalysisHistoryItem copyWith({
    String? storeName,
    List<SavedSake>? sakes,
    String? imagePath,
    bool clearImagePath = false,
    bool clearBase64Image = false,
    String? analysisStatus,
  }) => MenuAnalysisHistoryItem(
    id: id,
    date: date,
    storeName: storeName ?? this.storeName,
    sakes: sakes ?? this.sakes,
    imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    base64Image: clearBase64Image ? null : base64Image,
    analysisStatus: analysisStatus ?? this.analysisStatus,
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

  SavedSake({
    required this.name,
    this.type,
    this.isRecommended = false,
    this.sakeId,
    this.matchPercent,
    this.recommendationBasis,
    this.extractedName,
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
    };
  }
}

List<SavedSake> buildMenuHistorySakes({
  required List<({String name, String? type})> extracted,
  required List<({int? sakeId, String name, String? type})> resolved,
  required Map<String, String> nameMapping,
  required Map<String, int> matchPercents,
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
      );
    })
    .toList(growable: false);

extension MenuHistoryFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
