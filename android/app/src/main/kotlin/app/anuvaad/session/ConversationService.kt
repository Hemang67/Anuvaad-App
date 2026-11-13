package app.anuvaad.session

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import android.view.KeyEvent
import app.anuvaad.MainActivity
import app.anuvaad.R

/** What the conversation notification shows; built from the Dart side's SessionNotification.toMap(). */
data class NotificationSpec(
    val title: String,
    val text: String,
    val privateText: String?,
    val actions: List<Pair<String, String>>,
    val active: Boolean,
) {
    companion object {
        fun from(args: Map<*, *>): NotificationSpec {
            val commands = (args["commands"] as? List<*>)?.map { it.toString() } ?: emptyList()
            val labels = (args["labels"] as? List<*>)?.map { it.toString() } ?: emptyList()
            return NotificationSpec(
                title = args["title"] as? String ?: "",
                text = args["text"] as? String ?: "",
                privateText = args["privateText"] as? String,
                actions = commands.zip(labels),
                active = args["active"] as? Boolean ?: true,
            )
        }
    }
}

/**
 * A microphone foreground service: while a conversation runs it keeps the microphone with the screen off or another
 * app on top, shows what is happening in its notification (with buttons that work on the lock screen), turns the
 * screen off in a pocket as a phone call does, and hands the earphones' play/pause button to the conversation.
 */
class ConversationService : Service() {
    data class Start(val spec: NotificationSpec, val channelName: String, val earphoneButton: Boolean)

    companion object {
        private const val TAG = "AnuvaadSession"
        private const val CHANNEL_ID = "conversation"
        private const val NOTIFICATION_ID = 4101
        const val ACTION_START = "app.anuvaad.session.START"
        private const val ACTION_COMMAND = "app.anuvaad.session.COMMAND"
        private const val EXTRA_COMMAND = "command"

        /** Wake locks end by themselves after this, in case nothing ever releases them. */
        private const val LOCK_TIMEOUT_MS = 4 * 60 * 60 * 1000L

        /** Button presses go here (set by [SessionPlugin] while the Flutter engine is alive). */
        @Volatile
        var commands: ((String) -> Unit)? = null

        /** What the next ACTION_START shows; same process, so no need to parcel it. */
        @Volatile
        var pending: Start? = null

        @Volatile
        private var instance: ConversationService? = null

        /** Shows [spec] now, or at start if the service hasn't reached the foreground yet. */
        fun update(spec: NotificationSpec) {
            val running = instance
            if (running != null && running.foreground) {
                running.show(spec)
            } else {
                pending = pending?.copy(spec = spec)
            }
        }
    }

