# Flutter wrapper - keep ALL Flutter and plugin classes with members
-keep class io.flutter.** { *; }
-keepclassmembers class io.flutter.** { *; }

# Keep all plugin packages
-keep class io.flutter.plugins.** { *; }
-keepclassmembers class io.flutter.plugins.** { *; }

# Keep all embedding classes
-keep class io.flutter.embedding.** { *; }
-keepclassmembers class io.flutter.embedding.** { *; }

# CRITICAL: Keep GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class ai.viosa.app.** { *; }

# Keep all plugin registrations
-keepclassmembers class * {
    public void registerWith(io.flutter.plugin.common.PluginRegistry$Registrar);
}
-keepclassmembers class * implements io.flutter.embedding.engine.plugins.FlutterPlugin {
    public void onAttachedToEngine(io.flutter.embedding.engine.plugins.FlutterPlugin$FlutterPluginBinding);
}

# Keep Pigeon-generated classes (critical for path_provider and other plugins)
-keep class dev.flutter.pigeon.** { *; }
-keep class dev.flutter.pigeon.path_provider_android.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep all classes in packages that use Pigeon
-keep class **.messages.** { *; }
-keep class **.*Api { *; }
-keep class **.*Api$* { *; }

# Keep all plugin classes
-keep class io.flutter.plugins.** { *; }
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel$MethodCallHandler *;
}

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google Play Core (deferred components) - mark as missing OK
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Apache Tika missing XML stream classes (not available on Android)
-dontwarn javax.xml.stream.**
-dontwarn org.apache.tika.**

# Don't optimize Flutter classes (obfuscation is enabled for release builds)
-dontoptimize

# Keep everything related to path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class dev.flutter.pigeon.path_provider_android.PathProviderApi { *; }
-keep class dev.flutter.pigeon.path_provider_android.PathProviderApi$* { *; }

# CRITICAL: Keep PathProviderPlugin's Pigeon setup method
-keepclassmembers class io.flutter.plugins.pathprovider.PathProviderPlugin {
    public void onAttachedToEngine(io.flutter.embedding.engine.plugins.FlutterPlugin$FlutterPluginBinding);
    private void setup(io.flutter.plugin.common.BinaryMessenger, io.flutter.plugins.pathprovider.PathProviderPlugin);
}

# Keep all Pigeon message handlers
-keep class * implements io.flutter.plugin.common.BasicMessageChannel$MessageHandler { *; }
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes RuntimeVisibleAnnotations

# Keep ALL Pigeon-generated host API classes and their inner classes
-keep,allowobfuscation class * implements dev.flutter.pigeon.** { *; }
-keep class * extends dev.flutter.pigeon.** { *; }

# Specifically keep PathProviderApi and all related classes
-keep class dev.flutter.pigeon.path_provider_android.** { *; }
-keepclassmembers class dev.flutter.pigeon.path_provider_android.** { *; }

# Keep classes with methods that match Pigeon patterns
-keepclassmembers class * {
    public void getApplicationDocumentsPath(...);
    public void getTemporaryPath(...);
    public void getApplicationSupportPath(...);
    public void getExternalStoragePath(...);
}

# Prevent R8 from removing unused Pigeon interfaces
-keep interface dev.flutter.pigeon.** { *; }

# NUCLEAR OPTION: Keep ALL anonymous inner classes and lambdas for path_provider
-keep class io.flutter.plugins.pathprovider.**$* { *; }
-keepclassmembers class io.flutter.plugins.pathprovider.** {
    <fields>;
    <methods>;
}

# Keep all synthetic methods (lambdas)
-keepclassmembers class * {
    private synthetic *** lambda$*(...);
}

# Prevent class merging and inlining for Flutter plugins
-keep,allowshrinking class io.flutter.plugins.** { *; }
-keep,allowshrinking class dev.flutter.pigeon.** { *; }

# Remove verbose and debug logs in release builds
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int w(...);
}

# Remove verbose logging specifically for media/audio components
-assumenosideeffects class * {
    public void trace(...);
}

# CRITICAL: Keep path_provider_android Kotlin Pigeon classes
-keep class io.flutter.plugins.pathprovider.Messages$* { *; }
-keep class io.flutter.plugins.pathprovider.Messages { *; }
-keepclassmembers class io.flutter.plugins.pathprovider.Messages$* { *; }

# Keep all Result callback classes used by Pigeon
-keep class * extends io.flutter.plugin.common.BasicMessageChannel$Reply { *; }

# Prevent R8 from removing method channel setup
-keepclassmembers class io.flutter.plugins.pathprovider.PathProviderPlugin {
    *;
}
