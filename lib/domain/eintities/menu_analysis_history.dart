import 'dart:convert';

class MenuAnalysisHistoryItem {
  final String id;
  final DateTime date;
  final String? storeName;
  final List<SavedSake> sakes;
  final String? imagePath; // Add this field

  MenuAnalysisHistoryItem({
    required this.id,
    required this.date,
    this.storeName,
    required this.sakes,
    this.imagePath, // Add this parameter
  });

  factory MenuAnalysisHistoryItem.fromJson(Map<String, dynamic> json) {
    return MenuAnalysisHistoryItem(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      storeName: json['storeName'] as String?,
      sakes: (json['sakes'] as List<dynamic>)
          .map((e) => SavedSake.fromJson(e as Map<String, dynamic>))
          .toList(),
      imagePath: json['imagePath'] as String?, // Add this field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'storeName': storeName,
      'sakes': sakes.map((e) => e.toJson()).toList(),
      'imagePath': imagePath, // Add this field
    };
  }
}

class SavedSake {
  final String name;
  final String? type;
  final bool isRecommended;

  SavedSake({
    required this.name,
    this.type,
    this.isRecommended = false,
  });

  factory SavedSake.fromJson(Map<String, dynamic> json) {
    return SavedSake(
      name: json['name'] as String,
      type: json['type'] as String?,
      isRecommended: json['isRecommended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'isRecommended': isRecommended,
    };
  }
}
