import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

ChopperClient sakeMenuRecognitionChopperClient({http.Client? client}) {
  const String baseUrl = 'https://molasoft-ai-central.com/';
  // baseUrl: Uri.parse('https://molasoft-ai-central.com/'),
  return ChopperClient(
    baseUrl: Uri.parse(baseUrl),
    client: client,
    converter: const JsonConverter(),
    errorConverter: const JsonConverter(),
    interceptors: <dynamic>[
      (Request request) async => request.copyWith(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
    ],
  );
}
