import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/sake_scan_page.dart';

void main() {
  test('複数の背面カメラがある場合は標準広角を優先する', () {
    const cameras = <CameraDescription>[
      CameraDescription(
        name: 'telephoto',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
        lensType: CameraLensType.telephoto,
      ),
      CameraDescription(
        name: 'wide',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
        lensType: CameraLensType.wide,
      ),
      CameraDescription(
        name: 'front',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 270,
        lensType: CameraLensType.wide,
      ),
    ];

    expect(selectPreferredSakeScanCamera(cameras).name, 'wide');
    expect(selectCloseUpSakeScanCamera(cameras)?.name, isNull);
  });

  test('超広角カメラがある場合は近接モード用カメラとして選択する', () {
    const cameras = <CameraDescription>[
      CameraDescription(
        name: 'wide',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
        lensType: CameraLensType.wide,
      ),
      CameraDescription(
        name: 'ultra-wide',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
        lensType: CameraLensType.ultraWide,
      ),
    ];

    expect(selectCloseUpSakeScanCamera(cameras)?.name, 'ultra-wide');
  });

  test('coverで左右が切れるプレビューのタップ位置をカメラ座標へ変換する', () {
    final center = normalizeCameraPreviewPoint(
      tapPosition: const Offset(200, 400),
      viewportSize: const Size(400, 800),
      previewSize: const Size(1080, 1920),
    );
    final leftEdge = normalizeCameraPreviewPoint(
      tapPosition: const Offset(0, 400),
      viewportSize: const Size(400, 800),
      previewSize: const Size(1080, 1920),
    );

    expect(center.dx, closeTo(0.5, 0.0001));
    expect(center.dy, closeTo(0.5, 0.0001));
    expect(leftEdge.dx, closeTo(1 / 18, 0.0001));
    expect(leftEdge.dy, closeTo(0.5, 0.0001));
  });

  test('ズーム倍率を端末の対応範囲内に制限する', () {
    expect(
      clampSakeScanZoomLevel(
        requestedZoomLevel: 0.5,
        minZoomLevel: 1,
        maxZoomLevel: 4,
      ),
      1,
    );
    expect(
      clampSakeScanZoomLevel(
        requestedZoomLevel: 2,
        minZoomLevel: 1,
        maxZoomLevel: 4,
      ),
      2,
    );
    expect(
      clampSakeScanZoomLevel(
        requestedZoomLevel: 8,
        minZoomLevel: 1,
        maxZoomLevel: 4,
      ),
      4,
    );
  });
}
