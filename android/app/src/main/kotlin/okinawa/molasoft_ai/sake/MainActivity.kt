package okinawa.molasoft_ai.sake

import android.content.pm.PackageManager
import android.os.Build
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    private val textRecognizerDelegate = lazy { TextRecognition.getClient(JapaneseTextRecognizerOptions.Builder().build()) }
    private val textRecognizer by textRecognizerDelegate
    private val appIdentityChannel = "okinawa.molasoft_ai.sake/app_identity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "okinawa.molasoft.sakepedia/text_ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognizeFrame" && call.method != "recognizeFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val frame = call.method == "recognizeFrame"
                    val width = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    val rotation = call.argument<Int>("rotation") ?: 0
                    val region = if (frame) requireNotNull(call.argument<Map<String, Double>>("region")) else null
                    if (region != null) {
                        val x = requireNotNull(region["x"])
                        val y = requireNotNull(region["y"])
                        val w = requireNotNull(region["width"])
                        val h = requireNotNull(region["height"])
                        require(listOf(x, y, w, h).all { it.isFinite() } &&
                            x >= 0 && y >= 0 && w > 0 && h > 0 && x + w <= 1.000001 && y + h <= 1.000001)
                    }
                    val image = if (frame) {
                        InputImage.fromByteArray(requireNotNull(call.argument<ByteArray>("bytes")), width, height, rotation, InputImage.IMAGE_FORMAT_NV21)
                    } else {
                        InputImage.fromFilePath(this, Uri.fromFile(java.io.File(requireNotNull(call.argument<String>("path")))))
                    }
                    textRecognizer.process(image).addOnSuccessListener { recognized ->
                        val uprightWidth = if (rotation == 90 || rotation == 270) height else width
                        val uprightHeight = if (rotation == 90 || rotation == 270) width else height
                        val lines = recognized.textBlocks.flatMap { it.lines }.filter { line ->
                            val bounds = line.boundingBox
                            !frame || (bounds != null && bounds.exactCenterX() >= uprightWidth * region!!.getValue("x") &&
                                bounds.exactCenterX() <= uprightWidth * (region.getValue("x") + region.getValue("width")) &&
                                bounds.exactCenterY() >= uprightHeight * region.getValue("y") &&
                                bounds.exactCenterY() <= uprightHeight * (region.getValue("y") + region.getValue("height")))
                        }
                        result.success(lines.joinToString("\n") { it.text })
                    }.addOnFailureListener { result.error("OCR_FAILED", "文字を読み取れませんでした", null) }
                } catch (_: Exception) { result.error("OCR_INPUT", "文字を読み取れませんでした", null) }
            }
        // Register the custom image picker plugin
        flutterEngine.plugins.add(CustomImagePickerPlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appIdentityChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getSigningCertificateSha1") {
                    runCatching { signingCertificateSha1() }
                        .onSuccess(result::success)
                        .onFailure { result.error("SIGNATURE_ERROR", it.message, null) }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        if (textRecognizerDelegate.isInitialized()) textRecognizer.close()
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    private fun signingCertificateSha1(): String {
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
        } else {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
        }
        val signature = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.signingInfo?.apkContentsSigners?.firstOrNull()
        } else {
            packageInfo.signatures?.firstOrNull()
        } ?: error("Signing certificate was not found")
        return MessageDigest.getInstance("SHA-1")
            .digest(signature.toByteArray())
            .joinToString("") { byte -> "%02X".format(byte) }
    }
}
