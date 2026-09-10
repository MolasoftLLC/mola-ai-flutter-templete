import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_scan_repository.dart';
import 'package:mola_gemini_flutter_template/domain/services/sake_scan_services.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/sake_scan_notifier.dart';

void main() {
  setUpAll(loggerConfigure);
  final image = File('/tmp/sake_scan_test.jpg');

  group('SakeScanNotifier', () {
    test('正面ラベルの候補を全件表示する', () async {
      final repository = _FakeScanRepository(
        frontResult: _candidatesResult(count: 4),
      );
      final notifier = _buildNotifier(repository);

      await notifier.submitFront(image);

      expect(
        notifier.currentState.status,
        SakeScanViewStatus.confirmingCandidate,
      );
      expect(notifier.currentState.candidates, hasLength(4));
      expect(notifier.currentState.scanSessionId, 'scan_test');
    });

    test('候補確定後にキャッシュ済み解析を即時完了する', () async {
      final repository = _FakeScanRepository(
        frontResult: _candidatesResult(),
        confirmation: const SakeScanConfirmation(
          status: SakeScanApiStatus.cacheHit,
          sakeId: 101,
        ),
        overview: _overview(completed: true),
      );
      final analysis = _FakeAnalysisService(const Sake(name: 'unused'));
      final persistence = _FakePersistenceService();
      final notifier = _buildNotifier(
        repository,
        analysis: analysis,
        persistence: persistence,
      );

      await notifier.submitFront(image);
      await notifier.confirmCandidate();

      expect(notifier.currentState.status, SakeScanViewStatus.completed);
      expect(notifier.currentState.sake?.sakeId, 101);
      expect(analysis.calls, 0);
      expect(persistence.completedSakes.single.sakeId, 101);
      expect(persistence.completedSakes.single.isPublic, isFalse);
    });

    test('キャッシュなしの場合は基本情報にsakeIdを保持してAI解析する', () async {
      final repository = _FakeScanRepository(
        frontResult: _candidatesResult(),
        confirmation: const SakeScanConfirmation(
          status: SakeScanApiStatus.analysisRequired,
          sakeId: 101,
        ),
        overview: _overview(completed: false),
      );
      final analysis = _FakeAnalysisService(
        const Sake(name: '獺祭', description: '解析済み'),
      );
      final persistence = _FakePersistenceService();
      final notifier = _buildNotifier(
        repository,
        analysis: analysis,
        persistence: persistence,
      );

      await notifier.submitFront(image);
      await notifier.confirmCandidate();

      expect(notifier.currentState.status, SakeScanViewStatus.completed);
      expect(notifier.currentState.sake?.sakeId, 101);
      expect(notifier.currentState.sake?.description, '解析済み');
      expect(analysis.calls, 1);
      expect(analysis.lastSakeId, 101);
    });

    test('詳細解析中でも保存後は次の一本を撮影できる', () async {
      final repository = _FakeScanRepository(
        frontResult: _candidatesResult(),
        confirmation: const SakeScanConfirmation(
          status: SakeScanApiStatus.analysisRequired,
          sakeId: 101,
        ),
        overview: _overview(completed: false),
      );
      final analysisCompleter = Completer<Sake>();
      final analysis = _FakeAnalysisService(
        const Sake(name: '獺祭', description: '解析済み'),
        completer: analysisCompleter,
      );
      final persistence = _FakePersistenceService();
      final notifier = _buildNotifier(
        repository,
        analysis: analysis,
        persistence: persistence,
      );

      await notifier.submitFront(image);
      final confirmation = notifier.confirmCandidate();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.currentState.status, SakeScanViewStatus.aiAnalyzing);
      expect(notifier.currentState.savedSake, isNotNull);

      notifier.startNextScan();
      expect(notifier.currentState.status, SakeScanViewStatus.frontScanning);
      expect(notifier.currentState.frontImage, isNull);

      analysisCompleter.complete(const Sake(name: '獺祭', description: '解析済み'));
      await confirmation;

      expect(notifier.currentState.status, SakeScanViewStatus.frontScanning);
      expect(persistence.completedSakes.single.description, '解析済み');
    });

    test('正面候補が違う場合は裏ラベルへ進み、新しい候補を表示する', () async {
      final repository = _FakeScanRepository(
        frontResult: _candidatesResult(),
        backResult: const SakeScanResult(
          status: SakeScanApiStatus.candidates,
          scanSessionId: 'scan_test',
          candidates: <SakeScanCandidate>[
            SakeScanCandidate(sakeId: 202, name: '裏ラベル候補'),
          ],
        ),
      );
      final notifier = _buildNotifier(repository);

      await notifier.submitFront(image);
      notifier.rejectCandidates();
      expect(notifier.currentState.status, SakeScanViewStatus.backScanning);

      await notifier.submitBack(image);
      expect(
        notifier.currentState.status,
        SakeScanViewStatus.confirmingCandidate,
      );
      expect(notifier.currentState.selectedCandidate?.sakeId, 202);
    });

    test('裏ラベルで特定した場合も表をメイン画像として両方保存する', () async {
      final frontImage = File('/tmp/front_label.jpg');
      final backImage = File('/tmp/back_label.jpg');
      final repository = _FakeScanRepository(
        frontResult: const SakeScanResult(
          status: SakeScanApiStatus.needBackLabel,
          scanSessionId: 'scan_test',
        ),
        backResult: const SakeScanResult(
          status: SakeScanApiStatus.candidates,
          scanSessionId: 'scan_test',
          candidates: <SakeScanCandidate>[
            SakeScanCandidate(sakeId: 202, name: '裏ラベル候補'),
          ],
        ),
        overview: const SakeOverview(
          sake: Sake(sakeId: 202, name: '裏ラベル候補'),
          analysisCompleted: true,
        ),
      );
      final persistence = _FakePersistenceService();
      final notifier = _buildNotifier(repository, persistence: persistence);

      await notifier.submitFront(frontImage);
      await notifier.submitBack(backImage);
      await notifier.confirmCandidate();

      expect(persistence.initialSakes.single.imagePaths, <String>[
        frontImage.path,
        backImage.path,
      ]);
      expect(notifier.currentState.savedSake?.imagePaths, <String>[
        frontImage.path,
        backImage.path,
      ]);
    });

    test('裏ラベルの低信頼DB候補も確認画面に表示する', () async {
      final repository = _FakeScanRepository(
        frontResult: const SakeScanResult(
          status: SakeScanApiStatus.needBackLabel,
          scanSessionId: 'scan_test',
        ),
        backResult: const SakeScanResult(
          status: SakeScanApiStatus.aiRequired,
          scanSessionId: 'scan_test',
          candidates: <SakeScanCandidate>[
            SakeScanCandidate(sakeId: 202, name: '低信頼候補'),
          ],
        ),
      );
      final analysis = _FakeAnalysisService(const Sake(name: '未使用'));
      final notifier = _buildNotifier(repository, analysis: analysis);

      await notifier.submitFront(image);
      await notifier.submitBack(image);

      expect(
        notifier.currentState.status,
        SakeScanViewStatus.confirmingCandidate,
      );
      expect(notifier.currentState.selectedCandidate?.name, '低信頼候補');
      expect(analysis.identifyCalls, 0);
      expect(analysis.calls, 0);
    });

    test('裏ラベルでDB特定不能ならAI候補を表示し確定後に詳細解析する', () async {
      final repository = _FakeScanRepository(
        frontResult: const SakeScanResult(
          status: SakeScanApiStatus.needBackLabel,
          scanSessionId: 'scan_test',
        ),
        backResult: const SakeScanResult(
          status: SakeScanApiStatus.aiRequired,
          scanSessionId: 'scan_test',
        ),
      );
      final analysis = _FakeAnalysisService(const Sake(name: 'AI特定酒'));
      final persistence = _FakePersistenceService();
      final notifier = _buildNotifier(
        repository,
        analysis: analysis,
        persistence: persistence,
      );

      await notifier.submitFront(image);
      expect(notifier.currentState.status, SakeScanViewStatus.backScanning);
      await notifier.submitBack(image);

      expect(
        notifier.currentState.status,
        SakeScanViewStatus.confirmingCandidate,
      );
      expect(notifier.currentState.selectedCandidate?.name, 'AI特定酒');
      expect(analysis.identifyCalls, 1);
      expect(analysis.calls, 0);
      expect(persistence.initialSakes, isEmpty);

      await notifier.confirmCandidate();

      expect(notifier.currentState.status, SakeScanViewStatus.completed);
      expect(notifier.currentState.sake?.name, 'AI特定酒');
      expect(analysis.calls, 1);
      expect(analysis.lastImagePath, image.path);
      expect(persistence.initialSakes.single.name, 'AI特定酒');
    });

    test('DB特定不能時はAI解析成功まで仮の保存酒を作らない', () async {
      final repository = _FakeScanRepository(
        frontResult: const SakeScanResult(
          status: SakeScanApiStatus.needBackLabel,
          scanSessionId: 'scan_test',
        ),
        backResult: const SakeScanResult(
          status: SakeScanApiStatus.aiRequired,
          scanSessionId: 'scan_test',
        ),
      );
      final analysisCompleter = Completer<Sake>();
      final analysis = _FakeAnalysisService(
        const Sake(name: 'AI特定酒'),
        completer: analysisCompleter,
      );
      final persistence = _FakePersistenceService();
      final notifier = _buildNotifier(
        repository,
        analysis: analysis,
        persistence: persistence,
      );

      await notifier.submitFront(image);
      await notifier.submitBack(File('/tmp/back_label.jpg'));

      expect(
        notifier.currentState.status,
        SakeScanViewStatus.confirmingCandidate,
      );
      expect(analysis.identifyCalls, 1);
      expect(analysis.calls, 0);
      expect(persistence.initialSakes, isEmpty);

      final analysisFuture = notifier.confirmCandidate();
      await Future<void>.delayed(Duration.zero);

      expect(persistence.initialSakes, isEmpty);
      expect(analysis.lastImagePath, image.path);

      analysisCompleter.complete(const Sake(name: 'AI特定酒'));
      await analysisFuture;
      expect(persistence.initialSakes.single.name, 'AI特定酒');
    });

    test('文字認識失敗の理由を裏ラベル撮影状態へ渡す', () async {
      final repository = _FakeScanRepository(
        frontResult: const SakeScanResult(
          status: SakeScanApiStatus.needBackLabel,
          scanSessionId: 'scan_test',
          backLabelReason: SakeScanBackLabelReason.ocrUnreadable,
        ),
      );
      final notifier = _buildNotifier(repository);

      await notifier.submitFront(image);

      expect(notifier.currentState.status, SakeScanViewStatus.backScanning);
      expect(
        notifier.currentState.backLabelReason,
        SakeScanBackLabelReason.ocrUnreadable,
      );
    });

    test('APIエラーをerror状態へ変換する', () async {
      final repository = _FakeScanRepository(
        frontError: const SakeScanException(
          kind: SakeScanErrorKind.rateLimited,
          message: 'too many requests',
          statusCode: 429,
        ),
      );
      final notifier = _buildNotifier(repository);

      await notifier.submitFront(image);

      expect(notifier.currentState.status, SakeScanViewStatus.error);
      expect(notifier.currentState.error?.kind, SakeScanErrorKind.rateLimited);
    });

    test('送信中の多重実行を防止する', () async {
      final completer = Completer<SakeScanResult>();
      final repository = _FakeScanRepository(frontCompleter: completer);
      final notifier = _buildNotifier(repository);

      final first = notifier.submitFront(image);
      final second = notifier.submitFront(image);
      expect(repository.frontCalls, 1);

      completer.complete(_candidatesResult());
      await Future.wait(<Future<void>>[first, second]);
      expect(repository.frontCalls, 1);
      expect(
        notifier.currentState.status,
        SakeScanViewStatus.confirmingCandidate,
      );
    });
  });
}

