package app.anuvaad.session

import android.app.Activity
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** `app.anuvaad/session`: start, update and stop [ConversationService]; its button presses come back as events. */
class SessionPlugin(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val channel = MethodChannel(messenger, "app.anuvaad/session")
    private val events = EventChannel(messenger, "app.anuvaad/session/commands")
    private var sink: EventChannel.EventSink? = null

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(this)
        ConversationService.commands = { command -> sink?.success(command) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                ConversationService.pending = ConversationService.Start(
                    spec = NotificationSpec.from(args),
                    channelName = args["channelName"] as? String ?: "Conversations",
                    earphoneButton = args["earphoneButton"] as? Boolean ?: true,
                )
                try {
                    activity.startForegroundService(service().setAction(ConversationService.ACTION_START))
                    result.success(true)
                } catch (e: Exception) {
                    // Android 12+ refuses from the background (ForegroundServiceStartNotAllowedException).
                    Log.w("AnuvaadSession", "Could not start the conversation service", e)
                    ConversationService.pending = null
                    result.success(false)
                }
            }
            "update" -> {
                ConversationService.update(NotificationSpec.from(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()))
                result.success(null)
            }
            "stop" -> {
                stop()
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

    private fun service() = Intent(activity, ConversationService::class.java)

    private fun stop() {
        ConversationService.pending = null
        activity.stopService(service())
    }

    /** The app is closing: no conversation, so no microphone and no notification. */
    fun dispose() {
        stop()
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        ConversationService.commands = null
    }
}
