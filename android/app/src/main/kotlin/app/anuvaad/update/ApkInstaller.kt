package app.anuvaad.update

import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Handles `app.anuvaad/installer`: opens Android's package installer for a verified
 * update APK. Android always shows its own confirmation screen; nothing installs silently.
 */
class ApkInstaller(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installApk" -> install(call.argument<String>("path"), result)
            else -> result.notImplemented()
        }
    }

    private fun install(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("install_failed", "Missing APK path", null)
            return
        }
        val updatesDir = File(context.cacheDir, "updates").canonicalFile
        val apk = File(path).canonicalFile
        if (apk.parentFile != updatesDir || !apk.isFile || !apk.name.endsWith(".apk")) {
            result.error("install_failed", "The APK must be a downloaded update in the app cache", null)
            return
        }
        try {
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.updates", apk)
            val intent = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("install_failed", e.message ?: e.javaClass.simpleName, null)
        }
    }
}
