import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/utils/async_action_gate.dart';

void main() {
  test('同じ保存への同時タップは1回だけ実行し、完了後は再操作できる', () async {
    final gate = AsyncActionGate();
    final response = Completer<bool>();
    var calls = 0;
    Future<bool> save() {
      calls++;
      return response.future;
    }

    final first = gate.run('saved-1', save);
    final second = gate.run('saved-1', save);
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    response.complete(true);
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(await gate.run('saved-1', () async => false), isFalse);
  });

  test('失敗した保存は再試行でき、別のお酒の操作は待たせない', () async {
    final gate = AsyncActionGate();
    final response = Completer<bool>();
    final failed = gate.run('saved-1', () => response.future);
    final retryTap = gate.run('saved-1', () async => true);
    final failure = expectLater(
      Future.wait([failed, retryTap]),
      throwsA(isA<StateError>()),
    );
    expect(await gate.run('saved-2', () async => true), isTrue);
    response.completeError(StateError('network failed'));
    await failure;
    expect(await gate.run('saved-1', () async => true), isTrue);
  });
}