SakeScanNotifier _buildNotifier(
  _FakeScanRepository repository, {
  _FakeAnalysisService? analysis,
  _FakePersistenceService? persistence,
}) {
  return SakeScanNotifier(
    scanRepository: repository,
    analysisService: analysis ?? _FakeAnalysisService(const Sake(name: '解析酒')),
    persistenceService: persistence ?? _FakePersistenceService(),
  );
}

SakeScanResult _candidatesResult({int count = 1}) {
  return SakeScanResult(
    status: SakeScanApiStatus.candidates,
    scanSessionId: 'scan_test',
    candidates: List<SakeScanCandidate>.generate(
      count,
      (index) => SakeScanCandidate(sakeId: 101 + index, name: '候補${index + 1}'),
    ),
  );
}

SakeOverview _overview({required bool completed}) {
  return SakeOverview(
    sake: const Sake(
      sakeId: 101,
      brandId: 10,
      name: '獺祭',
      type: '純米大吟醸',
      brewery: '旭酒造',
    ),
    analysisCompleted: completed,
  );
}

class _FakeScanRepository implements SakeScanRepository {
  _FakeScanRepository({
    this.frontResult,
    this.backResult,
    this.confirmation,
    this.overview,
    this.frontError,
    this.frontCompleter,
  });

