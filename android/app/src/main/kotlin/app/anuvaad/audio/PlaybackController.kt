package app.anuvaad.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRouting
import android.media.AudioTrack
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.min
import kotlin.math.sin

/**
 * Plays synthesized speech on a preferred output with transient audio focus, reports the route Android
 * actually used, and plays a short test tone. One playback at a time; everything runs on the main thread.
 */
class PlaybackController(
    context: Context,
    private val outputs: OutputController,
    private val send: (Map<String, Any?>) -> Unit,
) {
    private val audioManager = context.getSystemService(AudioManager::class.java)
    private val main = Handler(Looper.getMainLooper())
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()

    private var player: MediaPlayer? = null
    private var playbackId: String? = null
    private var tone: AudioTrack? = null
    private var focus: AudioFocusRequest? = null

    fun play(path: String, deviceId: Int?, id: String, result: MethodChannel.Result) {
        stopAll()
        if (!requestFocus()) {
            result.error("playbackFailed", "Audio focus was refused", null)
            return
        }
        val requested = deviceId?.let { outputs.device(it) }
        val mp = MediaPlayer()
        try {
            mp.setAudioAttributes(attributes)
            mp.setDataSource(path)
            requested?.let { mp.setPreferredDevice(it) }
            mp.setOnCompletionListener {
                if (player === mp) {
                    send(mapOf("type" to "completed", "playbackId" to id))
                    releasePlayer()
                }
            }
            mp.setOnErrorListener { _, what, extra ->
                if (player === mp) {
                    send(mapOf("type" to "failed", "playbackId" to id, "code" to "$what:$extra"))
                    releasePlayer()
                }
                true
            }
            mp.prepare()
            player = mp
            playbackId = id
            mp.start()
        } catch (e: Exception) {
            if (player === mp) player = null
            mp.release()
            abandonFocus()
            result.error("playbackFailed", e.message, null)
            return
        }
        result.success(null)
        reportRoute(mp, id, requested)
    }

    /** Stops everything before answering, so the microphone never opens over playback. */
    fun stop(result: MethodChannel.Result) {
        stopAll()
        result.success(null)
    }

    fun playTestTone(deviceId: Int?, result: MethodChannel.Result) {
        stopAll()
        val requested = deviceId?.let { outputs.device(it) }
        val samples = toneSamples()
        val track = try {
            AudioTrack.Builder()
                .setAudioAttributes(attributes)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                )
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(samples.size * 2)
                .build()
        } catch (e: Exception) {
            result.error("playbackFailed", e.message, null)
            return
        }
        track.write(samples, 0, samples.size)
        requested?.let { track.setPreferredDevice(it) }
        requestFocus()
        tone = track
        track.play()
        // Give Android a moment to settle the route, then report it and clean up after the tone ends.
        main.postDelayed({
            val routed = track.routedDevice ?: requested ?: outputs.speaker()
            result.success(routed?.let { OutputController.describeRouted(it) })
        }, 150)
        main.postDelayed({
            if (tone === track) {
                track.release()
                tone = null
                abandonFocus()
            }
        }, TONE_MS + 100L)
    }

    fun dispose() = stopAll()

    private fun reportRoute(mp: MediaPlayer, id: String, requested: AudioDeviceInfo?) {
        mp.routedDevice?.let {
            sendStarted(id, it)
            return
        }
        var reported = false
        lateinit var listener: AudioRouting.OnRoutingChangedListener
        listener = AudioRouting.OnRoutingChangedListener { router ->
            val routed = router.routedDevice
            if (!reported && player === mp && routed != null) {
                reported = true
                mp.removeOnRoutingChangedListener(listener)
                sendStarted(id, routed)
            }
        }
        mp.addOnRoutingChangedListener(listener, main)
        main.postDelayed({
            if (!reported && player === mp) {
                reported = true
                mp.removeOnRoutingChangedListener(listener)
                (mp.routedDevice ?: requested ?: outputs.speaker())?.let { sendStarted(id, it) }
            }
        }, ROUTE_WAIT_MS)
    }

    private fun sendStarted(id: String, device: AudioDeviceInfo) {
        send(mapOf("type" to "started", "playbackId" to id, "routed" to OutputController.describeRouted(device)))
    }

    private fun requestFocus(): Boolean {
        abandonFocus()
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(attributes)
            .setOnAudioFocusChangeListener({ change ->
                // A call or alarm takes the audio: stop. Being ducked (quieter) keeps playing.
                if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                    val id = playbackId
                    stopAll()
                    if (id != null) send(mapOf("type" to "focusLost", "playbackId" to id))
                }
            }, main)
            .build()
        focus = request
        return audioManager.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun abandonFocus() {
        focus?.let { audioManager.abandonAudioFocusRequest(it) }
        focus = null
    }

    private fun releasePlayer() {
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        player = null
        playbackId = null
        abandonFocus()
    }

    private fun stopAll() {
        releasePlayer()
        tone?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        tone = null
        abandonFocus()
    }

    /** 440 Hz sine with short fades so it doesn't click. */
    private fun toneSamples(): ShortArray {
        val count = SAMPLE_RATE * TONE_MS / 1000
        val fade = SAMPLE_RATE * 20 / 1000
        return ShortArray(count) { i ->
            val envelope = min(1.0, min(i, count - 1 - i).toDouble() / fade)
            (sin(2 * PI * 440 * i / SAMPLE_RATE) * envelope * Short.MAX_VALUE * 0.5).toInt().toShort()
        }
    }

    private companion object {
        const val SAMPLE_RATE = 44_100
        const val TONE_MS = 600
        const val ROUTE_WAIT_MS = 500L
    }
}
