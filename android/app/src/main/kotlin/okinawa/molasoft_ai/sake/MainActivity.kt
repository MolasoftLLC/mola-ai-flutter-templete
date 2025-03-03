package okinawa.molasoft_ai.sake

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the custom image picker plugin
        flutterEngine.plugins.add(CustomImagePickerPlugin())
    }
}
