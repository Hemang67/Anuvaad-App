package app.anuvaad.audio

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper

/** The outputs Android reports as connected, and notifications when that list changes. */
class OutputController(context: Context, private val onChange: (List<Map<String, Any>>) -> Unit) {
    private val audioManager = context.getSystemService(AudioManager::class.java)
    private val main = Handler(Looper.getMainLooper())
    private var watching = false

    /** Connected outputs Anuvaad can play to, in the shared-contract shape. */
    fun list(): List<Map<String, Any>> =
        audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).mapNotNull { describe(it) }

    fun device(id: Int): AudioDeviceInfo? =
        audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).firstOrNull { it.id == id }

    fun speaker(): AudioDeviceInfo? =
        audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }

    fun startWatching() {
        if (watching) return
        audioManager.registerAudioDeviceCallback(callback, main) // reports the current devices straight away
        watching = true
    }

    fun stopWatching() {
        if (!watching) return
        audioManager.unregisterAudioDeviceCallback(callback)
        watching = false
    }

    private val callback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) = onChange(list())
        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) = onChange(list())
    }

    companion object {
        /** Contract kind for a device Anuvaad lists, or null for outputs it ignores (earpiece, SCO, HDMI…). */
        fun kindOf(type: Int): String? = when (type) {
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
            AudioDeviceInfo.TYPE_WIRED_HEADSET, AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "wired"
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "bluetooth"
            AudioDeviceInfo.TYPE_USB_HEADSET -> "usb"
            else -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                (type == AudioDeviceInfo.TYPE_BLE_HEADSET || type == AudioDeviceInfo.TYPE_BLE_SPEAKER)
            ) "bluetooth" else null
        }

        fun describe(device: AudioDeviceInfo): Map<String, Any>? = kindOf(device.type)?.let { kind ->
            // The built-in speaker's product name is the phone model; the app labels it "Phone speaker" instead.
            val name = if (kind == "speaker") "" else device.productName?.toString()?.trim().orEmpty()
            mapOf("id" to device.id, "kind" to kind, "name" to name)
        }

        /**
         * Describes the device a playback was actually routed to. Never claims a different route: types
         * Anuvaad doesn't list are reported by their nearest kind (Bluetooth call audio as bluetooth, other
         * built-in outputs as speaker) with Android's product name.
         */
        fun describeRouted(device: AudioDeviceInfo): Map<String, Any> = describe(device) ?: run {
            val kind = when (device.type) {
                AudioDeviceInfo.TYPE_BLUETOOTH_SCO, AudioDeviceInfo.TYPE_HEARING_AID -> "bluetooth"
                AudioDeviceInfo.TYPE_USB_DEVICE, AudioDeviceInfo.TYPE_USB_ACCESSORY -> "usb"
                else -> "speaker"
            }
            mapOf("id" to device.id, "kind" to kind, "name" to device.productName?.toString()?.trim().orEmpty())
        }
    }
}
