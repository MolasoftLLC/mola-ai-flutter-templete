import 'package:chopper/chopper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../common/access_url.dart';

ChopperClient sakeMenuRecognitionChopperClient({http.Client? client}) {
  const String baseUrl = sakeMenuUrl;
  // baseUrl: Uri.parse('https://molasoft-ai-central.com/'),
  return ChopperClient(
    baseUrl: Uri.parse(baseUrl),
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
            // ignore
          }
        }

        return request.copyWith(headers: headers);
      },
    ],
  );
}
