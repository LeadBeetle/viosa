package com.example.viosa

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.util.Log
import java.lang.reflect.Method
import java.lang.reflect.Field
import java.lang.reflect.Proxy
import java.lang.reflect.InvocationHandler

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
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
