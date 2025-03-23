import 'dart:convert';

class SakeBottleImage {
  final String id;
  final String path;
  final String? base64Image; // Add base64 encoded image data
  final DateTime capturedAt;
  final String? sakeName;
  final String? type;

  SakeBottleImage({
    required this.id,
    required this.path,
    this.base64Image, // Add this parameter
    required this.capturedAt,
    this.sakeName,
    this.type,
  });

  factory SakeBottleImage.fromJson(Map<String, dynamic> json) {
    return SakeBottleImage(
      id: json['id'] as String,
      path: json['path'] as String,
      base64Image: json['base64Image'] as String?, // Add this field
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      sakeName: json['sakeName'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'base64Image': base64Image, // Add this field
      'capturedAt': capturedAt.toIso8601String(),
      'sakeName': sakeName,
      'type': type,
    };
  }

  // Create a copy of this SakeBottleImage with the given fields replaced
  SakeBottleImage copyWith({
    String? id,
    String? path,
    String? base64Image, // Add this parameter
    DateTime? capturedAt,
    String? sakeName,
    String? type,
  }) {
    return SakeBottleImage(
      id: id ?? this.id,
      path: path ?? this.path,
      base64Image: base64Image ?? this.base64Image, // Add this field
      capturedAt: capturedAt ?? this.capturedAt,
      sakeName: sakeName ?? this.sakeName,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'SakeBottleImage(id: $id, path: $path, capturedAt: $capturedAt, sakeName: $sakeName, type: $type)';
  }

  // Helper method to convert a list of SakeBottleImage to JSON string
  static String encodeList(List<SakeBottleImage> images) {
    return jsonEncode(images.map((image) => image.toJson()).toList());
  }

  // Helper method to convert a JSON string to a list of SakeBottleImage
  static List<SakeBottleImage> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => SakeBottleImage.fromJson(json)).toList();
  }
}
