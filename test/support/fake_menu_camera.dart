import 'dart:async';
import 'dart:math';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FakeMenuCamera extends CameraPlatform {
  FakeMenuCamera({this.path = '/tmp/menu-camera-photo.jpg'});
  final String path;
  bool denied = false;
  bool failCapture = false;
  int captures = 0;
  final created = <int>[];
  final disposed = <int>[];
  final descriptions = <CameraDescription>[];
  final audio = <bool>[];
  final flashes = <FlashMode>[];
  Completer<void>? initializeGate;
  Completer<void>? captureGate;
  final _errors = StreamController<CameraErrorEvent>.broadcast();

  Future<void> close() {
    // Complete the camera plugin's pending first-event listeners before closing.
    _errors.add(const CameraErrorEvent(0, 'disposed'));
    return _errors.close();
  }

  @override
  Future<List<CameraDescription>> availableCameras() async {
    if (denied) {
      throw CameraException('CameraAccessDenied', 'Permission denied');
    }
    return const [
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
    ];
  }

  @override
  Future<int> createCamera(
    CameraDescription description,
    ResolutionPreset? resolution, {
    bool enableAudio = false,
  }) async {
    final id = created.length + 1;
    created.add(id);
    descriptions.add(description);
    audio.add(enableAudio);
    return id;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    if (initializeGate != null) await initializeGate!.future;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int id) => Stream.value(
    CameraInitializedEvent(
      id,
      1920,
      1080,
      ExposureMode.auto,
      true,
      FocusMode.auto,
      true,
    ),
  );
  @override
  Stream<CameraErrorEvent> onCameraError(int id) => _errors.stream;
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();
  @override
  Widget buildPreview(int cameraId) =>
      const ColoredBox(color: Color(0xFF112B4B));
  @override
  Future<double> getMinZoomLevel(int cameraId) async => 1;
  @override
  Future<double> getMaxZoomLevel(int cameraId) async => 4;
  @override
  Future<void> setZoomLevel(int cameraId, double zoom) async {}
  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {
    flashes.add(mode);
  }

  @override
  Future<void> setFocusPoint(int cameraId, Point<double>? point) async {}
  @override
  Future<void> setExposurePoint(int cameraId, Point<double>? point) async {}
  @override
  Future<XFile> takePicture(int cameraId) async {
    captures++;
    if (captureGate != null) await captureGate!.future;
    if (failCapture) {
      throw PlatformException(code: 'CaptureFailed', message: 'Test failure');
    }
    return XFile(path);
  }

  @override
  Future<void> dispose(int cameraId) async {
    disposed.add(cameraId);
  }
}
