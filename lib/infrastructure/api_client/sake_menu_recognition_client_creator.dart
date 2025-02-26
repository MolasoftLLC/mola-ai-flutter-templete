import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

ChopperClient sakeMenuRecognitionChopperClient({http.Client? client}) {
  return ChopperClient(
    baseUrl: Uri(
      scheme: 'https',
      host: 'molasoft-ai-central.com',
    ),
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
