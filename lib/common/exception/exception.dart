class AppException implements Exception {
  AppException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final dynamic details;

  @override
  String toString() => 'AppException($code, $message, $details)';
}

class MolaApiException implements Exception {
  MolaApiException({
    this.code,
    required this.message,
    required this.details,
  });

  final dynamic code;
  final String message;
  final String details;

  @override
  String toString() => 'AppException($code, $message, $details)';

  // ignore: sort_constructors_first
  factory MolaApiException.anyError() {
    return MolaApiException(
      code: 500,
      details: '通信エラーが発生しました',
      message: '再度お試しください',
    );
  }

  // ignore: sort_constructors_first
  factory MolaApiException.fromObject(Object error) {
    final errorMapData = error as Map<String, dynamic>;
    return MolaApiException(
      code: errorMapData['code'],
      details: errorMapData['detail'].toString(),
      message: errorMapData['message'].toString(),
    );
  }
}
