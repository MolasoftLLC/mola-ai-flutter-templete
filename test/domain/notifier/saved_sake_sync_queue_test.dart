import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/saved_sake_sync_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loggerConfigure);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('解析完了失敗後の再同期では送信済み裏ラベルを再アップロードしない', () async {
    final directory = await Directory.systemTemp.createTemp('saved-sake-69');
    addTearDown(() => directory.delete(recursive: true));
    final front = File('${directory.path}/front.jpg')..writeAsBytesSync([1]);
    final back = File('${directory.path}/back.jpg')..writeAsBytesSync([2]);
    final repository = _FakeSavedSakeSyncRepository(
      completeResults: <bool>[false, true],
    );
    final notifier = _notifier(repository);
    addTearDown(notifier.dispose);
    await notifier.addSavedSake(
      Sake(
        savedId: 'saved_69_1',
        name: '来福',
        imagePaths: [front.path, back.path],
        syncStatus: SavedSakeSyncStatus.localOnly,
      ),
    );

    expect(await notifier.syncSavedSakeToServer('saved_69_1'), isNull);
    expect(repository.uploadCalls, 1);
    expect(notifier.savedSakes.single.imagePaths, [
      front.path,
      'https://example.com/back.webp',
    ]);

    final retried = await notifier.syncSavedSakeToServer(
      'saved_69_1',
      force: true,
    );
    expect(retried?.syncStatus, SavedSakeSyncStatus.serverSynced);
    expect(repository.uploadCalls, 1);
  });

  test('同じsavedIdの自動・手動同期が重なっても一本の処理だけを実行する', () async {
    final directory = await Directory.systemTemp.createTemp('saved-sake-69');
    addTearDown(() => directory.delete(recursive: true));
    final front = File('${directory.path}/front.jpg')..writeAsBytesSync([1]);
    final back = File('${directory.path}/back.jpg')..writeAsBytesSync([2]);
    final gate = Completer<void>();
    final repository = _FakeSavedSakeSyncRepository(startGate: gate);
    final notifier = _notifier(repository);
    addTearDown(notifier.dispose);
    await notifier.addSavedSake(
      Sake(
        savedId: 'saved_69_2',
        name: '来福',
        imagePaths: [front.path, back.path],
        syncStatus: SavedSakeSyncStatus.localOnly,
      ),
    );

    final automatic = notifier.syncSavedSakeToServer(
      'saved_69_2',
      startOnly: true,
    );
    final manual = notifier.syncSavedSakeToServer('saved_69_2', force: true);
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    expect(await automatic, isNotNull);
    expect(await manual, isNotNull);
    expect(repository.startCalls, 1);
    expect(repository.uploadCalls, 1);
    expect(repository.completeCalls, 1);
  });
}

SavedSakeNotifier _notifier(_FakeSavedSakeSyncRepository repository) {
  final auth = _SignedInAuthRepository();
  return SavedSakeNotifier()
    ..read = <T>() {
      if (T == AuthRepository) return auth as T;
      if (T == SavedSakeSyncRepository) return repository as T;
      throw StateError('Unexpected dependency: $T');
    };
}

class _FakeSavedSakeSyncRepository extends SavedSakeSyncRepository {
  _FakeSavedSakeSyncRepository({
    this.startGate,
    List<bool> completeResults = const <bool>[true],
  }) : _completeResults = [...completeResults],
       super(_UnusedApiClient());

  final Completer<void>? startGate;
  final List<bool> _completeResults;
  int startCalls = 0;
  int completeCalls = 0;
  int uploadCalls = 0;

  @override
  Future<bool> syncSavedSake({
    required SavedSakeSyncStage stage,
    required String userId,
    required Sake sake,
    File? imageFile,
    bool? isPublic,
    bool publicLabelContribution = false,
  }) async {
    if (stage == SavedSakeSyncStage.analysisStart) {
      startCalls++;
      if (startGate != null && !startGate!.isCompleted) {
        await startGate!.future;
      }
      return true;
    }
    completeCalls++;
    return _completeResults.isEmpty ? true : _completeResults.removeAt(0);
  }

  @override
  Future<String?> uploadSavedSakeImage({
    required String userId,
    required String savedId,
    required File imageFile,
    String imageRole = 'additional',
  }) async {
    uploadCalls++;
    return 'https://example.com/back.webp';
  }

  @override
  Future<List<Sake>> fetchSavedSakes(String userId) async => const <Sake>[];
}

class _SignedInAuthRepository implements AuthRepository {
  @override
  User? get currentUser => _FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  String get uid => 'user-69';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
