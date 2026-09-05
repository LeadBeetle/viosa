package ai.viosa.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import java.io.File
import java.lang.reflect.Method
import java.lang.reflect.Field
import java.lang.reflect.Proxy
import java.lang.reflect.InvocationHandler

class MainActivity : FlutterActivity() {
    private val sharedAudioChannel = "ai.viosa.app/shared_audio"
    private var pendingSharedAudioPath: String? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sharedAudioChannel)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedAudioFile" -> {
                    result.success(pendingSharedAudioPath)
                    pendingSharedAudioPath = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSharedAudioIntent(intent)
        pendingSharedAudioPath?.let { path ->
            methodChannel?.invokeMethod("onSharedAudioFile", path)
            pendingSharedAudioPath = null
        }
    }

    /**
     * Kopiert eine geteilte Audiodatei in den App-Cache und merkt sich den Pfad,
     * damit Flutter sie ohne Zugriff auf den Ursprungsordner öffnen kann.
     */
    private fun handleSharedAudioIntent(intent: Intent?) {
        val uri: Uri? = when (intent?.action) {
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM)
            Intent.ACTION_VIEW -> intent.data
            else -> null
        }

        if (uri == null) return

        val mimeType = intent?.type
        if (mimeType != null && !mimeType.startsWith("audio")) return

        try {
            val fileName = queryDisplayName(uri) ?: "shared_audio_${System.currentTimeMillis()}"
            val targetDirectory = File(cacheDir, "shared_audio").apply { mkdirs() }
            val target = File(targetDirectory, fileName)

            contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return

            pendingSharedAudioPath = target.absolutePath
        } catch (e: Exception) {
            Log.w("Viosa", "Could not read shared audio file", e)
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment

        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                return cursor.getString(index)
            }
        }
        return null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        handleSharedAudioIntent(intent)

        // Suppress HiTouch logs via reflection
        suppressHiTouchLogs()

        // Set log properties BEFORE super.onCreate
        System.setProperty("log.tag.TraceLog", "SUPPRESS")
        System.setProperty("log.tag.BufferPoolAccessor2.0", "SUPPRESS")
        System.setProperty("log.tag.HiTouch_PressGestureDetector", "SUPPRESS")

        super.onCreate(savedInstanceState)

        // Disable verbose logging from media components
        try {
            val loggingClass = Class.forName("android.media.MediaCodec")
            val setVerboseLoggingMethod: Method = loggingClass.getDeclaredMethod("setVerboseLogging", Boolean::class.javaPrimitiveType)
            setVerboseLoggingMethod.isAccessible = true
            setVerboseLoggingMethod.invoke(null, false)
        } catch (e: Exception) {
            // Silently ignore if method doesn't exist
        }

        // Additional attempts to suppress codec logging
        try {
            System.setProperty("media.codec2.log-level", "0")
            System.setProperty("vendor.media.log.level", "0")
        } catch (e: Exception) {
            // Ignore
        }
    }

    private fun suppressHiTouchLogs() {
        try {
            val logClass = Class.forName("android.util.Log")
            val sLoggerField = logClass.getDeclaredField("sLogger")
            sLoggerField.isAccessible = true

            val originalLogger = sLoggerField.get(null)
            val loggerInterface = Class.forName("android.util.Log\$Logger")

            val filteredLogger = Proxy.newProxyInstance(
                loggerInterface.classLoader,
                arrayOf(loggerInterface),
                InvocationHandler { _, method, args ->
                    if (args != null && args.size >= 2) {
                        val tag = args[0] as? String
                        if (tag?.contains("HiTouch") == true) {
                            return@InvocationHandler null
                        }
                    }
                    method.invoke(originalLogger, *(args ?: arrayOf()))
                }
            )

            sLoggerField.set(null, filteredLogger)
        } catch (e: Exception) {
            // Ignore
        }
    }
}