  final SakeScanResult? frontResult;
  final SakeScanResult? backResult;
  final SakeScanConfirmation? confirmation;
  final SakeOverview? overview;
  final Object? frontError;
  final Completer<SakeScanResult>? frontCompleter;
  int frontCalls = 0;

  @override
  Future<SakeScanResult> scanFront(File image) async {
    frontCalls++;
    if (frontError != null) throw frontError!;
    if (frontCompleter != null) return frontCompleter!.future;
    return frontResult!;
  }

  @override
  Future<SakeScanResult> scanBack(String scanSessionId, File image) async {
    return backResult!;
  }

  @override
  Future<SakeScanConfirmation> confirm(String scanSessionId, int sakeId) async {
    return confirmation ??
        SakeScanConfirmation(
          status: SakeScanApiStatus.cacheHit,
          sakeId: sakeId,
        );
  }

  @override
  Future<SakeOverview> fetchOverview(
    int sakeId, {
    bool trackView = false,
  }) async {
    return overview ?? _overview(completed: true);
  }
}

class _FakeAnalysisService implements SakeScanAnalysisService {
  _FakeAnalysisService(this.result, {this.completer});

  final Sake result;
  final Completer<Sake>? completer;
  int identifyCalls = 0;
  int calls = 0;
  int? lastSakeId;
  String? lastImagePath;

