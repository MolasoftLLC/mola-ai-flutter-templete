import UIKit
import Flutter
import GoogleMaps
import Vision
import ImageIO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // プロファイリングを無効化
    UserDefaults.standard.set(false, forKey: "FLTEnableMetricKit")
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
       !mapsKey.isEmpty,
       !mapsKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(mapsKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceTextReader") else { return }
    let channel = FlutterMethodChannel(name: "okinawa.molasoft.sakepedia/text_ocr", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeFrame" || call.method == "recognizeFile" else {
        result(FlutterMethodNotImplemented); return
      }
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "OCR_INPUT", message: "Invalid text input", details: nil)); return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let request = VNRecognizeTextRequest()
          request.recognitionLevel = .accurate
          request.usesLanguageCorrection = false
          let supported = try request.supportedRecognitionLanguages()
          request.recognitionLanguages = ["ja-JP", "en-US"].filter { supported.contains($0) }
          let handler: VNImageRequestHandler
          if call.method == "recognizeFile", let path = args["path"] as? String {
            handler = VNImageRequestHandler(url: URL(fileURLWithPath: path), options: [:])
          } else {
            guard let data = args["bytes"] as? FlutterStandardTypedData,
                  let width = args["width"] as? Int, let height = args["height"] as? Int,
                  let row = args["bytesPerRow"] as? Int,
                  width > 0, height > 0, row >= width * 4, data.data.count >= row * height else {
              throw NSError(domain: "TextOCR", code: 1)
            }
            var buffer: CVPixelBuffer?
            guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &buffer) == kCVReturnSuccess,
                  let pixelBuffer = buffer else { throw NSError(domain: "TextOCR", code: 2) }
            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
            let destRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            guard let destination = CVPixelBufferGetBaseAddress(pixelBuffer) else { throw NSError(domain: "TextOCR", code: 3) }
            data.data.withUnsafeBytes { source in
              for y in 0..<height { memcpy(destination.advanced(by: y * destRow), source.baseAddress!.advanced(by: y * row), width * 4) }
            }
            let rotation = args["rotation"] as? Int ?? 90
            let orientation: CGImagePropertyOrientation = rotation == 90 ? .right : rotation == 180 ? .down : rotation == 270 ? .left : .up
            handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
            guard let region = args["region"] as? [String: Double],
                  let x = region["x"], let y = region["y"],
                  let w = region["width"], let h = region["height"],
                  [x, y, w, h].allSatisfy({ $0.isFinite }),
                  x >= 0, y >= 0, w > 0, h > 0, x + w <= 1.000001, y + h <= 1.000001 else {
              throw NSError(domain: "TextOCR", code: 4)
            }
            // Flutter uses a top-left origin; Vision uses a bottom-left origin.
            let rect = CGRect(x: x, y: 1 - y - h, width: w, height: h)
            request.regionOfInterest = rect
          }
          try handler.perform([request])
          // Vision observation boxes are relative to the cropped ROI, not the
          // original frame. regionOfInterest already excludes outside pixels.
          let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
          DispatchQueue.main.async { result(text) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "OCR_FAILED", message: "文字を読み取れませんでした", details: nil)) }
        }
      }
    }
  }
}
