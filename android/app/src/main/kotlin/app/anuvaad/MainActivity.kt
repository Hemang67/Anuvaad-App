package app.anuvaad

import app.anuvaad.speech.SpeechRecognitionPlugin
import app.anuvaad.update.ApkInstaller
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var speech: SpeechRecognitionPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "app.anuvaad/installer").setMethodCallHandler(ApkInstaller(this))
        speech = SpeechRecognitionPlugin(this, messenger)
    }

    override fun onDestroy() {
        speech?.dispose()
        speech = null
        super.onDestroy()
    }
}
