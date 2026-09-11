import '../sake_menu_recognition_response/sake_menu_recognition_response.dart';

class SakeBottleComprehensiveResponse {
  const SakeBottleComprehensiveResponse({
    this.sakeId,
    this.sakeName,
    this.type,
    this.sakeInfo,
    this.manualSearchSuggested = false,
    this.manualSearchQuery,
  });

  final int? sakeId;
  final String? sakeName;
  final String? type;
  final Sake? sakeInfo;
  final bool manualSearchSuggested;
  final String? manualSearchQuery;
}