    private var foreground = false
    private var mediaSession: MediaSession? = null
    private var pocketLock: PowerManager.WakeLock? = null
    private var cpuLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val start = pending
                pending = null
                if (start == null || !goForeground(start)) {
                    commands?.invoke("stopped")
                    stopSelf()
                }
            }
            ACTION_COMMAND -> {
                // A button on a notification that outlived its conversation does nothing.
                if (foreground) intent.getStringExtra(EXTRA_COMMAND)?.let { commands?.invoke(it) } else stopSelf()
            }
            else -> if (!foreground) stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun goForeground(start: Start): Boolean {
        ensureChannel(start.channelName)
        try {
            startForeground(NOTIFICATION_ID, build(start.spec), ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } catch (e: Exception) {
            // No microphone permission, or Android refused (the app wasn't on screen).
            Log.w(TAG, "Could not start the conversation service", e)
            return false
        }
        foreground = true
        updateCpuLock(start.spec.active)
        holdPocketLock()
        if (start.earphoneButton) {
            listenToEarphoneButton()
            claimMediaButton()
        }
        return true
    }

    private fun show(spec: NotificationSpec) {
        try {
            getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, build(spec))
        } catch (e: SecurityException) {
            Log.w(TAG, "Could not update the conversation notification", e)
        }
        updateCpuLock(spec.active)
    }

    private fun ensureChannel(name: String) {
        // Default importance shows it on the lock screen (with its buttons); no sound or vibration, ever.
        val channel = NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_DEFAULT).apply {
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun build(spec: NotificationSpec): Notification {
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        fun base(): Notification.Builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_conversation)
            .setContentTitle(spec.title)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setContentIntent(open)
            .apply {
                // Android 12+ may delay a new service's notification by 10 s; this one shows at once.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
                }
            }
            .apply { spec.actions.forEach { (command, label) -> addAction(action(command, label)) } }

        // A locked phone set to hide private content shows only the status and the languages.
        val public = base().setContentText(spec.text).build()
        val latest = spec.privateText
        return base()
            .setContentText(latest ?: spec.text)
            .apply {
                if (latest != null) {
                    setSubText(spec.text)
                    setStyle(Notification.BigTextStyle().bigText(latest))
                }
            }
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(public)
            .build()
    }

    private fun action(command: String, label: String): Notification.Action {
        val intent = Intent(this, ConversationService::class.java)
            .setAction(ACTION_COMMAND)
            .putExtra(EXTRA_COMMAND, command)
        // One request code per command: PendingIntents that differ only in extras would be the same one.
        val pending = PendingIntent.getService(
            this,
            command.hashCode(),
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return Notification.Action.Builder(null, label, pending).build()
    }

    /** Play/pause on earphones (or a wired headset's button) while the conversation runs. */
    private fun listenToEarphoneButton() {
        if (mediaSession != null) return
        mediaSession = MediaSession(this, "AnuvaadConversation").apply {
            setCallback(object : MediaSession.Callback() {
                override fun onMediaButtonEvent(mediaButtonIntent: Intent): Boolean {
                    val event = keyEventOf(mediaButtonIntent) ?: return false
                    return when (event.keyCode) {
                        KeyEvent.KEYCODE_HEADSETHOOK,
                        KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
                        KeyEvent.KEYCODE_MEDIA_PLAY,
                        KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                                commands?.invoke("earphoneButton")
                            }
                            true
                        }
                        else -> false
                    }
                }
            })
            // "Playing" makes this the session Android sends media buttons to.
            setPlaybackState(
                PlaybackState.Builder()
                    .setActions(PlaybackState.ACTION_PLAY_PAUSE or PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE)
                    .setState(PlaybackState.STATE_PLAYING, 0L, 1f)
                    .build(),
            )
            isActive = true
        }
    }

    /**
     * Android sends media buttons to the app that played audio last (it ignores a session that never played), so a
     * moment of silence makes that this app from the start of the conversation. No audio focus: music isn't paused.
     */
    private fun claimMediaButton() {
        Thread {
            try {
                val rate = 16000
                val samples = rate / 5
                val track = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build(),
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(rate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build(),
                    )
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .setBufferSizeInBytes(samples * 2)
                    .build()
                track.write(ShortArray(samples), 0, samples)
                track.play()
                Thread.sleep(400)
                track.stop()
                track.release()
            } catch (e: Exception) {
                Log.w(TAG, "Could not claim the earphone button", e)
            }
        }.start()
    }

    private fun keyEventOf(intent: Intent): KeyEvent? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT)
        }

    /** In a pocket (or face down) the screen turns off, as during a phone call; out of it, back on. */
    private fun holdPocketLock() {
        if (pocketLock != null) return
        val power = getSystemService(PowerManager::class.java)
        if (!power.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) return
        pocketLock = power.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "anuvaad:pocket").apply {
            setReferenceCounted(false)
            acquire(LOCK_TIMEOUT_MS)
        }
    }

    /** While listening or working (not paused), the processor stays awake for translation and speech. */
    private fun updateCpuLock(active: Boolean) {
        if (active) {
            val lock = cpuLock ?: getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "anuvaad:conversation")
                .also {
                    it.setReferenceCounted(false)
                    cpuLock = it
                }
            lock.acquire(LOCK_TIMEOUT_MS)
        } else {
            cpuLock?.takeIf { it.isHeld }?.release()
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Swiped away from Recents: the conversation is gone, and so is the microphone.
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        mediaSession?.release()
        mediaSession = null
        pocketLock?.takeIf { it.isHeld }?.release(PowerManager.RELEASE_FLAG_WAIT_FOR_NO_PROXIMITY)
        pocketLock = null
        cpuLock?.takeIf { it.isHeld }?.release()
        cpuLock = null
        if (foreground) stopForeground(STOP_FOREGROUND_REMOVE)
        foreground = false
        super.onDestroy()
    }
}