  @override
  Future<Sake> identify(File image) async {
    identifyCalls++;
    return result;
  }

  @override
  Future<Sake> analyze(File image, {int? sakeId, String? scanSessionId}) async {
    calls++;
    lastSakeId = sakeId;
    lastImagePath = image.path;
    if (completer != null) return completer!.future;
    return result;
  }
}

class _FakePersistenceService implements SakeScanPersistenceService {
  final List<Sake> initialSakes = <Sake>[];
  final List<Sake> completedSakes = <Sake>[];

  @override
  Future<Sake> saveInitial(
    Sake sake,
    File primaryImage, {
    File? secondaryImage,
    required bool isPublic,
  }) async {
    final saved = sake.copyWith(
      savedId: 'saved_test',
      isPublic: isPublic,
      imagePaths: <String>[
        primaryImage.path,
        if (secondaryImage != null) secondaryImage.path,
      ],
    );
    initialSakes.add(saved);
    return saved;
  }

  @override
  Future<Sake> saveCompleted(
    Sake initial,
    Sake completed,
    File image, {
    required bool isPublic,
  }) async {
    final saved = completed.copyWith(
      savedId: initial.savedId,
      sakeId: completed.sakeId ?? initial.sakeId,
      isPublic: isPublic,
      imagePaths: initial.imagePaths,
    );
    completedSakes.add(saved);
    return saved;
  }
}
