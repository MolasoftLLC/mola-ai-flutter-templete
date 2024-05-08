import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

ChopperClient chopperClient({http.Client? client, required String url}) {
  return ChopperClient(
    baseUrl: url == '127.0.0.1' || url == '10.0.2.2'
        ? Uri(
            scheme: 'http',
            port: 8080,
            host: url,
            path: '/api',
          )
        : Uri(
            scheme: 'https',
            host: url,
            path: '/api',
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
