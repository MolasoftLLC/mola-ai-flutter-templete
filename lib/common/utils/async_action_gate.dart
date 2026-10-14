import 'dart:async';

/// Concurrent taps for the same action share one operation. A later tap can retry.
class AsyncActionGate {
  final Map<Object, Future<dynamic>> _pending = {};

  Future<T> run<T>(Object key, Future<T> Function() action) {
    final existing = _pending[key];
    if (existing != null) return existing as Future<T>;
    final completion = Completer<T>();
    _pending[key] = completion.future;
    Future<void> execute() async {
      try {
        completion.complete(await action());
      } catch (error, stack) {
        completion.completeError(error, stack);
      } finally {
        _pending.remove(key);
      }
    }

    unawaited(execute());
    return completion.future;
  }
}
