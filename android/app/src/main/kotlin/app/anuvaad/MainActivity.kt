package app.anuvaad

import app.anuvaad.audio.AudioPlugin
import app.anuvaad.speech.SpeechRecognitionPlugin
import app.anuvaad.update.ApkInstaller
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var speech: SpeechRecognitionPlugin? = null
    private var audio: AudioPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "app.anuvaad/installer").setMethodCallHandler(ApkInstaller(this))
        speech = SpeechRecognitionPlugin(this, messenger)
        audio = AudioPlugin(this, messenger)
    }

    override fun onDestroy() {
        speech?.dispose()
        speech = null
        audio?.dispose()
        audio = null
        super.onDestroy()
    }
}
