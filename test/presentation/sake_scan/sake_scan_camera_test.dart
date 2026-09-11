import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
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

  test('黄色いラベルガイドを撮影画像内の範囲へ変換する', () {
    final cropRect = labelGuideCropRect(
      viewportSize: const Size(400, 800),
      previewSize: const Size(1080, 1920),
    );

    expect(cropRect.left, greaterThan(0));
    expect(cropRect.top, greaterThan(0));
    expect(cropRect.right, lessThan(1));
    expect(cropRect.bottom, lessThan(1));
    expect(cropRect.width, closeTo(0.69, 0.02));
    expect(cropRect.height, closeTo(0.58, 0.01));
  });

  test('撮影画像はガイド枠の範囲だけを切り出す', () {
    final source = image.Image(width: 100, height: 100);
    final bytes = cropSakeScanPhotoBytes(<String, Object>{
      'bytes': image.encodeJpg(source),
      'left': 0.1,
      'top': 0.2,
      'right': 0.9,
      'bottom': 0.8,
    });
    final cropped = image.decodeJpg(bytes);

    expect(cropped, isNotNull);
    expect(cropped!.width, 80);
    expect(cropped.height, 60);
  });
}
