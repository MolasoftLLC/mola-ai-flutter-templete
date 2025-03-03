package okinawa.molasoft_ai.sake

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * CustomImagePickerPlugin
 *
 * A custom implementation of image picker that uses MediaStore.ACTION_PICK_IMAGES
 * or Intent.ACTION_PICK instead of requesting READ_MEDIA_IMAGES permission.
 */
class CustomImagePickerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private val REQUEST_CODE_PICK_IMAGE = 2023

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "custom_image_picker")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "pickImage" -> {
                pendingResult = result
                pickImage()
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun pickImage() {
        activity?.let {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Use MediaStore.ACTION_PICK_IMAGES for Android 13+ (API 33+)
                Intent(MediaStore.ACTION_PICK_IMAGES)
            } else {
                // Use Intent.ACTION_PICK for older Android versions
                Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            }
            it.startActivityForResult(intent, REQUEST_CODE_PICK_IMAGE)
        } ?: run {
            pendingResult?.error("activity_not_available", "Activity is not available", null)
            pendingResult = null
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_PICK_IMAGE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    try {
                        val filePath = copyUriToFile(uri)
                        pendingResult?.success(filePath)
                    } catch (e: IOException) {
                        pendingResult?.error("io_error", "Failed to read picked image: ${e.message}", null)
                    }
                } else {
                    pendingResult?.error("no_image", "No image was picked", null)
                }
            } else {
                pendingResult?.error("canceled", "Image picking was canceled", null)
            }
            pendingResult = null
            return true
        }
        return false
    }

    @Throws(IOException::class)
    private fun copyUriToFile(uri: Uri): String {
        val context = activity?.applicationContext ?: throw IOException("Context is null")
        val inputStream = context.contentResolver.openInputStream(uri)
            ?: throw IOException("Failed to open input stream")

        val cacheDir = context.cacheDir
        val outputFile = File(cacheDir, "picked_image_${System.currentTimeMillis()}.jpg")
        
        FileOutputStream(outputFile).use { outputStream ->
            inputStream.use { input ->
                input.copyTo(outputStream)
            }
        }
        
        return outputFile.absolutePath
    }
}
