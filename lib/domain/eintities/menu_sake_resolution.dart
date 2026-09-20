import 'response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'sake_label_scan.dart';

enum MenuSakeResolutionStatus { resolved, multiple, unresolved }

class MenuSakeCandidate {
  const MenuSakeCandidate({required this.sake, this.tasteProfile});

  factory MenuSakeCandidate.fromJson(Map<String, dynamic> json) =>
      MenuSakeCandidate(
        sake: Sake.fromJson(json),
        tasteProfile: json['tasteProfile'] is Map
            ? SakeTasteProfileDetails.fromJson(
                Map<String, dynamic>.from(json['tasteProfile'] as Map),
              )
            : null,
      );

  final Sake sake;
  final SakeTasteProfileDetails? tasteProfile;
}

class MenuSakeResolution {
  const MenuSakeResolution({
    required this.inputName,
    required this.status,
    required this.candidates,
    this.inputType,
    this.fallback,
  });

  factory MenuSakeResolution.fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString();
    return MenuSakeResolution(
      inputName: json['inputName']?.toString() ?? '',
      inputType: json['inputType']?.toString(),
      status: MenuSakeResolutionStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => MenuSakeResolutionStatus.unresolved,
      ),
      candidates: (json['candidates'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                MenuSakeCandidate.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      fallback: json['fallback'] is Map
          ? Sake.fromJson(Map<String, dynamic>.from(json['fallback'] as Map))
          : null,
    );
  }

  final String inputName;
  final String? inputType;
  final MenuSakeResolutionStatus status;
  final List<MenuSakeCandidate> candidates;
  final Sake? fallback;
}
