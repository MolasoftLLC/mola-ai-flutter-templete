package okinawa.molasoft_ai.sake

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    private val appIdentityChannel = "okinawa.molasoft_ai.sake/app_identity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
