import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

/// Shared with My Records: a bookmark or an automatically saved scan is not a record.
bool hasPersonalSakeRecord(Sake sake) =>
    sake.impression?.trim().isNotEmpty == true ||
    sake.place?.trim().isNotEmpty == true ||
    sake.drinkingPlace?.displayName.trim().isNotEmpty == true ||
    sake.userTags?.any((tag) => tag.trim().isNotEmpty) == true ||
    sake.personalTasteRatings?.isNotEmpty == true ||
    (sake.imagePaths?.length ?? 0) >= 2;
