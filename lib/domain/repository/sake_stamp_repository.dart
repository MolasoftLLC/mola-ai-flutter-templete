import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../eintities/collected_sake_stamp.dart';

abstract interface class SakeStampRemote {
  Future<List<CollectedSakeStamp>> fetch(String accountId);
  Future<List<CollectedSakeStamp>> upload(
    String accountId,
    List<CollectedSakeStamp> stamps,
  );
}

/// Every request is bound to the captured account, including after token refresh.
class SakeStampRepository implements SakeStampRemote {
  SakeStampRepository({
    required this.baseUrl,
    http.Client? client,
    Future<String?> Function(String)? tokenReader,
    String? Function()? accountReader,
  }) : _client = client ?? http.Client(),
       _tokenReader = tokenReader ?? _token,
       _accountReader = accountReader ?? _account;
  final Uri baseUrl;
  final http.Client _client;
  final Future<String?> Function(String) _tokenReader;
  final String? Function() _accountReader;
  static String? _account() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous && user.emailVerified
        ? user.uid
        : null;
  }

  static Future<String?> _token(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_account() != uid || user == null) return null;
    final token = await user.getIdToken();
    return _account() == uid ? token : null;
  }

  void close() => _client.close();
  Future<Map<String, dynamic>> _request(
    String uid, {
    List<CollectedSakeStamp>? stamps,
    int? after,
  }) async {
    if (_accountReader() != uid) throw StateError('Account changed');
    final token = await _tokenReader(uid).timeout(const Duration(seconds: 15));
    if (token == null || _accountReader() != uid) {
      throw StateError('Account changed');
    }
    final url = baseUrl.replace(
      path: stamps == null ? '/api/sake-stamps' : '/api/sake-stamps/sync',
      queryParameters: after == null ? null : {'after': '$after'},
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response =
        await (stamps == null
                ? _client.get(url, headers: headers)
                : _client.post(
                    url,
                    headers: headers,
                    body: jsonEncode({
                      'stamps': stamps.map((s) => s.toJson()).toList(),
                    }),
                  ))
            .timeout(const Duration(seconds: 20));
    if (_accountReader() != uid) throw StateError('Account changed');
    if (response.statusCode != 200) throw StateError('Stamp sync unavailable');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  List<CollectedSakeStamp> _parse(Map<String, dynamic> body) =>
      (body['stamps'] as List)
          .map(
            (s) => CollectedSakeStamp.fromJson(
              Map<String, dynamic>.from(s as Map),
            ),
          )
          .toList();
  @override
  Future<List<CollectedSakeStamp>> fetch(String accountId) async {
    final result = <CollectedSakeStamp>[];
    int? after;
    do {
      final body = await _request(accountId, after: after);
      result.addAll(_parse(body));
      final next = body['nextCursor'] as int?;
      if (next != null && next <= (after ?? 0)) {
        throw const FormatException('Invalid stamp cursor');
      }
      after = next;
    } while (after != null);
    return result;
  }

  @override
  Future<List<CollectedSakeStamp>> upload(
    String accountId,
    List<CollectedSakeStamp> stamps,
  ) async => _parse(await _request(accountId, stamps: stamps));
}
