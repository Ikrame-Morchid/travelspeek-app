# ========================================
# TRAVELSPEEK - PROGUARD RULES
# ========================================

# ✅ Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# ✅ Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# ✅ Keep Dio (HTTP client)
-keep class dio.** { *; }
-dontwarn dio.**

# ✅ Keep Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# ✅ Keep Camera
-keep class io.flutter.plugins.camera.** { *; }

# ✅ Keep Record (Audio)
-keep class com.llfbandit.record.** { *; }

# ✅ Keep Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# ✅ Keep Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# ✅ Keep Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ✅ Keep Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# ✅ Keep Isar Database
-keep class io.isar.** { *; }
-dontwarn io.isar.**

# ✅ Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ✅ Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# ✅ Optimize code
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# ✅ Remove logging in production
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}