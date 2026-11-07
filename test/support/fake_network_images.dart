import 'dart:async';
import 'dart:io';

/// Serves image bytes deterministically without accessing the network in tests.
class FakeImageClient implements HttpClient {
  FakeImageClient(this.bytes);
  final List<int> bytes;
  final requested = <Uri>[];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requested.add(url);
    return _ImageRequest(bytes, url.path.contains('missing') ? 404 : 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageRequest implements HttpClientRequest {
  _ImageRequest(this.bytes, this.status);
  final List<int> bytes;
  final int status;
  @override
  Future<HttpClientResponse> close() async => _ImageResponse(bytes, status);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  _ImageResponse(this.bytes, this.statusCode);
  final List<int> bytes;
  @override
  final int statusCode;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
