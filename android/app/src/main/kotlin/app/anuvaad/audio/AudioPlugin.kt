package app.anuvaad.audio

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Audio for Flutter: text-to-speech, output devices and routed playback.
 * Methods on `app.anuvaad/audio`, events on `app.anuvaad/audio/events` (contract in the M3 plan).
 */
class AudioPlugin(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val tts = TtsController(activity)
    private var sink: EventChannel.EventSink? = null
    private val outputs = OutputController(activity) { list -> send(mapOf("type" to "outputs", "outputs" to list)) }
    private val playback = PlaybackController(activity, outputs) { event -> send(event) }

    init {
        MethodChannel(messenger, "app.anuvaad/audio").setMethodCallHandler(this)
        EventChannel(messenger, "app.anuvaad/audio/events").setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "voiceAvailability" -> {
                val locale = call.argument<String>("locale") ?: return badArgs(result, "locale")
                tts.availability(locale, result)
            }
            "synthesize" -> {
                val text = call.argument<String>("text") ?: return badArgs(result, "text")
                val locale = call.argument<String>("locale") ?: return badArgs(result, "locale")
                val path = call.argument<String>("path") ?: return badArgs(result, "path")
                tts.synthesize(text, locale, path, result)
            }
            "openVoiceInstall" -> result.success(tts.openVoiceInstall())
            "outputs" -> result.success(outputs.list())
            "play" -> {
                val path = call.argument<String>("path") ?: return badArgs(result, "path")
                val playbackId = call.argument<String>("playbackId") ?: return badArgs(result, "playbackId")
                playback.play(path, call.argument<Int>("deviceId"), playbackId, result)
            }
            "stop" -> playback.stop(result)
            "playTestTone" -> playback.playTestTone(call.argument<Int>("deviceId"), result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        outputs.startWatching()
    }

    override fun onCancel(arguments: Any?) {
        outputs.stopWatching()
        sink = null
    }

    /** Called from the Activity's onDestroy. */
    fun dispose() {
        playback.dispose()
        outputs.stopWatching()
        tts.dispose()
        sink = null
    }

    private fun send(event: Map<String, Any?>) {
        sink?.success(event)
    }

    private fun badArgs(result: MethodChannel.Result, name: String) {
        result.error("bad_args", "$name is required", null)
    }
}
