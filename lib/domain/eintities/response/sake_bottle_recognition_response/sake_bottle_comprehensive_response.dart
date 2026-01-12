import '../sake_menu_recognition_response/sake_menu_recognition_response.dart';

class SakeBottleComprehensiveResponse {
  const SakeBottleComprehensiveResponse({
    this.sakeName,
    this.type,
    this.sakeInfo,
  });

  final String? sakeName;
  final String? type;
  final Sake? sakeInfo;
}
