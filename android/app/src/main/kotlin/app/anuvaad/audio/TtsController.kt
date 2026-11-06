package app.anuvaad.audio

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale
import java.util.UUID

/**
 * Android TextToSpeech, bound to Google's engine when installed. Speech is written to WAV files
 * (synthesizeToFile) so playback can be routed and replayed. All callbacks are answered on the main thread.
 */
class TtsController(private val activity: Activity) {
    private val main = Handler(Looper.getMainLooper())
    private var tts: TextToSpeech? = null
    private var enginePackage: String? = null
    private var ready = false
    private var initFailed = false
    private val waiting = mutableListOf<() -> Unit>()
    private val pending = mutableMapOf<String, MethodChannel.Result>()

    fun availability(tag: String, result: MethodChannel.Result) =
        withEngine(result) { engine -> result.success(availabilityOf(engine, Locale.forLanguageTag(tag))) }

    fun synthesize(text: String, tag: String, path: String, result: MethodChannel.Result) = withEngine(result) { engine ->
        val locale = Locale.forLanguageTag(tag)
        val set = engine.setLanguage(locale)
        if (set == TextToSpeech.LANG_MISSING_DATA || set == TextToSpeech.LANG_NOT_SUPPORTED) {
            result.error("voiceMissing", "No voice for $tag", null)
            return@withEngine
        }
        engine.setSpeechRate(1.0f)
        val file = File(path)
        file.parentFile?.mkdirs()
        val utteranceId = UUID.randomUUID().toString()
        pending[utteranceId] = result
        if (engine.synthesizeToFile(text, Bundle(), file, utteranceId) != TextToSpeech.SUCCESS) {
            pending.remove(utteranceId)?.error("synthesisFailed", "synthesizeToFile was refused", null)
        }
    }

    /** Opens the engine's voice download screen, falling back to the system TTS settings. */
    fun openVoiceInstall(): Boolean {
        val install = Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)
        enginePackage?.let { install.setPackage(it) }
        return try {
            activity.startActivity(install)
            true
        } catch (_: ActivityNotFoundException) {
            try {
                activity.startActivity(Intent("com.android.settings.TTS_SETTINGS"))
                true
            } catch (_: ActivityNotFoundException) {
                false
            }
        }
    }

    fun dispose() {
        pending.values.forEach { it.error("synthesisFailed", "Speech engine closed", null) }
        pending.clear()
        waiting.clear()
        tts?.shutdown()
        tts = null
        ready = false
    }

    private fun availabilityOf(engine: TextToSpeech, locale: Locale): String {
        val code = engine.isLanguageAvailable(locale)
        return when {
            code == TextToSpeech.LANG_MISSING_DATA -> "needsDownload"
            code < TextToSpeech.LANG_AVAILABLE -> "unsupported"
            else -> {
                val voices = engine.voices.orEmpty().filter {
                    it.locale.language == locale.language && (locale.country.isEmpty() || it.locale.country == locale.country)
                }
                val allMissing = voices.isNotEmpty() &&
                    voices.all { it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) }
                if (allMissing) "needsDownload" else "available"
            }
        }
    }

    /** Runs [action] once the engine is ready; calls arriving during start-up wait in a queue. */
    private fun withEngine(result: MethodChannel.Result, action: (TextToSpeech) -> Unit) {
        val engine = tts
        if (ready && engine != null) {
            action(engine)
            return
        }
        if (initFailed) {
            result.error("synthesisFailed", "Speech engine unavailable", null)
            return
        }
        waiting.add {
            val started = tts
            if (ready && started != null) action(started) else result.error("synthesisFailed", "Speech engine unavailable", null)
        }
        if (engine == null) start()
    }

    private fun start() {
        val engines = activity.packageManager
            .queryIntentServices(Intent(TextToSpeech.Engine.INTENT_ACTION_TTS_SERVICE), 0)
            .map { it.serviceInfo.packageName }
        enginePackage = GOOGLE_TTS.takeIf { it in engines }
        lateinit var created: TextToSpeech
        val onInit = TextToSpeech.OnInitListener { status ->
            main.post {
                ready = status == TextToSpeech.SUCCESS
                initFailed = !ready
                if (ready) created.setOnUtteranceProgressListener(progress)
                val queued = waiting.toList()
                waiting.clear()
                queued.forEach { it() }
            }
        }
        created = if (enginePackage != null) TextToSpeech(activity, onInit, enginePackage) else TextToSpeech(activity, onInit)
        tts = created
    }

    private val progress = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {}

        override fun onDone(utteranceId: String?) {
            main.post { pending.remove(utteranceId)?.success(null) }
        }

        @Deprecated("Deprecated in Java")
        override fun onError(utteranceId: String?) {
            main.post { pending.remove(utteranceId)?.error("synthesisFailed", "Synthesis failed", null) }
        }

        override fun onError(utteranceId: String?, errorCode: Int) {
            val code = if (errorCode == TextToSpeech.ERROR_NOT_INSTALLED_YET) "voiceMissing" else "synthesisFailed"
            main.post { pending.remove(utteranceId)?.error(code, "Synthesis error $errorCode", null) }
        }
    }

    private companion object {
        const val GOOGLE_TTS = "com.google.android.tts"
    }
}
