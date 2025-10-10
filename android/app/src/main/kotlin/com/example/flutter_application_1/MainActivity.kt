package com.example.flutter_application_1  // <-- keep your actual package

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "audio.route"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        when (call.method) {
          "earpiece" -> {
            // Route input/output for voice comm; NO speakerphone
            am.mode = AudioManager.MODE_IN_COMMUNICATION
            am.isSpeakerphoneOn = false
            result.success(null)
          }
          "speaker" -> {
            // Normal media playback to speaker
            am.isSpeakerphoneOn = true
            am.mode = AudioManager.MODE_NORMAL
            result.success(null)
          }
          else -> result.notImplemented()
        }
      }
  }
}
