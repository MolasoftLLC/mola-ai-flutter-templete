import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      (Request request) async {
        final headers = Map<String, String>.from(request.headers);
        headers['Content-Type'] = 'application/json';

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final token = await user.getIdToken();
            headers['Authorization'] = 'Bearer $token';
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-token-expired' || e.code == 'user-disabled') {
              await FirebaseAuth.instance.signOut();
            }
          } catch (_) {
            // ignore other errors and proceed without token
          }
        }

        final originalUri = request.url;
        final needsApiPrefix =
            !originalUri.path.startsWith('/api/') && originalUri.path != '/api';
        final normalizedPath = needsApiPrefix
            ? '/api${originalUri.path.startsWith('/') ? originalUri.path : '/${originalUri.path}'}'
            : originalUri.path;
        final updatedUri = originalUri.replace(path: normalizedPath);

        return request.copyWith(headers: headers, uri: updatedUri);
      },
    ],
  );
}
