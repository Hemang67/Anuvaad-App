package app.anuvaad.speech

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android SpeechRecognizer for Flutter.
 * Methods on `app.anuvaad/speech`: isAvailable, supportsLanguageDetection, start {locale, detectAmong?}, stop, cancel.
 * Events on `app.anuvaad/speech/events`: ready, speechStart, level {value 0..1}, partial {text}, final {text},
 * endOfSpeech, languageDetected {locale, confidence 0..3}, error {code}.
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
            "supportsLanguageDetection" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
            "start" -> {
                val locale = call.argument<String>("locale")
                if (locale.isNullOrBlank()) {
                    result.error("bad_args", "locale is required", null)
                } else {
                    start(locale, call.argument<List<String>>("detectAmong").orEmpty())
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

    private fun start(locale: String, detectAmong: List<String>) {
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
            // Android 14+: detect which allowed language is spoken, and switch transcription to it.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && detectAmong.isNotEmpty()) {
                val allowed = ArrayList(detectAmong)
                putExtra(RecognizerIntent.EXTRA_ENABLE_LANGUAGE_DETECTION, true)
                putStringArrayListExtra(RecognizerIntent.EXTRA_LANGUAGE_DETECTION_ALLOWED_LANGUAGES, allowed)
                putExtra(RecognizerIntent.EXTRA_ENABLE_LANGUAGE_SWITCH, RecognizerIntent.LANGUAGE_SWITCH_BALANCED)
                putStringArrayListExtra(RecognizerIntent.EXTRA_LANGUAGE_SWITCH_ALLOWED_LANGUAGES, allowed)
            }
        }
        current.startListening(intent)
    }

    private fun destroyRecognizer() {
        recognizer?.destroy()
        recognizer = null
    }

    private var lastLevelAt = 0L

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

        override fun onBeginningOfSpeech() {
            if (isCurrent) send(mapOf("type" to "speechStart"))
        }

        /** Loudness for the waveform, at most 10 times a second. rmsdB runs roughly -2..10. */
        override fun onRmsChanged(rmsdB: Float) {
            if (!isCurrent) return
            val now = SystemClock.elapsedRealtime()
            if (now - lastLevelAt < LEVEL_INTERVAL_MS) return
            lastLevelAt = now
            send(mapOf("type" to "level", "value" to ((rmsdB + 2f) / 12f).coerceIn(0f, 1f).toDouble()))
        }

        /** Android 14+: the recognizer's language guess. Never called on older versions. */
        override fun onLanguageDetection(results: Bundle) {
            if (!isCurrent) return
            val locale = results.getString(SpeechRecognizer.DETECTED_LANGUAGE) ?: return
            val confidence = results.getInt(SpeechRecognizer.LANGUAGE_DETECTION_CONFIDENCE_LEVEL, 0)
            send(mapOf("type" to "languageDetected", "locale" to locale, "confidence" to confidence))
        }

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

    private companion object {
        const val LEVEL_INTERVAL_MS = 100L
    }
}
