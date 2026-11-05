# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# pdfrx / pdfium
-keep class org.chromium.** { *; }
-dontwarn org.chromium.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# Keep annotations and enums used by plugins
-keepattributes *Annotation*
-keepclassmembers enum * { *; }

# Prevent stripping of generic signatures
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
