package app.anuvaad.speech

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android SpeechRecognizer for Flutter.
 * Methods on `app.anuvaad/speech`: isAvailable, start {locale}, stop, cancel.
 * Events on `app.anuvaad/speech/events`: ready, partial {text}, final {text}, endOfSpeech, error {code}.
 * Method calls and recognizer callbacks both run on the main thread.
 */
class SpeechRecognitionPlugin(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private var sink: EventChannel.EventSink? = null
    private var recognizer: SpeechRecognizer? = null

    init {
        MethodChannel(messenger, "app.anuvaad/speech").setMethodCallHandler(this)
        EventChannel(messenger, "app.anuvaad/speech/events").setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(SpeechRecognizer.isRecognitionAvailable(activity))
            "start" -> {
                val locale = call.argument<String>("locale")
                if (locale.isNullOrBlank()) {
                    result.error("bad_args", "locale is required", null)
                } else {
                    start(locale)
                    result.success(null)
                }
            }
            "stop" -> {
                recognizer?.stopListening()
                result.success(null)
            }
            "cancel" -> {
                destroyRecognizer()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    /** Called from the Activity's onDestroy: never leave the microphone open. */
    fun dispose() {
        destroyRecognizer()
        sink = null
    }

    private fun start(locale: String) {
        destroyRecognizer() // a new turn replaces any old one
        val current = SpeechRecognizer.createSpeechRecognizer(activity)
        recognizer = current
        current.setRecognitionListener(Listener(current))
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, activity.packageName)
        }
        current.startListening(intent)
    }

    private fun destroyRecognizer() {
        recognizer?.destroy()
        recognizer = null
    }

    private fun send(event: Map<String, Any>) {
        sink?.success(event)
    }

    /** One listener per recognizer, so late callbacks from a replaced recognizer are ignored. */
    private inner class Listener(private val owner: SpeechRecognizer) : RecognitionListener {
        private val isCurrent get() = recognizer === owner

        override fun onReadyForSpeech(params: Bundle?) {
            if (isCurrent) send(mapOf("type" to "ready"))
        }

        override fun onPartialResults(partialResults: Bundle?) {
            if (!isCurrent) return
            val text = firstResult(partialResults)
            if (!text.isNullOrBlank()) send(mapOf("type" to "partial", "text" to text))
        }

        override fun onResults(results: Bundle?) {
            if (!isCurrent) return
            val text = firstResult(results)
            if (text.isNullOrBlank()) {
                send(mapOf("type" to "error", "code" to "noMatch"))
            } else {
                send(mapOf("type" to "final", "text" to text))
            }
            destroyRecognizer()
        }

        override fun onEndOfSpeech() {
            if (isCurrent) send(mapOf("type" to "endOfSpeech"))
        }

        override fun onError(error: Int) {
            if (!isCurrent) return
            send(mapOf("type" to "error", "code" to errorCode(error)))
            destroyRecognizer()
        }

        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun firstResult(bundle: Bundle?): String? =
        bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()

    /** Names match RecognitionErrorCode in lib/features/conversation/domain/speech_recognition.dart. */
    private fun errorCode(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_NO_MATCH -> "noMatch"
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "speechTimeout"
        SpeechRecognizer.ERROR_NETWORK,
        SpeechRecognizer.ERROR_NETWORK_TIMEOUT,
        SpeechRecognizer.ERROR_SERVER_DISCONNECTED -> "network"
        SpeechRecognizer.ERROR_AUDIO -> "audio"
        SpeechRecognizer.ERROR_SERVER -> "server"
        SpeechRecognizer.ERROR_CLIENT -> "client"
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permission"
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY,
        SpeechRecognizer.ERROR_TOO_MANY_REQUESTS -> "busy"
        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> "languageUnsupported"
        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "languageUnavailable"
        else -> "unknown"
    }
}
