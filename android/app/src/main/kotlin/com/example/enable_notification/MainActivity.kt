package com.example.enable_notification

import android.content.Context
import android.media.AudioManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.silent_mode"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
//            Activity class {com.example.enable_notification/com.example.enable_notification.MainActivity} does not exist
            if (call.method == "setSilentMode") {
                 val enable = call.argument<Boolean>("enable") ?: false
                 setSilentMode(context, enable)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

     fun setSilentMode(context: Context, enable: Boolean) {
         val audioManager = context.getSystemService(AUDIO_SERVICE) as AudioManager
         if (enable) {
             audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
         } else {
             audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
         }
     }
}
